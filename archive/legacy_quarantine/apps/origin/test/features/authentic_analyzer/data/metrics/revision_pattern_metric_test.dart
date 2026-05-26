import 'package:flutter_test/flutter_test.dart';
import 'package:origin/features/authentic_analyzer/data/metrics/revision_pattern_metric.dart';

void main() {
  group('RevisionPatternMetric', () {
    test('zero backspaces returns 1.0', () {
      final result = RevisionPatternMetric.compute(
        eventCount: 10,
        backspaceCount: 0,
      );
      expect(result, equals(1.0));
    });

    test('50% backspace ratio returns ~0.75', () {
      /// backspaceRatio = 10/20 = 0.5, score = 0.5 + 0.5 * 0.5 = 0.75
      final result = RevisionPatternMetric.compute(
        eventCount: 10,
        backspaceCount: 10,
      );
      expect(result, closeTo(0.75, 0.0001));
    });

    test('100% backspaces returns 0.5', () {
      /// eventCount=0, all backspaces → backspaceRatio = 1.0, score = 0.5
      final result = RevisionPatternMetric.compute(
        eventCount: 0,
        backspaceCount: 10,
      );
      expect(result, equals(0.5));
    });

    test('more backspaces than events returns below 0.5', () {
      /// eventCount=1, backspaceCount=30 → backspaceRatio = 30/31 ≈ 0.968
      /// score = 0.5 + 0.5 * (1.0 - 0.968) ≈ 0.516
      final result = RevisionPatternMetric.compute(
        eventCount: 1,
        backspaceCount: 30,
      );
      expect(result, greaterThan(0.5));
      expect(result, lessThan(0.6));
    });

    test('zero events with zero backspaces returns 1.0', () {
      /// totalEvents=0, backspaceRatio=0.0, score = 0.5 + 0.5 * 1.0 = 1.0
      final result = RevisionPatternMetric.compute(
        eventCount: 0,
        backspaceCount: 0,
      );
      expect(result, equals(1.0));
    });

    test('low backspace ratio returns score close to 1.0', () {
      /// backspaceRatio = 1/21 ≈ 0.048, score ≈ 0.976
      final result = RevisionPatternMetric.compute(
        eventCount: 20,
        backspaceCount: 1,
      );
      expect(result, closeTo(0.976, 0.001));
    });

    test('high event count with zero backspaces returns 1.0', () {
      final result = RevisionPatternMetric.compute(
        eventCount: 1000,
        backspaceCount: 0,
      );
      expect(result, equals(1.0));
    });

    test('equal events and backspaces returns 0.75', () {
      /// backspaceRatio = 0.5, score = 0.75
      final result = RevisionPatternMetric.compute(
        eventCount: 50,
        backspaceCount: 50,
      );
      expect(result, closeTo(0.75, 0.0001));
    });
  });
}
