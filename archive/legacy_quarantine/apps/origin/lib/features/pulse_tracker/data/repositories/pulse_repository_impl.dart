import 'package:origin/core/services/database_service.dart';

import '../../domain/repositories/pulse_repository.dart';

class PulseRepositoryImpl implements PulseRepository {
  final DatabaseService db = globalDatabaseService;

  @override
  Future<String> createSession({required String userId}) =>
      db.createSession(userId: userId);

  @override
  Future<void> updateSessionContent({
    required String sessionId,
    required String content,
  }) =>
      db.updateSessionContent(sessionId: sessionId, content: content);

  @override
  Future<void> completeSession(String sessionId) => db.completeSession(sessionId);

  @override
  Future<Map<String, dynamic>?> getSession(String sessionId) =>
      db.getSessionById(sessionId);

  @override
  Future<List<Map<String, dynamic>>> getAllSessions() => db.getAllSessions();

  @override
  Future<void> insertKeystrokeEvent({
    required String id,
    required String sessionId,
    required int keyCode,
    required String keyName,
    required int tDelta,
    required String timestamp,
    bool isBackspace = false,
    int prevLength = 0,
    int newLength = 0,
  }) =>
      db.insertKeystrokeEvent(
        id: id,
        sessionId: sessionId,
        keyCode: keyCode,
        keyName: keyName,
        tDelta: tDelta,
        timestamp: timestamp,
        isBackspace: isBackspace,
        prevLength: prevLength,
        newLength: newLength,
      );

  @override
  Future<void> insertKeystrokeEventsBatch(List<Map<String, dynamic>> events) =>
      db.insertKeystrokeEventsBatch(events);

  @override
  Future<List<Map<String, dynamic>>> getEventsForSession(String sessionId) =>
      db.getEventsForSession(sessionId);

  @override
  Future<void> deleteSession(String sessionId) => db.deleteSession(sessionId);
}
