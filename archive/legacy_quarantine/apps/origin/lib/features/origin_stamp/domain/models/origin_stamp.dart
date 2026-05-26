/// Domain model for an Origin Stamp (certificate).
class OriginStamp {
  final String id;
  final String sessionId;
  final String userId;
  final String contentHash;
  final int contentLength;
  final String timestamp;
  final double authenticityScore;
  final int keystrokeEventCount;
  final double rhythmEntropy;
  final double revisionPatternScore;
  final String? createdAt;

  OriginStamp({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.contentHash,
    required this.contentLength,
    required this.timestamp,
    required this.authenticityScore,
    this.keystrokeEventCount = 0,
    required this.rhythmEntropy,
    required this.revisionPatternScore,
    this.createdAt,
  });
}
