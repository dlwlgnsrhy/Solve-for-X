import 'package:origin/core/services/database_service.dart';

/// Data source for origin stamp CRUD operations.
/// Thin adapter over [DatabaseService].
class StampSqliteDataSource {
  final DatabaseService _db = globalDatabaseService;

  Future<void> createStamp({
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
  }) => _db.createOriginStamp(
    id: id, sessionId: sessionId, userId: userId,
    contentHash: contentHash, contentLength: contentLength,
    timestamp: timestamp, authenticityScore: authenticityScore,
    keystrokeEventCount: keystrokeEventCount,
    rhythmEntropy: rhythmEntropy, revisionPatternScore: revisionPatternScore,
  );

  Future<List<Map<String, dynamic>>> getAllStamps() => _db.getAllStamps();

  Future<Map<String, dynamic>?> getStampBySession(String sessionId) => _db.getStampBySessionId(sessionId);
}
