/// Repository interface for pulse (keystroke) data.
/// Implementations use DatabaseService as the backing store.
abstract class PulseRepository {
  Future<String> createSession({required String userId});
  Future<void> updateSessionContent({required String sessionId, required String content});
  Future<void> completeSession(String sessionId);
  Future<Map<String, dynamic>?> getSession(String sessionId);
  Future<List<Map<String, dynamic>>> getAllSessions();
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
  });
  Future<void> insertKeystrokeEventsBatch(List<Map<String, dynamic>> events);
  Future<List<Map<String, dynamic>>> getEventsForSession(String sessionId);
  Future<void> deleteSession(String sessionId);
}
