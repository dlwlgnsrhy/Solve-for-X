import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';

import 'package:origin/core/utils/keystroke_tracker.dart';
import 'package:origin/features/authentic_analyzer/data/metrics/rhythm_entropy_metric.dart';
import 'package:origin/features/authentic_analyzer/data/metrics/revision_pattern_metric.dart';
import 'package:origin/features/authentic_analyzer/data/metrics/vocabulary_richness_metric.dart';
import 'package:origin/features/authentic_analyzer/data/metrics/temporal_consistency_metric.dart';

import 'package:origin/core/services/database_service.dart';
import 'package:origin/core/services/preference_service.dart';
import 'package:origin/core/services/encryption_service.dart';

// =========================================================
// FAKE implementation (in-memory, no platform deps)
// =========================================================

class OriginStampData {
  final String id, sessionId, userId, contentHash;
  final int contentLength;
  final String timestamp;
  final double authenticityScore, rhythmEntropy, revisionPatternScore;
  final int keystrokeEventCount;
  Map<String, dynamic> toMap() => {
        'id': id, 'session_id': sessionId, 'user_id': userId,
        'content_hash': contentHash, 'content_length': contentLength,
        'timestamp': timestamp, 'authenticity_score': authenticityScore,
        'keystroke_event_count': keystrokeEventCount,
        'rhythm_entropy': rhythmEntropy,
        'revision_pattern_score': revisionPatternScore,
      };
  OriginStampData({
    required this.id, required this.sessionId, required this.userId,
    required this.contentHash, required this.contentLength,
    required this.timestamp, required this.authenticityScore,
    required this.keystrokeEventCount, required this.rhythmEntropy,
    required this.revisionPatternScore,
  });
}

class ScoreData {
  final double composite, rhythmEntropy, revisionPatternScore;
  final double vocabularyRichness, temporalConsistency;
  ScoreData({
    required this.composite, required this.rhythmEntropy,
    required this.revisionPatternScore,
    required this.vocabularyRichness, required this.temporalConsistency,
  });
}

abstract class TestableOriginService {
  String get userId;
  Future<void> init();
  Future<void> reset();
  Future<String> createSession(String userId);
  Future<void> updateSessionContent(String sessionId, String content);
  Future<void> completeSession(String sessionId);
  Future<List<Map<String, dynamic>>> getAllSessions();
  Future<Map<String, dynamic>?> getSessionById(String sessionId);
  Future<void> deleteSession(String sessionId);
  Future<void> insertEventsBatch(List<Map<String, dynamic>> events);
  Future<List<Map<String, dynamic>>> getEvents(String sessionId);
  Future<void> createStamp(OriginStampData stamp);
  Future<List<Map<String, dynamic>>> getAllStamps();
  Future<Map<String, dynamic>?> getStampBySession(String sessionId);
  Future<void> deleteStamp(String sessionId);
  Future<void> upsertFingerprint(Map<String, dynamic> fp);
  Future<Map<String, dynamic>?> getFingerprint();
  Future<void> buildFingerprint();
  ScoreData computeScores({
    required List<double> tdeltas,
    required String content,
    required int backspaceCount,
  });
}

class FakeOriginService implements TestableOriginService {
  final Map<String, Map<String, dynamic>> _sessions = {};
  final Map<String, List<Map<String, dynamic>>> _events = {};
  final Map<String, Map<String, dynamic>> _stamps = {};
  Map<String, dynamic>? _fingerprint;
  final String _encKey = 'testkey-0000-4000-a000-000000000001';

  @override
  Future<void> init() async => _sessions.clear();

  @override
  Future<void> reset() async {
    _sessions.clear(); _events.clear(); _stamps.clear(); _fingerprint = null;
  }

  @override
  String get userId => 'test-user-id-1111-4000-a000-000000000001';

  String _enc(String plain) {
    try {
      final b = utf8.encode(plain);
      final k = utf8.encode(_encKey);
      final r = List<int>.generate(b.length, (i) => b[i] ^ k[i % k.length]);
      return base64Encode(r);
    } catch (_) { return plain; }
  }

  String _dec(String enc) {
    try {
      final b = base64Decode(enc);
      final k = utf8.encode(_encKey);
      final r = List<int>.generate(b.length, (i) => b[i] ^ k[i % k.length]);
      return utf8.decode(r);
    } catch (_) { return enc; }
  }

  @override
  Future<String> createSession(String userId) async {
    final id = _genUUID();
    _sessions[id] = {
      'id': id, 'user_id': userId,
      'started_at': DateTime.now().toIso8601String(),
      'ended_at': null, 'content': '', 'content_length': 0, 'is_completed': 0,
    };
    _events[id] = [];
    return id;
  }

  @override
  Future<void> updateSessionContent(String sessionId, String content) async {
    final s = _sessions[sessionId];
    if (s == null) return;
    s['content'] = _enc(content);
    s['content_length'] = content.length;
    s['ended_at'] = DateTime.now().toIso8601String();
  }

  @override
  Future<void> completeSession(String sessionId) async {
    final s = _sessions[sessionId];
    if (s == null) return;
    s['is_completed'] = 1;
    s['ended_at'] = DateTime.now().toIso8601String();
    s['content'] = _dec(s['content'] as String);
  }

  @override
  Future<List<Map<String, dynamic>>> getAllSessions() async =>
      _sessions.values.map((s) => Map<String, dynamic>.from(s))
          .toList()..sort((a, b) => (b['started_at'] as String).compareTo(a['started_at'] as String));

  @override
  Future<Map<String, dynamic>?> getSessionById(String sessionId) async {
    final s = _sessions[sessionId];
    return s != null ? Map<String, dynamic>.from(s) : null;
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    _sessions.remove(sessionId);
    _events.remove(sessionId);
    _stamps.remove(sessionId);
  }

  @override
  Future<void> insertEventsBatch(List<Map<String, dynamic>> events) async {
    final sid = events.first['session_id'] as String?;
    if (sid == null) return;
    if (_events[sid] == null) _events[sid] = [];
    _events[sid]!.addAll(events);
  }

  @override
  Future<List<Map<String, dynamic>>> getEvents(String sessionId) async => _events[sessionId] ?? [];

  @override
  Future<void> createStamp(OriginStampData stamp) async => _stamps[stamp.sessionId] = stamp.toMap();

  @override
  Future<List<Map<String, dynamic>>> getAllStamps() async => _stamps.values.toList();

  @override
  Future<Map<String, dynamic>?> getStampBySession(String sessionId) async => _stamps[sessionId];

  @override
  Future<void> deleteStamp(String sessionId) async => _stamps.remove(sessionId);

  @override
  Future<void> upsertFingerprint(Map<String, dynamic> fp) async => _fingerprint = fp;

  @override
  Future<Map<String, dynamic>?> getFingerprint() async => _fingerprint;

  @override
  Future<void> buildFingerprint() async {
    final sessions = await getAllSessions();
    final completed = sessions.where((s) => s['is_completed'] == 1).toList();
    if (completed.isEmpty) return;

    final vocabVals = <double>[];
    final tdeltaVals = <double>[];
    final revRatios = <double>[];
    final funcWordRatios = <double>[];
    final sentStddevs = <double>[];

    for (final session in completed) {
      final sid = session['id'] as String;
      final content = (session['content'] as String?) ?? '';
      final allEvts = await getEvents(sid);

      vocabVals.add(_vocabRichness(content));

      final tds = allEvts.map((e) => (e['t_delta'] as num?)?.toDouble() ?? 0).toList();
      if (tds.isNotEmpty) {
        tdeltaVals.add(tds.reduce((a, b) => a + b) / tds.length);
      } else {
        tdeltaVals.add(0.0);
      }

      int bc = 0;
      for (final e in allEvts) {
        if ((e['is_backspace'] is bool ? e['is_backspace'] as bool : (e['is_backspace'] as num?) == 1)) {
          bc++;
        }
      }
      revRatios.add(allEvts.isNotEmpty ? bc / allEvts.length : 0.0);
      funcWordRatios.add(_funcWordRatio(content));
      sentStddevs.add(_sentStddev(content));
    }

    await upsertFingerprint({
      'vocabulary_richness': _avg(vocabVals),
      'avg_t_delta': _avg(tdeltaVals),
      'revision_ratio': _avg(revRatios),
      'function_word_ratio': _avg(funcWordRatios),
      'sentence_length_stddev': _avg(sentStddevs),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  ScoreData computeScores({
    required List<double> tdeltas, required String content, required int backspaceCount,
  }) {
    if (tdeltas.isEmpty) {
      return ScoreData(composite: 0.0, rhythmEntropy: 0.0, revisionPatternScore: 1.0,
          vocabularyRichness: 0.0, temporalConsistency: 0.5);
    }
    final re = RhythmEntropyMetric.compute(tdeltas);
    final rp = RevisionPatternMetric.compute(eventCount: 1, backspaceCount: backspaceCount);
    final vr = VocabularyRichnessMetric.compute(content);
    final tc = TemporalConsistencyMetric.compute(tdeltas);
    final comp = (0.35 * re + 0.25 * rp + 0.20 * vr + 0.20 * tc) * 100.0;
    return ScoreData(composite: comp, rhythmEntropy: re, revisionPatternScore: rp,
        vocabularyRichness: vr, temporalConsistency: tc);
  }

  String _genUUID() {
    final bytes = List<int>.generate(16, (_) => 0);
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-4${hex.substring(13)}-a${hex.substring(17)}-${hex.substring(20)}';
  }

  double _avg(List<double> v) => v.isEmpty ? 0.0 : v.reduce((a, b) => a + b) / v.length;
  double _vocabRichness(String c) {
    if (c.trim().isEmpty) return 0.0;
    final w = c.toLowerCase().split(RegExp(r'\s+')).where((x) => x.isNotEmpty).toList();
    return w.isNotEmpty ? w.toSet().length / w.length : 0.0;
  }
  double _funcWordRatio(String c) {
    if (c.trim().isEmpty) return 0.0;
    final w = c.toLowerCase().split(RegExp(r'[^\p{L}]+', unicode: true)).where((x) => x.isNotEmpty).toList();
    if (w.isEmpty) return 0.0;
    const sw = {'a','an','the','and','or','but','nor','for','yet','so','in','on','at','to','of','with','by','from','as','is','was','are','were','be','been','being','it','its','i','we','our','he','she','they','them','their','this','that'};
    int c2 = 0;
    for (final wd in w) { if (sw.contains(wd)) c2++; }
    return c2 / w.length;
  }
  double _sentStddev(String c) {
    final ss = c.split(RegExp(r'[.!?]+')).map((s) => s.trim()).where((s) => s.isNotEmpty).map((s) => s.length.toDouble()).toList();
    if (ss.length <= 1) return 0.0;
    final m = ss.reduce((a, b) => a + b) / ss.length;
    final v = ss.map((s) => math.pow(s - m, 2)).reduce((a, b) => a + b) / ss.length;
    return math.sqrt(v);
  }
}

// =========================================================
// REAL implementation (delegates to app singletons)
// =========================================================

class RealOriginService implements TestableOriginService {
  @override
  String get userId => globalPreferenceService.userId;

  @override
  Future<void> init() async {
    await globalPreferenceService.init();
    await globalEncryptionService.init();
    await globalDatabaseService.init();
  }

  @override
  Future<void> reset() async {
    final stamps = await globalDatabaseService.getAllStamps();
    for (final s in stamps) { await globalDatabaseService.deleteStampBySessionId(s['session_id']); }
    final sessions = await globalDatabaseService.getAllSessions();
    for (final s in sessions) { await globalDatabaseService.deleteSession(s['id'] as String); }
  }

  @override
  Future<String> createSession(String userId) => globalDatabaseService.createSession(userId: userId);

  @override
  Future<void> updateSessionContent(String sid, String c) =>
      globalDatabaseService.updateSessionContent(sessionId: sid, content: c);

  @override
  Future<void> completeSession(String sid) => globalDatabaseService.completeSession(sid);

  @override
  Future<List<Map<String, dynamic>>> getAllSessions() => globalDatabaseService.getAllSessions();

  @override
  Future<Map<String, dynamic>?> getSessionById(String sid) => globalDatabaseService.getSessionById(sid);

  @override
  Future<void> deleteSession(String sid) => globalDatabaseService.deleteSession(sid);

  @override
  Future<void> insertEventsBatch(List<Map<String, dynamic>> evts) =>
      globalDatabaseService.insertKeystrokeEventsBatch(evts);

  @override
  Future<List<Map<String, dynamic>>> getEvents(String sid) =>
      globalDatabaseService.getEventsForSession(sid);

  @override
  Future<void> createStamp(OriginStampData stamp) => globalDatabaseService.createOriginStamp(
    id: stamp.id, sessionId: stamp.sessionId, userId: stamp.userId,
    contentHash: stamp.contentHash, contentLength: stamp.contentLength,
    timestamp: stamp.timestamp, authenticityScore: stamp.authenticityScore,
    keystrokeEventCount: stamp.keystrokeEventCount,
    rhythmEntropy: stamp.rhythmEntropy, revisionPatternScore: stamp.revisionPatternScore,
  );

  @override
  Future<List<Map<String, dynamic>>> getAllStamps() => globalDatabaseService.getAllStamps();

  @override
  Future<Map<String, dynamic>?> getStampBySession(String sid) =>
      globalDatabaseService.getStampBySessionId(sid);

  @override
  Future<void> deleteStamp(String sid) => globalDatabaseService.deleteStampBySessionId(sid);

  @override
  Future<void> upsertFingerprint(Map<String, dynamic> fp) => globalDatabaseService.upsertFingerprint(
    vocabularyRichness: fp['vocabulary_richness'] as double,
    avgTdelta: fp['avg_t_delta'] as double,
    revisionRatio: fp['revision_ratio'] as double,
    functionWordRatio: fp['function_word_ratio'] as double,
    sentenceLengthStddev: fp['sentence_length_stddev'] as double,
    updatedAt: fp['updated_at'] as String,
  );

  @override
  Future<Map<String, dynamic>?> getFingerprint() => globalDatabaseService.getFingerprint();

  @override
  Future<void> buildFingerprint() => globalDatabaseService.buildFingerprint();

  @override
  ScoreData computeScores({
    required List<double> tdeltas, required String content, required int backspaceCount,
  }) {
    if (tdeltas.isEmpty) {
      return ScoreData(composite: 0.0, rhythmEntropy: 0.0, revisionPatternScore: 1.0,
          vocabularyRichness: 0.0, temporalConsistency: 0.5);
    }
    final re = RhythmEntropyMetric.compute(tdeltas);
    final rp = RevisionPatternMetric.compute(eventCount: 1, backspaceCount: backspaceCount);
    final vr = VocabularyRichnessMetric.compute(content);
    final tc = TemporalConsistencyMetric.compute(tdeltas);
    final comp = (0.35 * re + 0.25 * rp + 0.20 * vr + 0.20 * tc) * 100.0;
    return ScoreData(composite: comp, rhythmEntropy: re, revisionPatternScore: rp,
        vocabularyRichness: vr, temporalConsistency: tc);
  }
}

// =========================================================
// INTEGRATION TESTS
// =========================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Use fake service for VM tests (no platform-channel dependencies)
  final service = FakeOriginService();
  late String testSessionId;

  setUp(() async {
    await service.init();
    await service.reset();
  });

  tearDown(() async {
    try {
      await service.deleteStamp(testSessionId);
      await service.deleteSession(testSessionId);
    } catch (_) {}
  });

  group('End-to-end: keystroke → score → stamp → fingerprint', () {

    test('full pipeline: keystrokes -> scores -> stamp -> verify -> fingerprint', () async {
      final userId = service.userId;
      expect(userId, isNotEmpty);

      testSessionId = await service.createSession(userId);
      expect(testSessionId, isNotEmpty);

      // Simulate keystrokes with realistic timing
      final tracker = KeystrokeTracker();
      final testText = 'The quick brown fox jumps over the lazy dog.';
      final baseTime = DateTime.now().subtract(const Duration(seconds: 30));

      final timings = [
        0, 85, 120, 95, 200, 45, 110, 88, 150, 95,
        75, 130, 210, 60, 140, 90, 105, 180, 70, 95,
        115, 200, 80, 125, 160, 75, 100, 85,
      ];
      // Pad timings array to cover all characters (cycle through to fill)
      while (timings.length < testText.length) {
        timings.add(100); // default timing
      }
      for (var i = 0; i < testText.length; i++) {
        final ms = timings.take(i + 1).reduce((a, b) => a + b);
        tracker.onKey(testText[i], baseTime.add(Duration(milliseconds: ms)));
      }
      expect(tracker.recentEvents, hasLength(testText.length));

      // Simulate backspace
      tracker.onTextChange(
          oldText: testText,
          newText: testText.substring(0, testText.length - 1));

      // Compute all 4 metrics
      final tdeltas = tracker.getTdeltas();
      expect(tdeltas.length, greaterThan(0));

      final rhythmEntropy = RhythmEntropyMetric.compute(tdeltas);
      final revisionScore = RevisionPatternMetric.compute(
        eventCount: tracker.recentEvents.length,
        backspaceCount: 1,
      );
      final vocabRichness = VocabularyRichnessMetric.compute(testText);
      final temporalConsistency = TemporalConsistencyMetric.compute(tdeltas);

      expect(rhythmEntropy, inInclusiveRange(0.0, 1.0));
      expect(revisionScore, inInclusiveRange(0.0, 1.0));
      expect(vocabRichness, inInclusiveRange(0.0, 1.0));
      expect(temporalConsistency, inInclusiveRange(0.0, 1.0));

      final scores = service.computeScores(
        tdeltas: tdeltas,
        content: testText,
        backspaceCount: 1,
      );
      expect(scores.composite, greaterThan(0.0));
      expect(scores.composite, lessThanOrEqualTo(100.0));

      // Update session content with encryption
      final content = testText.substring(0, testText.length - 1);
      await service.updateSessionContent(testSessionId, content);

      // Complete session
      await service.completeSession(testSessionId);

      // Create origin stamp with SHA-256 hash
      final contentHash = sha256.convert(utf8.encode(content)).toString();
      await service.createStamp(OriginStampData(
        id: service.runtimeType.toString().hashCode.toString(),
        sessionId: testSessionId,
        userId: userId,
        contentHash: contentHash,
        contentLength: content.length,
        timestamp: DateTime.now().toIso8601String(),
        authenticityScore: scores.composite,
        keystrokeEventCount: tracker.recentEvents.length,
        rhythmEntropy: scores.rhythmEntropy,
        revisionPatternScore: scores.revisionPatternScore,
      ));

      // Verify stamp persisted
      final stored = await service.getStampBySession(testSessionId);
      expect(stored, isNotNull);
      expect(stored!['content_hash'], contentHash);
      expect(stored['authenticity_score'], scores.composite);
      expect(stored['rhythm_entropy'], scores.rhythmEntropy);
      expect(stored['revision_pattern_score'], scores.revisionPatternScore);
      expect(stored['user_id'], userId);
      expect(stored['content_length'], content.length);

      // Verify stamps list
      expect(await service.getAllStamps(), isNotEmpty);

      // Verify session data
      var sessions = await service.getAllSessions();
      expect(sessions, isNotEmpty);
      final storedSession = await service.getSessionById(testSessionId);
      expect(storedSession, isNotNull);
      expect(storedSession!['user_id'], userId);
      expect(storedSession['content'], content);
      expect(storedSession['is_completed'], 1);

      // Insert keystroke events batch
      final events = <Map<String, dynamic>>[];
      for (var i = 0; i < tracker.recentEvents.length; i++) {
        events.add({
          'id': i.toString(),
          'session_id': testSessionId,
          'key_code': 0,
          'key_name': tracker.recentEvents[i].key,
          't_delta': timings[i],
          'timestamp': DateTime.now().toIso8601String(),
          'is_backspace': false,
          'prev_length': 0,
          'new_length': 0,
        });
      }
      await service.insertEventsBatch(events);
      final allEvents = await service.getEvents(testSessionId);
      expect(allEvents, isNotEmpty);

      // Build and verify fingerprint
      await service.buildFingerprint();
      final fp = await service.getFingerprint();
      expect(fp, isNotNull);
      expect(fp!['vocabulary_richness'], isNotNull);
      expect(fp['updated_at'], isNotEmpty);
      expect(fp['vocabulary_richness'], closeTo(vocabRichness, 0.001));

      // Verify SHA-256 determinism
      final recomputed = sha256.convert(utf8.encode(content)).toString();
      expect(recomputed, contentHash);
    });

    test('empty input produces zero scores', () async {
      await service.createSession(service.userId);

      final tracker = KeystrokeTracker();
      expect(tracker.getTdeltas(), isEmpty);

      expect(RhythmEntropyMetric.compute([]), equals(0.0));
      expect(VocabularyRichnessMetric.compute(''), equals(0.0));
      expect(TemporalConsistencyMetric.compute([]), equals(0.5));
    });

    test('stamp preserves all metric values', () async {
      final sid = await service.createSession(service.userId);
      final tracker = KeystrokeTracker();
      final base = DateTime.now().subtract(const Duration(seconds: 10));

      for (var i = 0; i < 10; i++) {
        tracker.onKey(
            String.fromCharCode('a'.codeUnitAt(0) + i),
            base.add(Duration(milliseconds: i * 100)));
      }

      final td = tracker.getTdeltas();
      expect(td.length, equals(9));

      final re = RhythmEntropyMetric.compute(td);
      final rp = RevisionPatternMetric.compute(
          eventCount: tracker.recentEvents.length, backspaceCount: 0);
      final vr = VocabularyRichnessMetric.compute('abcdefghij');
      final tc = TemporalConsistencyMetric.compute(td);

      expect(tc, greaterThan(0.9), reason: 'Uniform timing should yield high consistency');
      expect(vr, equals(1.0), reason: 'All unique chars should yield TTR of 1.0');
      expect(rp, closeTo(1.0, 0.01), reason: 'No backspaces = high revision score');

      final content = 'abcdefghij';
      await service.createStamp(OriginStampData(
        id: 'stamp-1',
        sessionId: sid,
        userId: service.userId,
        contentHash: sha256.convert(utf8.encode(content)).toString(),
        contentLength: content.length,
        timestamp: DateTime.now().toIso8601String(),
        authenticityScore: (0.35 * re + 0.25 * rp + 0.20 * vr + 0.20 * tc) * 100.0,
        keystrokeEventCount: tracker.recentEvents.length,
        rhythmEntropy: re,
        revisionPatternScore: rp,
      ));

      final s = await service.getStampBySession(sid);
      expect(s!['rhythm_entropy'], re);
      expect(s['revision_pattern_score'], rp);

      // Verify composite matches manual computation
      final manualComp = (0.35 * re + 0.25 * rp + 0.20 * vr + 0.20 * tc) * 100.0;
      expect(s['authenticity_score'], closeTo(manualComp, 0.1));

      await service.deleteSession(sid);
    });
  });
}
