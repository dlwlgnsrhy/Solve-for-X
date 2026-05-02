import 'package:flutter_test/flutter_test.dart';
import 'package:origin/features/authentic_analyzer/data/metrics/temporal_consistency_metric.dart';

void main() {
  group('TemporalConsistencyMetric', () {
    test('empty list returns 0.5', () {
      expect(TemporalConsistencyMetric.compute([]), equals(0.5));
    });

    test('single value returns 1.0 (CV=0)', () {
      final result = TemporalConsistencyMetric.compute([100.0]);
      expect(result, equals(1.0));
    });

    test('perfectly regular timing returns 1.0', () {
      /// All identical → variance=0 → CV=0 → score=1.0
      final result = TemporalConsistencyMetric.compute([50.0, 50.0, 50.0, 50.0]);
      expect(result, equals(1.0));
    });

    test('low variance timing returns high score close to 1.0', () {
      /// Slight variations around a base value
      final result = TemporalConsistencyMetric.compute([
        100.0, 102.0, 98.0, 101.0, 99.0,
      ]);
      expect(result, greaterThan(0.9));
      expect(result, lessThanOrEqualTo(1.0));
    });

    test('moderate variance timing returns mid-range score', () {
      /// Spread values giving moderate CV → score ≈ 0.53
      final result = TemporalConsistencyMetric.compute([
        25.0, 50.0, 100.0, 200.0, 400.0,
      ]);
      expect(result, greaterThan(0.0));
      expect(result, greaterThan(0.5));
      expect(result, lessThan(0.6));
    });

    test('high variance timing returns low score', () {
      /// Extreme spread → score ≈ 0.355
      final result = TemporalConsistencyMetric.compute([
        10.0, 10.0, 10.0, 10.0,
        500.0,
      ]);
      expect(result, greaterThan(0.0));
      expect(result, lessThan(0.4));
    });

    test('high variance returns lower than low variance', () {
      final lowVariance = TemporalConsistencyMetric.compute([100.0, 101.0, 99.0, 100.0]);
      final highVariance = TemporalConsistencyMetric.compute([10.0, 200.0, 50.0, 10.0, 50.0]);
      expect(lowVariance, greaterThan(highVariance));
    });

    test('two identical values returns 1.0', () {
      final result = TemporalConsistencyMetric.compute([75.0, 75.0]);
      expect(result, equals(1.0));
    });

    test('two very different values returns low score', () {
      /// score = 1/(1+CV) = 1/(1+1) ≈ 0.505
      final result = TemporalConsistencyMetric.compute([10.0, 1000.0]);
      expect(result, greaterThan(0.5));
      expect(result, lessThan(0.51));
    });

    test('score is always in range [0.0, 1.0]', () {
      final testCases = <List<double>>[
        [],
        [1.0],
        [50.0, 60.0],
        [10.0, 100.0, 500.0],
        List.generate(20, (i) => i.toDouble() + 1.0),
        List.filled(10, 42.0),
      ];
      for (final case_ in testCases) {
        final result = TemporalConsistencyMetric.compute(case_);
        expect(result, greaterThanOrEqualTo(0.0));
        expect(result, lessThanOrEqualTo(1.0));
      }
    });

    test('uniformly increasing timing returns predictable score', () {
      /// Regular pattern: 10, 20, 30, 40, 50 — moderate CV
      final result = TemporalConsistencyMetric.compute([10.0, 20.0, 30.0, 40.0, 50.0]);
      expect(result, greaterThan(0.4));
      expect(result, lessThan(0.7));
    });
  });
}
