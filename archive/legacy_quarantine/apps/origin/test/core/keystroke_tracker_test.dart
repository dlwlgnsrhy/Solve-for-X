import 'package:flutter_test/flutter_test.dart';
import 'package:origin/core/utils/keystroke_tracker.dart';

void main() {
  group('KeystrokeTracker', () {
    late KeystrokeTracker tracker;

    setUp(() {
      tracker = KeystrokeTracker();
    });

    test('initial state is empty', () {
      expect(tracker.recentEvents, isEmpty);
      expect(tracker.getTdeltas(), isEmpty);
    });

    test('onKey records events', () {
      tracker.onKey('h', DateTime.now());
      tracker.onKey('e', DateTime.now());
      expect(tracker.recentEvents, hasLength(2));
    });

    test('onKey tracks time deltas', () {
      final t1 = DateTime.now();
      final t2 = t1.add(const Duration(milliseconds: 50));
      tracker.onKey('a', t1);
      tracker.onKey('b', t2);
      final tdeltas = tracker.getTdeltas();
      expect(tdeltas, hasLength(1));
      expect(tdeltas[0], closeTo(50.0, 15.0)); // allow 15ms tolerance for test timing
    });

    test('onTextChange delegates to onKey for each char', () {
      tracker.onTextChange(oldText: 'hello', newText: 'hellox');
      expect(tracker.recentEvents, hasLength(1));
      expect(tracker.recentEvents.first.key, equals('x'));
    });

    test('getTdeltas extracts multiple deltas', () {
      final now = DateTime.now();
      tracker.onKey('a', now);
      tracker.onKey('b', now.add(const Duration(milliseconds: 100)));
      tracker.onKey('c', now.add(const Duration(milliseconds: 200)));
      final tdeltas = tracker.getTdeltas();
      expect(tdeltas, hasLength(2));
    });

    test('clear resets all state', () {
      tracker.onKey('a', DateTime.now());
      tracker.clear();
      expect(tracker.recentEvents, isEmpty);
    });
  });
}
