import 'package:origin/core/services/database_service.dart';

/// Data source for keystroke events and sessions.
/// Thin adapter over [DatabaseService].
class KeystrokeSqliteDataSource {
  final DatabaseService _db = globalDatabaseService;

  Future<void> insertEvent({
    required String id,
    required String sessionId,
    required int keyCode,
    required String keyName,
    required int tDelta,
    required String timestamp,
    bool isBackspace = false,
    int prevLength = 0,
    int newLength = 0,
  }) => _db.insertKeystrokeEvent(
    id: id, sessionId: sessionId, keyCode: keyCode,
    keyName: keyName, tDelta: tDelta, timestamp: timestamp,
    isBackspace: isBackspace, prevLength: prevLength, newLength: newLength,
  );

  Future<void> insertEventsBatch(List<Map<String, dynamic>> events) => _db.insertKeystrokeEventsBatch(events);

  Future<List<Map<String, dynamic>>> getEvents(String sessionId) => _db.getEventsForSession(sessionId);
}
