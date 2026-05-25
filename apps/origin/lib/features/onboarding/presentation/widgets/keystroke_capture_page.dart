import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origin/core/services/preference_service.dart';
import 'package:origin/core/theme/app_theme.dart';
import 'package:origin/core/utils/keystroke_tracker.dart';

/// Onboarding keystroke capture: user writes a short passage, then taps "I'm done".
class KeystrokeCapturePage extends ConsumerStatefulWidget {
  const KeystrokeCapturePage({super.key});

  @override
  ConsumerState<KeystrokeCapturePage> createState() => _KeystrokeCapturePageState();
}

class _KeystrokeCapturePageState extends ConsumerState<KeystrokeCapturePage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late final _tracker = KeystrokeTracker();

  String _liveStats = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateStats);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateStats);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateStats() {
    final text = _controller.text;
    final chars = text.length;
    final keystrokes = _tracker.recentEvents.length;

    final tdeltas = _tracker.getTdeltas();
    final avgRTI = tdeltas.isNotEmpty
        ? (tdeltas.reduce((a, b) => a + b) / tdeltas.length).round()
        : 0;

    setState(() {
      _liveStats = '$chars chars · $keystrokes keystrokes · Avg RTI: $avgRTI ms';
    });
  }

  Future<void> _completeOnboarding() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please write something before continuing.'),
            backgroundColor: AppColor.cardBg,
          ),
        );
      }
      return;
    }

    // Mark as onboarded
    await globalPreferenceService.setOnboarded(true);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColor.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const SizedBox(height: 24),
              Text(
                'Write a sample',
                style: style.textTheme.headlineMedium!.copyWith(
                  color: AppColor.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Write a short passage — just a paragraph or two. Your rhythm matters.',
                style: style.textTheme.bodyMedium!.copyWith(
                  color: AppColor.textSecondary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              // Text Field
              Expanded(
                child: Container(
                  key: const ValueKey('keystrokeTextField'),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    autocorrect: true,
                    enableSuggestions: true,
                    decoration: InputDecoration(
                      hintText: 'The best thoughts are not premeditated but spontaneous...',
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
                        borderSide: const BorderSide(color: AppColor.neonGreen, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(20),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.7,
                      color: AppColor.textPrimary,
                    ),
                  ),
                ),
              ),

              // Live stats
              if (_liveStats.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.keyboard_rounded, size: 14, color: AppColor.textDim),
                      const SizedBox(width: 6),
                      Text(
                        _liveStats,
                        style: style.textTheme.bodySmall!.copyWith(
                          color: AppColor.textDim,
                        ),
                      ),
                    ],
                  ),
                ),

              // Button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    key: const ValueKey('completeOnboardingBtn'),
                    onPressed: _completeOnboarding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.neonGreen,
                      foregroundColor: AppColor.bgPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27),
                      ),
                    ),
                    child: Text(
                      'Complete & Continue',
                      style: style.textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
