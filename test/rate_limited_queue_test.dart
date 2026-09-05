import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sift/core/ai/rate_limited_queue.dart';

void main() {
  group('RateLimitedQueue priority', () {
    test('an interactive call that arrives while background calls are '
        'already waiting on the bucket is admitted before them', () {
      fakeAsync((async) {
        // requestsPerSecond*3 floors at capacity 1 (see the .clamp(1, 5) in
        // RateLimitedQueue's constructor) whenever requestsPerSecond <=
        // 1/3 — that floor is what makes this deterministic: exactly one
        // call admits immediately, and every call after it must genuinely
        // wait for a refill rather than sliding through on burst headroom,
        // which is what actually exercises re-picking the queue head on
        // each retry instead of racing real-world timing.
        final queue =
            RateLimitedQueue(requestsPerSecond: 0.2, tokensPerMinute: 1000000);
        final order = <String>[];

        queue.run(1, () async => order.add('blocker'));
        async.flushMicrotasks();
        expect(order, ['blocker'], reason: 'capacity-1 bucket admits the '
            'first call immediately with nothing else queued yet');

        queue.run(1, () async => order.add('background1'));
        queue.run(1, () async => order.add('background2'));
        // Enqueued last, but both background calls are still sitting in
        // _pending waiting on the bucket at this point, not yet admitted.
        queue.run(
          1,
          () async => order.add('interactive'),
          priority: RequestPriority.interactive,
        );
        async.flushMicrotasks();
        expect(order, ['blocker'],
            reason: 'the bucket is empty — nothing new should admit yet');

        // Comfortably longer than one refill interval (1 / 0.2 rps = 5s).
        async.elapse(const Duration(seconds: 20));

        expect(order,
            ['blocker', 'interactive', 'background1', 'background2']);
      });
    });

    test('same-priority calls are admitted in the order they arrived', () {
      fakeAsync((async) {
        final queue =
            RateLimitedQueue(requestsPerSecond: 0.2, tokensPerMinute: 1000000);
        final order = <int>[];

        for (var i = 0; i < 4; i++) {
          queue.run(1, () async => order.add(i));
        }
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 30));

        expect(order, [0, 1, 2, 3]);
      });
    });

    test('a request asking for more tokens than the bucket can ever hold '
        'still completes instead of hanging forever', () {
      fakeAsync((async) {
        final queue =
            RateLimitedQueue(requestsPerSecond: 10, tokensPerMinute: 100);
        var ran = false;
        // tokensPerMinute: 100 means the token bucket's capacity is 100 — an
        // estimate of 10000 exceeds that, and would wait forever pre-clamp.
        queue.run(10000, () async => ran = true);
        async.elapse(const Duration(seconds: 5));
        expect(ran, isTrue);
      });
    });
  });
}
