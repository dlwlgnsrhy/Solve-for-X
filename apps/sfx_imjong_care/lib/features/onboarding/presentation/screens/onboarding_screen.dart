import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sfx_imjong_care/core/services/app_storage.dart';
import 'package:sfx_imjong_care/core/theme/neon_colors.dart';
import 'package:sfx_imjong_care/core/theme/card_template.dart';
import 'package:sfx_imjong_care/features/will_input/presentation/screens/will_input_screen.dart';

/// Onboarding welcome screen shown on first launch.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-advance after a delay for users who just want to skip
    // They can also tap "시작하기" to go immediately
  }

  void _startApp() async {
    await AppStorage.setOnboardingCompleted();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WillInputScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 0,
          maxWidth: double.infinity,
          minHeight: 0,
          maxHeight: double.infinity,
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Title
              Text(
                'SFX 임종 케어',
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: NeonColors.neonGreen,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      color: Color(0x6600FF88),
                      blurRadius: 16,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(
                    begin: -0.3,
                    end: 0,
                    duration: 600.ms,
                    curve: Curves.easeOut,
                  ),

              const SizedBox(height: 12),

              Text(
                '당신의 인생을 한 장의 카드로 남기세요',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 1.5,
                ),
              ).animate()
                  .fadeIn(delay: 200.ms, duration: 600.ms)
                  .slideY(begin: -0.3, end: 0, duration: 600.ms, curve: Curves.easeOut),

              const SizedBox(height: 8),

              Text(
                '내 가치와 유산을 담은 트렌디한 디지털 카드를 만들어보세요',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFF999999),
                  height: 1.5,
                ),
              ).animate()
                  .fadeIn(delay: 350.ms, duration: 600.ms)
                  .slideY(begin: -0.3, end: 0, duration: 600.ms, curve: Curves.easeOut),

              const Spacer(flex: 1),

              // Sample card previews
              _buildSampleCards(),

              const Spacer(flex: 2),

              // Start button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _startApp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NeonColors.neonGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 8,
                      shadowColor: NeonColors.neonGreen.withValues(alpha: 0.5),
                    ),
                    child: const Text(
                      '시작하기',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ).animate()
                  .fadeIn(delay: 500.ms, duration: 500.ms)
                  .slideY(begin: 0.3, end: 0, duration: 500.ms, curve: Curves.easeOut),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSampleCards() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: CardTemplate.values.length,
        itemBuilder: (context, index) {
          final template = CardTemplate.values[index];
          return _SampleCard(template: template)
              .animate()
              .fadeIn(delay: (400 + index * 100).ms, duration: 500.ms)
              .slideX(
                begin: index.isEven ? -0.5 : 0.5,
                end: 0,
                duration: 500.ms,
                curve: Curves.easeOut,
              );
        },
      ),
    );
  }
}

/// Mini sample card preview widget.
class _SampleCard extends StatefulWidget {
  final CardTemplate template;

  const _SampleCard({required this.template});

  @override
  State<_SampleCard> createState() => _SampleCardState();
}

class _SampleCardState extends State<_SampleCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _tiltAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _tiltAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(_tiltAnimation.value)
        ..rotateX(0.02),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.template.gradientColors,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.template.accentColor.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.template.accentColor.withValues(alpha: 0.25),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SFX 임종 케어',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: widget.template.accentColor,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '홍길동',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: widget.template.accentColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 1,
              color: widget.template.accentColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 6),
            _buildMiniValue('자유'),
            _buildMiniValue('사랑'),
            _buildMiniValue('성장'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(
                  color: widget.template.accentColor.withValues(alpha: 0.4),
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '진심으로 산다.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 7,
                  color: Colors.white.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniValue(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: widget.template.accentColor,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 9,
              color: Color(0xFFCCCCCC),
            ),
          ),
        ],
      ),
    );
  }
}
