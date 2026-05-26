/// Represents a single raw keystroke event captured from the keyboard listener.
class KeystrokeRawEvent {
  final String key;
  final int timestamp;
  final bool isShift;
  final bool isControl;
  final bool isPauseMarker;
  final int? pauseDuration;

  KeystrokeRawEvent({
    required this.key,
    required this.timestamp,
    this.isShift = false,
    this.isControl = false,
    this.isPauseMarker = false,
    this.pauseDuration,
  });

  @override
  String toString() => 'KeystrokeRawEvent(key: $key, ts: $timestamp, pause: $isPauseMarker)';
}

/// Threshold in milliseconds to detect an input pause.
const _pauseThresholdMs = 2000;

/// Shared state object that bridges [RawKeyboardListener] and [TextInputFormatter].
/// Tracks keystroke dynamics (press timing, sequence) for authenticity analysis.
class KeystrokeTracker {
  final List<KeystrokeRawEvent> recentEvents = [];

  /// Maximum number of recent events to retain in memory.
  static const int maxRecentEvents = 1000;

  int? _lastKeyTimestamp;
  int? _pauseStartMs;

  /// Returns the timestamp (ms) when the current pause started, or null.
  int? get pauseStartMs => _pauseStartMs;

  /// Registers a key event with the tracker.
  void onKey(String key, DateTime time) {
    if (key.isEmpty) return;

    final nowMs = time.millisecondsSinceEpoch;
    final isPause = _lastKeyTimestamp != null &&
        (nowMs - _lastKeyTimestamp!) > _pauseThresholdMs;

    if (isPause) {
      _pauseStartMs = _lastKeyTimestamp;
    }

    _lastKeyTimestamp = nowMs;

    final int? pauseDuration = isPause && _pauseStartMs != null
        ? nowMs - _pauseStartMs!
        : null;

    final event = KeystrokeRawEvent(
      key: key,
      timestamp: nowMs,
      isShift: key.toUpperCase() != key,
      isControl: key.length > 1,
      isPauseMarker: isPause,
      pauseDuration: pauseDuration,
    );

    recentEvents.add(event);
    if (recentEvents.length > maxRecentEvents) {
      recentEvents.removeAt(0);
    }

    // Clear pause tracking after a non-pause event
    if (!isPause) {
      _pauseStartMs = null;
    }
  }

  /// Registers a text field content change event.
  void onTextChange({required String oldText, required String newText}) {
    final insertion = newText.length > oldText.length
        ? newText.substring(oldText.length)
        : '';

    if (insertion.isNotEmpty) {
      for (final char in insertion.split('')) {
        onKey(char, DateTime.now());
      }
    }
  }

  /// Extracts all t_delta values from recent events.
  /// t_delta is the time (in ms) between consecutive keypresses.
  List<double> getTdeltas() {
    final List<double> tdeltas = [];
    int? prevTimestamp;

    for (final event in recentEvents) {
      if (prevTimestamp != null) {
        final delta = (event.timestamp - prevTimestamp).toDouble();
        if (delta >= 0) {
          tdeltas.add(delta);
        }
      }
      prevTimestamp = event.timestamp;
    }

    return tdeltas;
  }

  /// Clears all tracked events and reset state.
  void clear() {
    recentEvents.clear();
    _lastKeyTimestamp = null;
  }
}
