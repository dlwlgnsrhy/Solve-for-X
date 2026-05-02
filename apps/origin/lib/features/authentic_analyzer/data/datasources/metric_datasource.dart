import 'package:origin/core/services/database_service.dart';

/// Data source for querying session and keystroke data needed by metrics.
/// Thin adapter over [DatabaseService].
class MetricDataSource {
  final DatabaseService _db = globalDatabaseService;

  Future<List<Map<String, dynamic>>> getSessions() => _db.getAllSessions();

  Future<List<Map<String, dynamic>>> getEventsForSession(String sessionId) => _db.getEventsForSession(sessionId);

  Future<Map<String, dynamic>?> getSessionById(String sessionId) => _db.getSessionById(sessionId);
}
