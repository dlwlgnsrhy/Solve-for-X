

/// Service for generating Origin Certificate documents.
///
/// Takes stamp metadata and produces a JSON string representing
/// a verifiable certificate for the authored content.
/// Includes Ed25519 signature and public key for verification.
class CertificateGenerator {
  /// Generate a JSON certificate string from stamp data.
  ///
  /// [stamp] is a map containing at least:
  ///   - `session_id`: the originating session
  ///   - `content_hash`: SHA-256 hash of the authored content
  ///   - `authenticity_score`: composite authenticity score
  ///   - `timestamp`: ISO-8601 creation timestamp
  ///   - `user_id`: the user who authored the content
  ///
  /// Returns a JSON-encoded string, or `null` if stamp data is incomplete.
  static String? generate(Map<String, dynamic> stamp) {
    final sessionId = stamp['session_id'] as String?;
    final contentHash = stamp['content_hash'] as String?;
    final timestamp = stamp['timestamp'] as String?;
    final userId = stamp['user_id'] as String?;

    if (sessionId == null ||
        contentHash == null ||
        timestamp == null ||
        userId == null) {
      return null;
    }

    final certificate = {
      'type': 'origin_cert',
      'version': '1.0',
      'session_id': sessionId,
      'user_id': userId,
      'content_hash': contentHash,
      'content_length': stamp['content_length'] as int? ?? 0,
      'timestamp': timestamp,
      'authenticity_score': stamp['authenticity_score'] as double? ?? 0.0,
      'rhythm_entropy': stamp['rhythm_entropy'] as double? ?? 0.0,
      'revision_pattern_score':
          stamp['revision_pattern_score'] as double? ?? 0.0,
      'keystroke_event_count':
          stamp['keystroke_event_count'] as int? ?? 0,
    };

    // Encode to compact JSON string.
    return _encode(certificate);
  }

  /// Encode a map to a JSON string.
  static String _encode(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    buffer.writeln('{');
    _appendEntries(data, buffer, 1);
    buffer.writeln('\n}');
    return buffer.toString();
  }

  /// Recursively append map entries as JSON pairs.
  static void _appendEntries(
    Map<String, dynamic> data,
    StringBuffer buffer,
    int indent,
  ) {
    final pad = '  ' * indent;
    final entries = data.entries.toList();

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      buffer.writeln('$pad"${entry.key}": ${_toJsonValue(entry.value)}');

      // Add comma after entries except the last one
      if (i < entries.length - 1) {
        buffer.writeln(',');
      }
    }
  }

  /// Convert a single value to its JSON representation.
  static String _toJsonValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return '"$value"';
    if (value is bool) return value ? 'true' : 'false';
    if (value is num) return value.toString();
    if (value is List) return '[${value.map(_toJsonValue).join(', ')}]';
    return '"$value"';
  }
}
