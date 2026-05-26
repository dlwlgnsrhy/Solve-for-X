/// Domain model for user's intellectual fingerprint (long-term style profile).
class WritingFingerprint {
  final double vocabularyRichness;
  final double avgTDelta;
  final double revisionRatio;
  final double functionWordRatio;
  final double sentenceLengthStddev;
  final String updatedAt;

  WritingFingerprint({
    required this.vocabularyRichness,
    required this.avgTDelta,
    required this.revisionRatio,
    required this.functionWordRatio,
    required this.sentenceLengthStddev,
    required this.updatedAt,
  });
}
