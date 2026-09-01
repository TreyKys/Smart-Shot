/// A single token bucket — refills continuously at [ratePerSecond], holds at
/// most [capacity] tokens. [consume] resolves once enough tokens are
/// available, waiting out any shortfall rather than failing.
class _TokenBucket {
  final double ratePerSecond;
  final double capacity;
  double _tokens;
  DateTime _last;

  _TokenBucket({required this.ratePerSecond, required this.capacity})
      : _tokens = capacity,
        _last = DateTime.now();

  void _refill() {
    final now = DateTime.now();
    final elapsedSeconds = now.difference(_last).inMicroseconds / 1e6;
    _last = now;
    final refilled = _tokens + elapsedSeconds * ratePerSecond;
    _tokens = refilled > capacity ? capacity : refilled;
  }

  Future<void> consume(double amount) async {
    // A request asking for more than the bucket can ever hold would
    // otherwise wait forever — refills top out at [capacity], so `_tokens`
    // can never reach an [amount] above it. Clamping here means an
    // oversized estimate (an unrecognized model id falling back to
    // kMistralFallbackLimit's modest budget, say, combined with an
    // unusually large batch) costs a slightly-too-eager admission instead
    // of hanging this queue — and every call queued behind it — permanently.
    final target = amount > capacity ? capacity : amount;
    while (true) {
      _refill();
      if (_tokens >= target) {
        _tokens -= target;
        return;
      }
      final deficitSeconds = (target - _tokens) / ratePerSecond;
      final waitMs = (deficitSeconds * 1000).ceil().clamp(10, 60000);
      await Future.delayed(Duration(milliseconds: waitMs));
    }
  }
}

/// Paces calls to a rate-limited API so requests queue and wait their turn
/// instead of firing concurrently and getting 429'd.
///
/// Two independent limits are enforced at once: a requests-per-second cap
/// (fixed cost of 1 per call) and a tokens-per-minute budget (variable cost
/// per call — a vision call costs far more than a short text
/// classification). A call is admitted only once both buckets have room,
/// strictly in the order it was enqueued.
///
/// Admission is serialized, not execution: once a call clears the gate, its
/// actual network round-trip runs independently of whatever's admitted
/// next — the queue only ever throttles the *rate* new requests start at,
/// never adds request latency on top of itself. That's what keeps this fast
/// rather than turning every call into a strictly one-at-a-time relay.
class RateLimitedQueue {
  final _TokenBucket _requestBucket;
  final _TokenBucket _tokenBucket;
  Future<void> _admissionTail = Future.value();

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

  /// Waits for both buckets to have room for [estimatedTokens], in enqueue
  /// order, then runs [task]. Overestimating [estimatedTokens] just makes
  /// this call wait a touch longer — underestimating risks a real 429, so
  /// callers should round up.
  Future<T> run<T>(int estimatedTokens, Future<T> Function() task) async {
    final myTurn = _admissionTail.then((_) async {
      await _requestBucket.consume(1);
      await _tokenBucket.consume(estimatedTokens.toDouble());
    });
    _admissionTail = myTurn;
    await myTurn;
    return task();
  }
}
