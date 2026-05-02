import 'package:flutter_test/flutter_test.dart';
import 'package:origin/features/authentic_analyzer/data/metrics/rhythm_entropy_metric.dart';

void main() {
  group('RhythmEntropyMetric', () {
    test('empty list returns 0.0', () {
      expect(RhythmEntropyMetric.compute([]), equals(0.0));
    });

    test('all same bucket (perfect rhythm) returns 0.0', () {
      // All deltas fall in the ≤50ms bucket
      final result = RhythmEntropyMetric.compute([10.0, 10.0, 10.0, 10.0, 10.0]);
      expect(result, equals(0.0));
    });

    test('all same bucket with higher timing returns 0.0', () {
      // All deltas fall in the >500ms bucket
      final result = RhythmEntropyMetric.compute([600.0, 600.0, 600.0]);
      expect(result, equals(0.0));
    });

    test('uniformly distributed across all 5 buckets returns 1.0', () {
      /// 1 sample per bucket: ≤50, ≤100, ≤200, ≤500, >500
      final result = RhythmEntropyMetric.compute([25.0, 75.0, 150.0, 300.0, 600.0]);
      expect(result, closeTo(1.0, 0.0001));
    });

    test('uniform distribution with multiple samples per bucket returns 1.0', () {
      /// 3 samples per bucket (15 total, perfectly balanced)
      final deltas = <double>[
        25.0, 25.0, 25.0,  // bucket 0 (≤50)
        75.0, 75.0, 75.0,  // bucket 1 (≤100)
        150.0, 150.0, 150.0,  // bucket 2 (≤200)
        300.0, 300.0, 300.0,  // bucket 3 (≤500)
        600.0, 600.0, 600.0,  // bucket 4 (>500)
      ];
      final result = RhythmEntropyMetric.compute(deltas);
      expect(result, closeTo(1.0, 0.0001));
    });

    test('typical typing pattern returns value between 0 and 1', () {
      /// Simulating realistic typing: mostly fast with occasional pauses
      final result = RhythmEntropyMetric.compute([
        45.0, 55.0, 80.0, 90.0,  // fast bursts
        120.0, 150.0,  // medium
        350.0,  // longer pause
        90.0, 50.0, 40.0,  // fast again
        250.0, 400.0,  // pauses
        60.0, 75.0, 45.0,  // fast
        550.0,  // long pause
      ]);
      expect(result, greaterThan(0.0));
      expect(result, lessThan(1.0));
    });

    test('score is always in range [0.0, 1.0]', () {
      final testCases = <List<double>>[
        [],
        [1.0],
        [1.0, 1.0],
        [1.0, 2.0, 3.0],
        [50.0, 50.0, 50.0],
        [25.0, 75.0, 150.0, 300.0, 600.0],
        List.generate(100, (i) => i.toDouble()),
        List.filled(50, 1000.0),
      ];
      for (final case_ in testCases) {
        final result = RhythmEntropyMetric.compute(case_);
        expect(result, greaterThanOrEqualTo(0.0));
        expect(result, lessThanOrEqualTo(1.0));
      }
    });

    test('2 buckets occupied returns ~0.43', () {
      /// 3 in bucket 0 (≤50), 3 in bucket 4 (>50) → p=0.5 each
      /// entropy = -2*(0.5*log2(0.5)) = 1.0
      /// normalized = 1.0 / log2(5) ≈ 0.4307
      final result = RhythmEntropyMetric.compute([20.0, 20.0, 20.0, 600.0, 600.0, 600.0]);
      expect(result, closeTo(0.4307, 0.001));
    });
  });
}
