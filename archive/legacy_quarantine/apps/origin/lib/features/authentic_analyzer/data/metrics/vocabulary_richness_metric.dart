/// Vocabulary Richness Metric: Type-Token Ratio (TTR).
///
/// Measures lexical diversity by dividing the number of unique words (types)
/// by the total word count (tokens):
///   ttr = uniqueWords / totalWords
/// Range: [0.0, 1.0] where 1.0 = every word is unique.
class VocabularyRichnessMetric {
  /// Compute type-token ratio.
  ///
  /// [text] is the document text to analyze.
  /// Words are split by whitespace and lowercased.
  static double compute(String text) {
    final words = text
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    return words.isNotEmpty ? words.toSet().length / words.length : 0.0;
  }
}
