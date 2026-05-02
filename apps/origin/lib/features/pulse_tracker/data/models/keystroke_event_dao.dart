import 'package:origin/features/pulse_tracker/domain/models/keystroke_event.dart';

/// Data-access object that maps SQLite database rows to [KeystrokeEvent] domain models.
///
/// This DAO lives in the data layer and converts raw column maps produced by
/// [sqflite] into the domain model used by the rest of the app.
class KeystrokeEventDao {
  final String id;
  final String sessionId;
  final int keyCode;
  final String keyName;
  final int tDelta;
  final String timestamp;
  final bool isBackspace;
  final int prevLength;
  final int newLength;

  const KeystrokeEventDao({
    required this.id,
    required this.sessionId,
    required this.keyCode,
    required this.keyName,
    required this.tDelta,
    required this.timestamp,
    required this.isBackspace,
    required this.prevLength,
    required this.newLength,
  });

  /// Construct a [KeystrokeEventDao] from a database row map.
  factory KeystrokeEventDao.fromDb(Map<String, dynamic> map) {
    return KeystrokeEventDao(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      keyCode: map['key_code'] as int,
      keyName: map['key_name'] as String,
      tDelta: map['t_delta'] as int,
      timestamp: map['timestamp'] as String,
      isBackspace: (map['is_backspace'] as int?) == 1,
      prevLength: map['prev_length'] as int? ?? 0,
      newLength: map['new_length'] as int? ?? 0,
    );
  }

  /// Convert this DAO to the domain [KeystrokeEvent].
  KeystrokeEvent toDomain() {
    return KeystrokeEvent(
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
  }
}
