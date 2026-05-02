/// Domain model for authenticity scoring results.
class AuthenticityResult {
  final String sessionId;
  final double compositeScore;
  final double rhythmEntropy;
  final double revisionPatternScore;
  final double vocabularyRichness;
  final double temporalConsistency;

  AuthenticityResult({
    required this.sessionId,
    required this.compositeScore,
    required this.rhythmEntropy,
    required this.revisionPatternScore,
    required this.vocabularyRichness,
    required this.temporalConsistency,
  });
}
