import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:clock/clock.dart';

/// A single token bucket — refills continuously at [ratePerSecond], holds at
/// most [capacity] tokens.
///
/// Deliberately check-then-commit rather than a single blocking `consume`:
/// [hasCapacity] only ever reads state, [consumeNow] only ever mutates it
/// once a caller has confirmed capacity is there. Splitting them is what
/// lets [RateLimitedQueue] re-evaluate *which* pending call to admit next on
/// every retry tick instead of committing to one call and blocking on it —
/// see that class's doc for why that distinction matters for priority.
class _TokenBucket {
  final double ratePerSecond;
  final double capacity;
  double _tokens;
  DateTime _last;

  _TokenBucket({required this.ratePerSecond, required this.capacity})
      : _tokens = capacity,
        _last = clock.now();

  void _refill() {
    // package:clock's clock.now(), not the bare DateTime.now() this used to
    // call — identical in production (clock.now() delegates straight to
    // DateTime.now() by default), but only the clock.* API can be
    // overridden by fakeAsync/withClock in tests. Rate-limiting logic is
    // exactly the kind of code that's unverifiable without that: a real
    // test would otherwise need to actually sleep for however long a bucket
    // takes to refill.
    final now = clock.now();
    final elapsedSeconds = now.difference(_last).inMicroseconds / 1e6;
    _last = now;
    final refilled = _tokens + elapsedSeconds * ratePerSecond;
    _tokens = refilled > capacity ? capacity : refilled;
  }

  // A request asking for more than the bucket can ever hold would otherwise
  // never be satisfiable — refills top out at [capacity], so `_tokens` can
  // never reach an [amount] above it. Clamping here means an oversized
  // estimate (an unrecognized model id falling back to
  // kMistralFallbackLimit's modest budget, say, combined with an unusually
  // large batch) costs a slightly-too-eager admission instead of hanging
  // this queue — and every call queued behind it — permanently.
  double _clamp(double amount) => amount > capacity ? capacity : amount;

  bool hasCapacity(double amount) {
    _refill();
    return _tokens >= _clamp(amount);
  }

  /// Debits the bucket. Callers must have just checked [hasCapacity] true —
  /// this does not check again, so calling it without that check can drive
  /// `_tokens` negative.
  void consumeNow(double amount) => _tokens -= _clamp(amount);

  /// How many seconds until [amount] would be available if nothing else
  /// draws from this bucket meanwhile — a sizing hint for how long to sleep
  /// before retrying, not a guarantee (another call may consume first).
  double secondsUntilAvailable(double amount) {
    _refill();
    final target = _clamp(amount);
    if (_tokens >= target) return 0;
    return (target - _tokens) / ratePerSecond;
  }
}

/// Where a call sits in line when the buckets are busy. [interactive] calls
/// (the chat assistant, waiting on a person) always clear admission ahead of
/// any [background] calls (bulk screenshot tagging, waiting on no one) that
/// are still waiting — without this, a user opening the assistant right
/// after a big gallery sync queues behind that whole backlog with the UI
/// giving zero indication why, which just reads as broken. This governs
/// queueing order only, and the two priorities still draw from the exact
/// same buckets, so the real aggregate rate limit is never exceeded
/// regardless of how the queue reorders who gets there first.
enum RequestPriority { interactive, background }

class _PendingAdmission {
  final RequestPriority priority;
  final double estimatedTokens;
  final Completer<void> completer = Completer<void>();
  _PendingAdmission({required this.priority, required this.estimatedTokens});
}

/// Paces calls to a rate-limited API so requests queue and wait their turn
/// instead of firing concurrently and getting 429'd.
///
/// Two independent limits are enforced at once: a requests-per-second cap
/// (fixed cost of 1 per call) and a tokens-per-minute budget (variable cost
/// per call — a vision call costs far more than a short text
/// classification). A call is admitted only once both buckets have room, in
/// [RequestPriority] order and then enqueue order within the same priority.
///
/// Admission is serialized, not execution: once a call clears the gate, its
/// actual network round-trip runs independently of whatever's admitted
/// next — the queue only ever throttles the *rate* new requests start at,
/// never adds request latency on top of itself. That's what keeps this fast
/// rather than turning every call into a strictly one-at-a-time relay.
///
/// The dispatch loop re-picks the highest-priority *waiting* call on every
/// retry tick (a bounded sleep-and-recheck, not one long wait) rather than
/// committing to whichever call happened to be at the front when a wait
/// began — an earlier version here popped an entry and then `await`ed its
/// admission, which meant a background call that started waiting a moment
/// before an interactive one arrived couldn't be overtaken, since nothing
/// looked at the queue again until that wait resolved. For a single
/// in-flight background call that's a bounded, small cost either way; for
/// the actual failure this exists to fix — a whole backlog of pending
/// background calls after a big batch — every entry behind the first one
/// now correctly reorders behind a newly-arrived interactive call.
class RateLimitedQueue {
  final _TokenBucket _requestBucket;
  final _TokenBucket _tokenBucket;

  // A plain list, not a Queue, because interactive entries need to insert
  // ahead of any already-pending background entries rather than always
  // landing at one end — see RequestPriority's doc. Only _dispatch() ever
  // reads or removes from this, one entry at a time, so the two buckets
  // above never see concurrent access despite calls arriving concurrently.
  final ListQueue<_PendingAdmission> _pending = ListQueue<_PendingAdmission>();
  bool _dispatching = false;

  RateLimitedQueue({
    required double requestsPerSecond,
    required double tokensPerMinute,
  })  : _requestBucket = _TokenBucket(
          ratePerSecond: requestsPerSecond,
          // A little burst headroom so a quiet period doesn't force every
          // subsequent call to wait needlessly — capped low enough that it
          // can't blow past the real limit for more than an instant.
          capacity: (requestsPerSecond * 3).clamp(1, 5),
        ),
        _tokenBucket = _TokenBucket(
          ratePerSecond: tokensPerMinute / 60,
          capacity: tokensPerMinute,
        );

  /// Waits for both buckets to have room for [estimatedTokens] — ahead of
  /// same-or-lower priority calls still waiting, in enqueue order among
  /// equal priority — then runs [task]. Overestimating [estimatedTokens]
  /// just makes this call wait a touch longer — underestimating risks a
  /// real 429, so callers should round up.
  Future<T> run<T>(
    int estimatedTokens,
    Future<T> Function() task, {
    RequestPriority priority = RequestPriority.background,
  }) async {
    final entry = _PendingAdmission(
      priority: priority,
      estimatedTokens: estimatedTokens.toDouble(),
    );
    _enqueue(entry);
    unawaited(_dispatch());
    await entry.completer.future;
    return task();
  }

  void _enqueue(_PendingAdmission entry) {
    if (entry.priority == RequestPriority.background) {
      _pending.addLast(entry);
      return;
    }
    // Insert after any already-queued interactive entries but before the
    // first background one, so multiple interactive calls still admit in
    // the order they actually arrived.
    final list = _pending.toList();
    final firstBackground =
        list.indexWhere((e) => e.priority == RequestPriority.background);
    if (firstBackground == -1) {
      _pending.addLast(entry);
    } else {
      list.insert(firstBackground, entry);
      _pending
        ..clear()
        ..addAll(list);
    }
  }

  /// Repeatedly re-picks `_pending.first` — never a saved reference — so a
  /// higher-priority arrival is picked up on the very next tick rather than
  /// only once whatever was already at the front finishes waiting. Idempotent
  /// to call repeatedly: every [run] call triggers this, but only one loop is
  /// ever actually active; a loop already running will see entries added
  /// after it started without needing a second one.
  Future<void> _dispatch() async {
    if (_dispatching) return;
    _dispatching = true;
    try {
      while (_pending.isNotEmpty) {
        final head = _pending.first;
        if (_requestBucket.hasCapacity(1) &&
            _tokenBucket.hasCapacity(head.estimatedTokens)) {
          _requestBucket.consumeNow(1);
          _tokenBucket.consumeNow(head.estimatedTokens);
          _pending.removeFirst();
          head.completer.complete();
          continue;
        }
        // Not enough capacity for the current head right now. Sleep briefly
        // and loop back to re-peek — short enough that a newly-arrived
        // interactive call is noticed promptly, long enough not to spin.
        final waitSeconds = math.max(
          _requestBucket.secondsUntilAvailable(1),
          _tokenBucket.secondsUntilAvailable(head.estimatedTokens),
        );
        final waitMs = (waitSeconds * 1000).ceil().clamp(10, 250);
        await Future.delayed(Duration(milliseconds: waitMs));
      }
    } finally {
      _dispatching = false;
    }
  }
}
