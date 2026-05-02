/// Repository interface for authenticity scoring and stamping data.
/// Implementations use DatabaseService as the backing store.
abstract class AuthenticityRepository {
  Future<void> createOriginStamp({
    required String id,
    required String sessionId,
    required String userId,
    required String contentHash,
    required int contentLength,
    required String timestamp,
    required double authenticityScore,
    required int keystrokeEventCount,
    required double rhythmEntropy,
    required double revisionPatternScore,
  });
  Future<List<Map<String, dynamic>>> getAllStamps();
  Future<Map<String, dynamic>?> getStampBySessionId(String sessionId);
  Future<void> deleteStampBySessionId(String sessionId);
  Future<void> upsertFingerprint({
    required double vocabularyRichness,
    required double avgTdelta,
    required double revisionRatio,
    required double functionWordRatio,
    required double sentenceLengthStddev,
    required String updatedAt,
  });
  Future<Map<String, dynamic>?> getFingerprint();
}
