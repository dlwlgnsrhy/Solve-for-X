import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:crypto/crypto.dart';
import 'package:origin/core/services/database_service.dart';
import 'package:origin/core/services/preference_service.dart';
import 'package:origin/core/theme/app_theme.dart';
import 'package:origin/core/utils/keystroke_tracker.dart';
import 'package:origin/features/authentic_analyzer/data/metrics/rhythm_entropy_metric.dart';
import 'package:origin/features/authentic_analyzer/data/metrics/revision_pattern_metric.dart';
import 'package:origin/features/authentic_analyzer/data/metrics/vocabulary_richness_metric.dart';
import 'package:origin/features/authentic_analyzer/data/metrics/temporal_consistency_metric.dart';

import 'authenticity_score_page.dart';

/// Page for composing text while tracking keystroke dynamics.
class KeystrokeWritePage extends StatefulWidget {
  const KeystrokeWritePage({super.key});

  @override
  State<KeystrokeWritePage> createState() => _KeystrokeWritePageState();
}

class _KeystrokeWritePageState extends State<KeystrokeWritePage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late final _tracker = KeystrokeTracker();

  String _summary = '';
  bool _saving = false;
  String _prevText = '';
  int _backspaceCount = 0;
  final List<int> _eventDeleteFlags = [];
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _initSession();
  }

  Future<void> _initSession() async {
    final userId = globalPreferenceService.userId;
    if (userId.isEmpty) {
      debugPrint('[KeystrokeWritePage] userId empty, cannot create session');
      return;
    }
    final id = await globalDatabaseService.createSession(userId: userId);
    if (mounted) {
      setState(() => _sessionId = id);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _tracker.clear();
    _eventDeleteFlags.clear();
    super.dispose();
  }

  void _onTextChanged() {
    final currentText = _controller.text;

    // Track backspace and insert operations per-character
    final prevLen = _prevText.length;
    final curLen = currentText.length;
    if (curLen < prevLen) {
      final deleted = prevLen - curLen;
      _backspaceCount += deleted;
      for (var i = 0; i < deleted; i++) {
        _eventDeleteFlags.add(1);
      }
    } else if (curLen > prevLen) {
      final added = curLen - prevLen;
      for (var i = 0; i < added; i++) {
        _eventDeleteFlags.add(0);
      }
    } else {
      // Same length — compute actual insert/delete counts via prefix/suffix split
      var prefixEnd = 0;
      while (prefixEnd < prevLen &&
          _prevText[prefixEnd] == currentText[prefixEnd]) {
        prefixEnd++;
      }
      final oldRemainLen = prevLen - prefixEnd;
      final newRemainLen = curLen - prefixEnd;
      final commonSuffix = oldRemainLen < newRemainLen ? oldRemainLen : newRemainLen;
      final delLen = oldRemainLen - commonSuffix;
      final insLen = newRemainLen - commonSuffix;
      for (var i = 0; i < delLen; i++) {
        _eventDeleteFlags.add(1);
      }
      for (var i = 0; i < insLen; i++) {
        _eventDeleteFlags.add(0);
      }
    }

    _tracker.onTextChange(oldText: _prevText, newText: currentText);
    _prevText = currentText;
    _updateSummary();
  }

  void _updateSummary() {
    final text = _controller.text;
    final chars = text.length;
    final keystrokes = _tracker.recentEvents.length;
    final tdeltas = _tracker.getTdeltas();
    final avgRTI = tdeltas.isNotEmpty
        ? (tdeltas.reduce((a, b) => a + b) / tdeltas.length).round()
        : 0;

    setState(() {
      _summary = '$chars chars · $keystrokes keys · $_backspaceCount del · Avg RTI: $avgRTI ms';
    });
  }

  String _generateUUID() {
    final List<int> bytes = List<int>.generate(16, (_) => 0);
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-4${hex.substring(13)}-a${hex.substring(17)}-${hex.substring(20)}';
  }

  /// Compute score metrics. Called BEFORE tracker.clear().
  Map<String, dynamic> _computeScores({int? backspaceCount}) {
    final effectiveBackspace = backspaceCount ?? _backspaceCount;
    final tdeltas = _tracker.getTdeltas();
    if (tdeltas.isEmpty) {
      return {
        'composite': 0.0,
        'rhythmEntropy': 0.0,
        'revisionPatternScore': 1.0,
        'vocabularyRichness': 0.0,
        'temporalConsistency': 0.5,
        'tdeltas': <double>[],
        'avgResponseTime': '--',
        'backspaceRatio': '0.0%',
        'typeTokenRatio': '--',
      };
    }

    // Rhythm Entropy
    final rhythmEntropy = RhythmEntropyMetric.compute(tdeltas);

    // Revision Pattern
    final totalEvents = tdeltas.length + effectiveBackspace;
    final backspaceRatio = totalEvents > 0
        ? effectiveBackspace / totalEvents
        : 0.0;
    final revisionScore = RevisionPatternMetric.compute(
      eventCount: _tracker.recentEvents.length,
      backspaceCount: effectiveBackspace,
    );

    // Vocabulary Richness (Type-Token Ratio)
    final vocabRichness = VocabularyRichnessMetric.compute(_controller.text);

    // Temporal Consistency
    final temporalConsistency = TemporalConsistencyMetric.compute(tdeltas);

    // Mean for return map display
    final mean = tdeltas.reduce((a, b) => a + b) / tdeltas.length;

    // Composite score
    final composite = (0.35 * rhythmEntropy +
            0.25 * revisionScore +
            0.20 * vocabRichness +
            0.20 * temporalConsistency) *
        100.0;

    return {
      'composite': composite,
      'rhythmEntropy': rhythmEntropy,
      'revisionPatternScore': revisionScore,
      'vocabularyRichness': vocabRichness,
      'temporalConsistency': temporalConsistency,
      'tdeltas': tdeltas,
      'avgResponseTime': '${mean.round()}ms',
      'backspaceRatio': '${(backspaceRatio * 100).toStringAsFixed(1)}%',
      'typeTokenRatio': vocabRichness.toStringAsFixed(2),
    };
  }

  /// Complete: save session, compute score, create stamp, navigate.
  Future<void> _completeDocument() async {
    if (_sessionId == null) return;

    final content = _controller.text;
    if (content.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('문서를 작성해주세요.'),
            backgroundColor: AppColor.cardBg,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _saving = true);

    // Capture backspace count before tracking state changes
    final savedBackspaceCount = _backspaceCount;
    _backspaceCount = 0;

    try {
      // 1. Save content to database
      await globalDatabaseService.updateSessionContent(
        sessionId: _sessionId!,
        content: content,
      );

      // 2. Compute scores BEFORE clearing the tracker
      final scores = _computeScores(backspaceCount: savedBackspaceCount);
      final tdeltas = scores['tdeltas'] as List<double>;
      final eventIdCount = _tracker.recentEvents.length;

      // 3. Build event records from tracker data
      final events = <Map<String, dynamic>>[];
      final lastDelta = tdeltas.isNotEmpty ? tdeltas.last : 0;
      for (var i = 0; i < _tracker.recentEvents.length; i++) {
        final event = _tracker.recentEvents[i];
        events.add({
          'id': _generateUUID(),
          'session_id': _sessionId,
          'key_code': 0,
          'key_name': event.key,
          't_delta': lastDelta,
          'timestamp': event.timestamp.toString(),
          'is_backspace': i < _eventDeleteFlags.length && _eventDeleteFlags[i] == 1,
          'prev_length': 0,
          'new_length': 0,
        });
      }

      // 4. Mark session complete
      await globalDatabaseService.completeSession(_sessionId!);

      // 5. Batch insert events (this clears the tracker)
      if (events.isNotEmpty) {
        await globalDatabaseService.insertKeystrokeEventsBatch(events);
        _tracker.clear();
        _eventDeleteFlags.clear();
      }

      // 6. Create stamp
      final contentHash = sha256.convert(utf8.encode(content)).toString();
      final userId = globalPreferenceService.userId;

      await globalDatabaseService.createOriginStamp(
        id: _generateUUID(),
        sessionId: _sessionId!,
        userId: userId,
        contentHash: contentHash,
        contentLength: content.length,
        timestamp: DateTime.now().toIso8601String(),
        authenticityScore: scores['composite'],
        keystrokeEventCount: eventIdCount,
        rhythmEntropy: scores['rhythmEntropy'],
        revisionPatternScore: scores['revisionPatternScore'],
      );

      // 7. Navigate to score page (will query DB for live data)
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const AuthenticityScorePage(),
          ),
        );
      }
    } catch (e) {
      debugPrint('[KeystrokeWritePage] Error: $e');
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: AppColor.cardBg,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
      // Always reset tracking state to prevent staleness on error
      if (_eventDeleteFlags.isNotEmpty) _eventDeleteFlags.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, size: 22, color: AppColor.neonGreen),
                    const SizedBox(width: 10),
                    Text(
                      'Write',
                      style: style.textTheme.headlineMedium!.copyWith(
                        color: AppColor.textPrimary,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms),
              ),

              // Text area
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: 'Start writing...\nYour keystrokes tell a story.',
                    hintStyle: style.textTheme.bodyLarge!.copyWith(
                      color: AppColor.textDim,
                    ),
                    filled: true,
                    fillColor: AppColor.bgSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColor.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColor.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColor.neonGreen,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.7,
                    color: AppColor.textPrimary,
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
              ),

              // Summary bar (live keystroke stats)
              if (_summary.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColor.bgTertiary,
                    borderRadius: BorderRadius.circular(10),
                    border: const Border.fromBorderSide(BorderSide(color: AppColor.divider)),
                  ),
                  child: Text(
                    _summary,
                    style: style.textTheme.bodySmall!.copyWith(
                      color: AppColor.textSecondary,
                    ),
                  ).animate().fadeIn(duration: 300.ms),
                ).animate().slide(begin: const Offset(0, 0.2)).fadeIn(),

              const SizedBox(height: 16),

              // Complete button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _completeDocument,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _saving
                        ? AppColor.neonGreen.withValues(alpha: 0.4)
                        : AppColor.neonGreen,
                    foregroundColor: _saving
                        ? AppColor.textDim
                        : AppColor.bgPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColor.bgPrimary,
                          ),
                        )
                      : Text(
                          'Complete Document',
                          style: style.textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _saving
                                ? AppColor.bgTertiary
                                : AppColor.bgPrimary,
                          ),
                        ),
                ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
