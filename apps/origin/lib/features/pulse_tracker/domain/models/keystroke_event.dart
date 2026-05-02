/// Domain model for a single keystroke event.
class KeystrokeEvent {
  final String id;
  final String sessionId;
  final int keyCode;
  final String keyName;
  final int tDelta;
  final String timestamp;
  final bool isBackspace;
  final int prevLength;
  final int newLength;

  KeystrokeEvent({
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'session_id': sessionId,
    'key_code': keyCode,
    'key_name': keyName,
    't_delta': tDelta,
    'timestamp': timestamp,
    'is_backspace': isBackspace ? 1 : 0,
    'prev_length': prevLength,
    'new_length': newLength,
  };
}
