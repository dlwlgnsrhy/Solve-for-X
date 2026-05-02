/// Represents a single raw keystroke event captured from the keyboard listener.
class KeystrokeRawEvent {
  final String key;
  final int timestamp;
  final bool isShift;
  final bool isControl;

  KeystrokeRawEvent({
    required this.key,
    required this.timestamp,
    this.isShift = false,
    this.isControl = false,
  });

  @override
  String toString() => 'KeystrokeRawEvent(key: $key, ts: $timestamp)';
}

/// Shared state object that bridges [RawKeyboardListener] and [TextInputFormatter].
/// Tracks keystroke dynamics (press timing, sequence) for authenticity analysis.
class KeystrokeTracker {
  final List<KeystrokeRawEvent> recentEvents = [];

  /// Maximum number of recent events to retain in memory.
  static const int maxRecentEvents = 1000;

  /// Registers a key event with the tracker.
  void onKey(String key, DateTime time) {
    if (key.isEmpty) return;

    final event = KeystrokeRawEvent(
      key: key,
      timestamp: time.millisecondsSinceEpoch,
      isShift: key.toUpperCase() != key,
      isControl: key.length > 1,
    );

    recentEvents.add(event);
    if (recentEvents.length > maxRecentEvents) {
      recentEvents.removeAt(0);
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
  }
}
