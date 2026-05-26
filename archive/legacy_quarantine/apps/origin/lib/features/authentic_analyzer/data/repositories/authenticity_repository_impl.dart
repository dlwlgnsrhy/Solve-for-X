import 'package:origin/core/services/database_service.dart';

import '../../domain/repositories/authenticity_repository.dart';

class AuthenticityRepositoryImpl implements AuthenticityRepository {
  final DatabaseService db = globalDatabaseService;

  @override
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
  }) =>
      db.createOriginStamp(
        id: id,
        sessionId: sessionId,
        userId: userId,
        contentHash: contentHash,
        contentLength: contentLength,
        timestamp: timestamp,
        authenticityScore: authenticityScore,
        keystrokeEventCount: keystrokeEventCount,
        rhythmEntropy: rhythmEntropy,
        revisionPatternScore: revisionPatternScore,
      );

  @override
  Future<List<Map<String, dynamic>>> getAllStamps() => db.getAllStamps();

  @override
  Future<Map<String, dynamic>?> getStampBySessionId(String sessionId) =>
      db.getStampBySessionId(sessionId);

  @override
  Future<void> deleteStampBySessionId(String sessionId) =>
      db.deleteStampBySessionId(sessionId);

  @override
  Future<void> upsertFingerprint({
    required double vocabularyRichness,
    required double avgTdelta,
    required double revisionRatio,
    required double functionWordRatio,
    required double sentenceLengthStddev,
    required String updatedAt,
  }) =>
      db.upsertFingerprint(
        vocabularyRichness: vocabularyRichness,
        avgTdelta: avgTdelta,
        revisionRatio: revisionRatio,
        functionWordRatio: functionWordRatio,
        sentenceLengthStddev: sentenceLengthStddev,
        updatedAt: updatedAt,
      );

  @override
  Future<Map<String, dynamic>?> getFingerprint() => db.getFingerprint();
}
