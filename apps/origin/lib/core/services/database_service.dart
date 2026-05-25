import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:uuid/uuid.dart';

import 'encryption_service.dart';

// =============================================================================
// Constants: keys, table/column names
// =============================================================================

const String _dbFileName = 'origin.db';

const String _tblSessions = 'sessions';
const String _tblKeystrokeEvents = 'keystroke_events';
const String _tblOriginStamps = 'origin_stamps';
const String _tblFingerprint = 'fingerprint';

// ----- sessions -------
const String _colSessionsId = 'id';
const String _colSessionsUserId = 'user_id';
const String _colSessionsStartedAt = 'started_at';
const String _colSessionsEndedAt = 'ended_at';
const String _colSessionsContent = 'content';
const String _colSessionsContentLength = 'content_length';
const String _colSessionsEventCount = 'keystroke_event_count';
const String _colSessionsIsCompleted = 'is_completed';

// ----- keystroke_events -------
const String _colEventsId = 'id';
const String _colEventsSessionId = 'session_id';
const String _colEventsKeyCode = 'key_code';
const String _colEventsKeyName = 'key_name';
const String _colEventsTDelta = 't_delta';
const String _colEventsTimestamp = 'timestamp';
const String _colEventsIsBackspace = 'is_backspace';
const String _colEventsPauseMarker = 'pause_marker';
const String _colEventsPauseDuration = 'pause_duration';
const String _colEventsPrevLength = 'prev_length';
const String _colEventsNewLength = 'new_length';

// ----- origin_stamps -------
const String _colStampsId = 'id';
const String _colStampsSessionId = 'session_id';
const String _colStampsUserId = 'user_id';
const String _colStampsContentHash = 'content_hash';
const String _colStampsContentLength = 'content_length';
const String _colStampsTimestamp = 'timestamp';
const String _colStampsAuthScore = 'authenticity_score';
const String _colStampsEventCount = 'keystroke_event_count';
const String _colStampsRhythmEntropy = 'rhythm_entropy';
const String _colStampsRevPatternScore = 'revision_pattern_score';
const String _colStampsCreatedAt = 'created_at';

// ----- fingerprint -------
const String _colFingerprintVocabRichness = 'vocabulary_richness';
const String _colFingerprintAvgTdelta = 'avg_t_delta';
const String _colFingerprintRevisionRatio = 'revision_ratio';
const String _colFingerprintFwordRatio = 'function_word_ratio';
const String _colFingerprintSentLengthStddev = 'sentence_length_stddev';
const String _colFingerprintUpdatedAt = 'updated_at';

const String _delimiterEncrypt = ':';

// =============================================================================
// Encryption helpers
// =============================================================================

/// Service for encrypting/decrypting text with AES-256-CBC.
String? _encryptText(String plainText, String hexKey) {
  try {
    final key = encrypt_pkg.Key.fromBase16(hexKey);
    final iv = encrypt_pkg.IV.fromSecureRandom(16);
    final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  } catch (e) {
    if (kDebugMode) debugPrint('[_encryptText] Error: $e');
    return null;
  }
}

/// Decrypt text encrypted by [_encryptText].
String? _decryptText(String encryptedText, String hexKey) {
  try {
    final parts = encryptedText.split(_delimiterEncrypt);
    if (parts.length != 2) return null;

    final ivActual = encrypt_pkg.IV.fromBase64(parts[0]);
    final key = encrypt_pkg.Key.fromBase16(hexKey);
    final encrypted = encrypt_pkg.Encrypted.fromBase64(parts[1]);
    final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(key));
    return encrypter.decrypt(encrypted, iv: ivActual);
  } catch (e) {
    if (kDebugMode) debugPrint('[_decryptText] Error: $e');
    return null;
  }
}

// =============================================================================
// DatabaseService
// =============================================================================

/// Service for managing the local SQLite database with encrypted content.
class DatabaseService {
  Database? _database;
  String? _encryptionKey;

  // ---------------------------------------------------------------------------
  // Init
  // ---------------------------------------------------------------------------

  /// Initializes [SharedPreferences], loads/creates the encryption key,
  /// and opens/initializes the database.
  Future<void> init() async {
     _encryptionKey = globalEncryptionService.getStoredKey();
    if (_encryptionKey == null) {
       _encryptionKey = globalEncryptionService.generateEncryptionKey();
      await globalEncryptionService.saveKey( _encryptionKey!);
    }

    final dir = await _getApplicationDirectory();
    final dbPath = p.join(dir.path, _dbFileName);

    _database = await openDatabase(
      dbPath,
      version: 3,
      onCreate: _createDatabase,
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE $_tblKeystrokeEvents ADD COLUMN pause_marker INTEGER NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE $_tblKeystrokeEvents ADD COLUMN pause_duration INTEGER NOT NULL DEFAULT 0',
          );
        }
      },
    );
  }

  /// Returns the application support directory.
  Future<Directory> _getApplicationDirectory() async {
    return getApplicationSupportDirectory();
  }

  void _createDatabase(Database db, int version) {
    // keystroke_events
    db.execute('''
      CREATE TABLE IF NOT EXISTS $_tblKeystrokeEvents (
        id            TEXT PRIMARY KEY,
        session_id    TEXT    NOT NULL,
        key_code      INTEGER NOT NULL,
        key_name      TEXT    NOT NULL,
        t_delta       INTEGER NOT NULL,
        timestamp     TEXT    NOT NULL,
        is_backspace  INTEGER NOT NULL DEFAULT 0,
        pause_marker  INTEGER NOT NULL DEFAULT 0,
        pause_duration INTEGER NOT NULL DEFAULT 0,
        prev_length   INTEGER NOT NULL DEFAULT 0,
        new_length    INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // sessions
    db.execute('''
      CREATE TABLE IF NOT EXISTS $_tblSessions (
        id                      TEXT PRIMARY KEY,
        user_id                 TEXT    NOT NULL,
        started_at              TEXT    NOT NULL,
        ended_at                TEXT,
        content                 TEXT    NOT NULL,
        content_length          INTEGER NOT NULL,
        keystroke_event_count   INTEGER NOT NULL DEFAULT 0,
        is_completed            INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // origin_stamps
    db.execute('''
      CREATE TABLE IF NOT EXISTS $_tblOriginStamps (
        id                        TEXT PRIMARY KEY,
        session_id                TEXT    UNIQUE NOT NULL,
        user_id                   TEXT    NOT NULL,
        content_hash              TEXT    NOT NULL,
        content_length            INTEGER NOT NULL,
        timestamp                 TEXT    NOT NULL,
        authenticity_score        REAL,
        keystroke_event_count     INTEGER,
        rhythm_entropy            REAL,
        revision_pattern_score    REAL,
        created_at                TEXT
      )
    ''');

    // fingerprint
    db.execute('''
      CREATE TABLE IF NOT EXISTS $_tblFingerprint (
        id                        INTEGER PRIMARY KEY CHECK (id = 1),
        vocabulary_richness       REAL,
        avg_t_delta               REAL,
        revision_ratio            REAL,
        function_word_ratio       REAL,
        sentence_length_stddev    REAL,
        updated_at                TEXT
      )
    ''');
  }

  // ---------------------------------------------------------------------------
  // KEYS (encryption)
  // ---------------------------------------------------------------------------



  // ---------------------------------------------------------------------------
  // SESSIONS
  // ---------------------------------------------------------------------------

  Future<String> createSession({required String userId}) async {
    final now = DateTime.now().toIso8601String();
    final id = _generateUUID();
    await _database?.insert(
      _tblSessions,
      {
        _colSessionsId: id,
        _colSessionsUserId: userId,
        _colSessionsStartedAt: now,
        _colSessionsEndedAt: null,
        _colSessionsContent: '',
        _colSessionsContentLength: 0,
        _colSessionsEventCount: 0,
        _colSessionsIsCompleted: 0,
      },
    );
    return id;
  }

  Future<void> updateSessionContent({
    required String sessionId,
    required String content,
  }) async {
    final encrypted = _encryptText(content,  _encryptionKey!);
    if (encrypted == null) return;
    await _database?.update(
      _tblSessions,
      {
        _colSessionsContent: encrypted,
        _colSessionsContentLength: content.length,
        _colSessionsEndedAt: DateTime.now().toIso8601String(),
      },
      where: '$_colSessionsId = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> completeSession(String sessionId) async {
    await _database?.update(
      _tblSessions,
      {
        _colSessionsIsCompleted: 1,
        _colSessionsEndedAt: DateTime.now().toIso8601String(),
      },
      where: '$_colSessionsId = ?',
      whereArgs: [sessionId],
    );
  }

  Future<List<Map<String, dynamic>>> getAllSessions() async {
    final results = await _database?.query(
      _tblSessions,
      orderBy: 'started_at DESC',
    );
    return _decryptSessions(results ?? []);
  }

  Future<Map<String, dynamic>?> getSessionById(String sessionId) async {
    final results = await _database?.query(
      _tblSessions,
      where: '$_colSessionsId = ?',
      whereArgs: [sessionId],
    );
    if (results == null || results.isEmpty) return null;
    return _decryptSessions([results.first]).first;
  }

  Future<void> deleteSession(String sessionId) async {
    await _database?.delete(
      _tblKeystrokeEvents,
      where: '$_colEventsSessionId = ?',
      whereArgs: [sessionId],
    );
    await _database?.delete(
      _tblSessions,
      where: '$_colSessionsId = ?',
      whereArgs: [sessionId],
    );
  }

  // ---------------------------------------------------------------------------
  // KEYSTROKE EVENTS
  // ---------------------------------------------------------------------------

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
  }) async {
    await _database?.insert(
      _tblKeystrokeEvents,
      {
        _colEventsId: id,
        _colEventsSessionId: sessionId,
        _colEventsKeyCode: keyCode,
        _colEventsKeyName: keyName,
        _colEventsTDelta: tDelta,
        _colEventsTimestamp: timestamp,
        _colEventsIsBackspace: isBackspace ? 1 : 0,
        _colEventsPauseMarker: 0,
        _colEventsPauseDuration: 0,
        _colEventsPrevLength: prevLength,
        _colEventsNewLength: newLength,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertKeystrokeEventsBatch(List<Map<String, dynamic>> events) async {
    await _database?.transaction((txn) async {
      final batch = txn.batch();
      for (final event in events) {
        batch.insert(
          _tblKeystrokeEvents,
          {
            _colEventsId: event['id'] as String,
            _colEventsSessionId: event['session_id'] as String,
            _colEventsKeyCode: event['key_code'] as int,
            _colEventsKeyName: event['key_name'] as String,
            _colEventsTDelta: event['t_delta'] as int,
            _colEventsTimestamp: event['timestamp'] as String,
            _colEventsIsBackspace: (event['is_backspace'] as bool?) == true ? 1 : 0,
            _colEventsPauseMarker: (event['is_pause_marker'] as int?) ?? 0,
            _colEventsPauseDuration: (event['pause_duration'] as int?) ?? 0,
            _colEventsPrevLength: event['prev_length'] as int,
            _colEventsNewLength: event['new_length'] as int,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit();
    });
  }

  Future<List<Map<String, dynamic>>> getEventsForSession(String sessionId) async {
    return (await _database?.query(
      _tblKeystrokeEvents,
      where: '$_colEventsSessionId = ?',
      whereArgs: [sessionId],
    )) ??
        [];
  }

  Future<void> deleteEventsForSession(String sessionId) async {
    await _database?.delete(
      _tblKeystrokeEvents,
      where: '$_colEventsSessionId = ?',
      whereArgs: [sessionId],
    );
  }

  // ---------------------------------------------------------------------------
  // ORIGIN STAMPS
  // ---------------------------------------------------------------------------

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
  }) async {
    await _database?.insert(
      _tblOriginStamps,
      {
        _colStampsId: id,
        _colStampsSessionId: sessionId,
        _colStampsUserId: userId,
        _colStampsContentHash: contentHash,
        _colStampsContentLength: contentLength,
        _colStampsTimestamp: timestamp,
        _colStampsAuthScore: authenticityScore,
        _colStampsEventCount: keystrokeEventCount,
        _colStampsRhythmEntropy: rhythmEntropy,
        _colStampsRevPatternScore: revisionPatternScore,
        _colStampsCreatedAt: DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getAllStamps() async {
    return (await _database?.query(
      _tblOriginStamps,
      orderBy: 'timestamp DESC',
    )) ??
        [];
  }

  Future<Map<String, dynamic>?> getStampBySessionId(String sessionId) async {
    final results = await _database?.query(
      _tblOriginStamps,
      where: '$_colStampsSessionId = ?',
      whereArgs: [sessionId],
    );
    if (results == null || results.isEmpty) return null;
    return results.first;
  }

  Future<void> deleteStampBySessionId(String sessionId) async {
    await _database?.delete(
      _tblOriginStamps,
      where: '$_colStampsSessionId = ?',
      whereArgs: [sessionId],
    );
  }

  // ---------------------------------------------------------------------------
  // FINGERPRINT
  // ---------------------------------------------------------------------------

  Future<void> upsertFingerprint({
    required double vocabularyRichness,
    required double avgTdelta,
    required double revisionRatio,
    required double functionWordRatio,
    required double sentenceLengthStddev,
    required String updatedAt,
  }) async {
    await _database?.rawInsert(
      '''
        INSERT INTO $_tblFingerprint (id, $_colFingerprintVocabRichness, $_colFingerprintAvgTdelta, $_colFingerprintRevisionRatio, $_colFingerprintFwordRatio, $_colFingerprintSentLengthStddev, $_colFingerprintUpdatedAt)
        VALUES (1, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          $_colFingerprintVocabRichness   = excluded.$_colFingerprintVocabRichness,
          $_colFingerprintAvgTdelta       = excluded.$_colFingerprintAvgTdelta,
          $_colFingerprintRevisionRatio   = excluded.$_colFingerprintRevisionRatio,
          $_colFingerprintFwordRatio      = excluded.$_colFingerprintFwordRatio,
          $_colFingerprintSentLengthStddev = excluded.$_colFingerprintSentLengthStddev,
          $_colFingerprintUpdatedAt       = excluded.$_colFingerprintUpdatedAt
      ''',
      [
        vocabularyRichness,
        avgTdelta,
        revisionRatio,
        functionWordRatio,
        sentenceLengthStddev,
        updatedAt,
      ],
    );
  }

  Future<Map<String, dynamic>?> getFingerprint() async {
    return (await _database?.rawQuery('SELECT * FROM $_tblFingerprint WHERE id = 1'))?.first;
  }

  /// Builds the user's intellectual fingerprint from all completed sessions
  /// and upserts it into the fingerprint table.
  Future<void> buildFingerprint() async {
    final sessions = await getAllSessions();
    if (sessions.isEmpty) return;

    // Filter to only completed sessions
    final completedSessions = sessions.where((s) => s[_colSessionsIsCompleted] == 1).toList();
    if (completedSessions.isEmpty) return;

    // Build per-session stats
    final vocabRichnessValues = <double>[];
    final avgTDeltas = <double>[];
    final revisionRatios = <double>[];
    final functionWordRatios = <double>[];
    final sentenceLengthStddevs = <double>[];

    for (final session in completedSessions) {
      final sessionId = session[_colSessionsId] as String;
      final content = session[_colSessionsContent] as String? ?? '';
      final events = await getEventsForSession(sessionId);

      // Vocabulary richness (Type-Token Ratio)
      vocabRichnessValues.add(_computeVocabularyRichness(content));

      // Average t_delta from events
      final tdeltas = events
          .map((e) => (e[_colEventsTDelta] as num?)?.toDouble() ?? 0)
          .toList();
      if (tdeltas.isNotEmpty) {
        final sum = tdeltas.reduce((a, b) => a + b);
        avgTDeltas.add(sum / tdeltas.length);
      } else {
        avgTDeltas.add(0.0);
      }

      // Revision ratio: backspaces / total events
      int backspaceCount = 0;
      for (final event in events) {
        if ((event[_colEventsIsBackspace] as int?) == 1) {
          backspaceCount++;
        }
      }
      revisionRatios.add(events.isNotEmpty ? backspaceCount / events.length : 0.0);

      // Function word ratio
      functionWordRatios.add(_computeFunctionWordRatio(content));

      // Sentence length standard deviation
      sentenceLengthStddevs.add(_computeSentenceLengthStddev(content));
    }

    // Average across all sessions
    final avgVocabRichness = _average(vocabRichnessValues);
    final avgAvgTDelta = _average(avgTDeltas);
    final avgRevisionRatio = _average(revisionRatios);
    final avgFunctionWordRatio = _average(functionWordRatios);
    final avgSentenceLengthStddev = _average(sentenceLengthStddevs);
    final updatedAt = DateTime.now().toIso8601String();

    await upsertFingerprint(
      vocabularyRichness: avgVocabRichness,
      avgTdelta: avgAvgTDelta,
      revisionRatio: avgRevisionRatio,
      functionWordRatio: avgFunctionWordRatio,
      sentenceLengthStddev: avgSentenceLengthStddev,
      updatedAt: updatedAt,
    );
  }

  /// Compute Type-Token Ratio for content.
  double _computeVocabularyRichness(String content) {
    if (content.trim().isEmpty) return 0.0;
    final words = content
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    return words.isNotEmpty ? words.toSet().length / words.length : 0.0;
  }

  /// Compute the average of a list of values.
  double _average(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Compute function word ratio: (stop words count / total word count).
  double _computeFunctionWordRatio(String content) {
    if (content.trim().isEmpty) return 0.0;
    final words = content
        .toLowerCase()
        .split(RegExp(r'[^\p{L}]+', unicode: true))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return 0.0;

    final stopWords = {
      'a', 'an', 'the', 'and', 'or', 'but', 'nor', 'for', 'yet', 'so',
      'in', 'on', 'at', 'to', 'of', 'with', 'by', 'from', 'as',
      'is', 'was', 'are', 'were', 'be', 'been', 'being', 'have', 'has',
      'had', 'do', 'does', 'did', 'will', 'would', 'shall', 'should',
      'can', 'could', 'may', 'might', 'must', 'that', 'this', 'these',
      'those', 'it', 'its', 'i', 'me', 'my', 'we', 'our', 'you', 'your',
      'he', 'him', 'his', 'she', 'her', 'they', 'them', 'their', 'what',
      'which', 'who', 'whom', 'whose', 'where', 'when', 'why', 'how',
    };

    int stopWordCount = 0;
    for (final word in words) {
      if (stopWords.contains(word)) {
        stopWordCount++;
      }
    }
    return stopWordCount / words.length;
  }

  /// Compute standard deviation of sentence lengths (split by '.', '!', '?').
  double _computeSentenceLengthStddev(String content) {
    final sentences = content
        .split(RegExp(r'[.!?]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((s) => s.length.toDouble())
        .toList();

    if (sentences.length <= 1) return 0.0;

    final mean = sentences.reduce((a, b) => a + b) / sentences.length;
    final variance = sentences
        .map((s) => (s - mean) * (s - mean))
        .reduce((a, b) => a + b) /
        sentences.length;
    return math.sqrt(variance);
  }

  // ---------------------------------------------------------------------------
  // UTILS
  // ---------------------------------------------------------------------------

  /// Encrypt plaintext using AES-256-CBC with the stored key.
  String? encryptText(String plainText) =>
       _encryptionKey != null ? _encryptText(plainText,  _encryptionKey!) : null;

  /// Decrypt ciphertext.
  String? decryptText(String encryptedText) =>
       _encryptionKey != null ? _decryptText(encryptedText,  _encryptionKey!) : null;

  /// Close database.
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  // ---------------------------------------------------------------------------
  // HELPERS (private)
  // ---------------------------------------------------------------------------

  /// Decrypts the [content] field in a list of session maps in-place.
  List<Map<String, dynamic>> _decryptSessions(List<Map<String, dynamic>> sessions) {
    final result = <Map<String, dynamic>>[];
    for (final session in sessions) {
      final copy = Map<String, dynamic>.from(session);
      final encrypted = copy[_colSessionsContent] as String?;
      if (encrypted != null && encrypted.isNotEmpty &&  _encryptionKey != null) {
        final decrypted = _decryptText(encrypted,  _encryptionKey!);
        if (decrypted != null) {
          copy[_colSessionsContent] = decrypted;
        }
      }
      result.add(copy);
    }
    return result;
  }

  String _generateUUID() => const Uuid().v4();
}

// =============================================================================
// Async lazy-initialized singleton provider (matching preference_service pattern)
// =============================================================================

final globalDatabaseService = DatabaseService();
