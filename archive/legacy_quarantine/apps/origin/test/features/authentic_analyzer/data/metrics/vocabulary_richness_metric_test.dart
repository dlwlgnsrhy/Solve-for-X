import 'package:flutter_test/flutter_test.dart';
import 'package:origin/features/authentic_analyzer/data/metrics/vocabulary_richness_metric.dart';

void main() {
  group('VocabularyRichnessMetric', () {
    test('single word returns 1.0', () {
      final result = VocabularyRichnessMetric.compute('hello');
      expect(result, equals(1.0));
    });

    test('single word with trailing whitespace returns 1.0', () {
      final result = VocabularyRichnessMetric.compute('  hello  ');
      expect(result, equals(1.0));
    });

    test('all different words returns ~1.0', () {
      final result = VocabularyRichnessMetric.compute(
        'apple banana cherry date elderberry',
      );
      expect(result, equals(1.0));
    });

    test('all same word returns close to 0.0', () {
      final result = VocabularyRichnessMetric.compute('the the the the the');
      expect(result, closeTo(0.2, 0.0001));
    });

    test('repeating words returns lower ratio', () {
      /// unique: {the, quick, brown} = 3, total: 8 → 3/8 = 0.375
      final result = VocabularyRichnessMetric.compute(
        'the quick brown the quick brown the quick',
      );
      expect(result, equals(0.375));
    });

    test('empty string returns 0.0', () {
      final result = VocabularyRichnessMetric.compute('');
      expect(result, equals(0.0));
    });

    test('only whitespace returns 0.0', () {
      final result = VocabularyRichnessMetric.compute('   ');
      expect(result, equals(0.0));
    });

    test('case insensitive — upper/lower mixed returns correct ratio', () {
      /// 'The' and 'the' count as the same word; 1 unique / 2 total = 0.5
      final result = VocabularyRichnessMetric.compute('The the');
      expect(result, equals(0.5));
    });

    test('mixed vocabulary with one repeat returns 4/5 = 0.8', () {
      /// 'a b c d a' → 4 unique out of 5
      final result = VocabularyRichnessMetric.compute('a b c d a');
      expect(result, equals(0.8));
    });

    test('long diverse text maintains meaningful TTR', () {
      final text =
          'the cat sat on the mat the dog ran in the park the bird flew high';
      /// unique: {the, cat, sat, on, mat, dog, ran, in, park, bird, flew, high} = 12
      /// tokens: [the, cat, sat, on, the, mat, the, dog, ran, in, the, park, the, bird, flew, high] = 16
      final result = VocabularyRichnessMetric.compute(text);
      expect(result, equals(12 / 16));
    });
  });
}
