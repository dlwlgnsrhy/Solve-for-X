import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:screenshot/screenshot.dart';
import 'package:sfx_imjong_care/core/constants/app_constants.dart';
import 'package:sfx_imjong_care/core/services/app_storage.dart';
import 'package:sfx_imjong_care/core/theme/neon_colors.dart';
import 'package:sfx_imjong_care/core/theme/card_template.dart';
import 'package:sfx_imjong_care/features/will_input/domain/entities/will_card.dart';
import 'package:sfx_imjong_care/features/will_card/presentation/widgets/neon_3d_card.dart';
import 'package:sfx_imjong_care/features/will_card/presentation/widgets/card_share_button.dart';

class WillCardRenderScreen extends StatefulWidget {
  final WillCard card;
  final CardTemplate template;

  const WillCardRenderScreen({
    super.key,
    required this.card,
    this.template = CardTemplate.neon,
  });

  @override
  State<WillCardRenderScreen> createState() => _WillCardRenderScreenState();
}

class _WillCardRenderScreenState extends State<WillCardRenderScreen> {
  late CardTemplate _currentTemplate;
  final ScreenshotController _screenshotController = ScreenshotController();
  final InAppReview _inAppReview = InAppReview.instance;

  @override
  void initState() {
    super.initState();
    _currentTemplate = widget.template;
    _incrementGenerationCountAndCheckReview();
  }

  Future<void> _incrementGenerationCountAndCheckReview() async {
    final count = await AppStorage.incrementCardGenerationCount();
    final alreadyPrompted = await AppStorage.isReviewPrompted();

    // Prompt for review after 3rd card generation, only once
    if (count >= 3 && !alreadyPrompted) {
      await AppStorage.setReviewPrompted();
      // Delay slightly so user can enjoy their card first
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;

      final available = await _inAppReview.isAvailable();
      if (available) {
        await _inAppReview.requestReview();
      }
    }
  }

  void _switchTemplate(CardTemplate template) {
    setState(() {
      _currentTemplate = template;
    });
  }

  void _goHome() {
    // Pop all the way back to root (home/input screen)
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _regenerateCard() {
    // Go back to the input screen to create a new card
    Navigator.of(context).popUntil((route) => route.isFirst);
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
              // Header with template switcher
              _buildHeader(context),
              const SizedBox(height: 12),

              // 3D Card
              Expanded(
                child: Center(
                  child: Neon3DWillCard(
                    card: widget.card,
                    screenshotController: _screenshotController,
                    template: _currentTemplate,
                  ),
                ),
              ),

              // Bottom Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  children: [
                    // Share & Save row
                    CardShareButton(
                      card: widget.card,
                      screenshotController: _screenshotController,
                      template: _currentTemplate,
                    ),
                    const SizedBox(height: 10),

                    // Action buttons row: 재작성 | 홈으로 | 수정하기
                    Row(
                      children: [
                        // 재작성 (Regenerate) button
                        Expanded(
                          child: _ActionButton(
                            label: '재작성',
                            icon: Icons.refresh_outlined,
                            color: _currentTemplate.accentColor,
                            borderColor: _currentTemplate.accentColor.withValues(alpha: 120),
                            onTap: _regenerateCard,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // 홈으로 (Go Home) button
                        Expanded(
                          child: _ActionButton(
                            label: '홈으로',
                            icon: Icons.home_outlined,
                            color: NeonColors.neonCyan,
                            borderColor: NeonColors.neonCyan.withValues(alpha: 120),
                            onTap: _goHome,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // 수정하기 (Edit) button
                        Expanded(
                          child: _ActionButton(
                            label: '수정하기',
                            icon: Icons.edit_outlined,
                            color: NeonColors.neonPink,
                            borderColor: NeonColors.neonPink.withValues(alpha: 120),
                            onTap: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _currentTemplate.accentColor.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  AppConstants.cardTitle,
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _currentTemplate.accentColor,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Template switcher row
          _buildTemplateSwitcher(),
        ],
      ),
    );
  }

  /// Template switcher pill row at the top of the card screen
  Widget _buildTemplateSwitcher() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: CardTemplate.values.map((template) {
        final isSelected = _currentTemplate == template;
        return GestureDetector(
          onTap: () => _switchTemplate(template),
          child: _buildTemplatePill(template, isSelected),
        );
      }).toList(),
    );
  }

  Widget _buildTemplatePill(CardTemplate template, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: EdgeInsets.symmetric(
        horizontal: isSelected ? 14 : 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isSelected
            ? template.accentColor.withValues(alpha: 0.15)
            : Colors.transparent,
        border: Border.all(
          color: isSelected
              ? template.accentColor
              : Colors.white.withValues(alpha: 0.1),
          width: isSelected ? 1.5 : 0.5,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: template.accentColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            template.icon,
            size: 14,
            color: isSelected ? template.accentColor : const Color(0xFF888888),
          ),
          const SizedBox(width: 4),
          Text(
            template.name.split('/')[0].trim(),
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: isSelected ? template.accentColor : const Color(0xFF888888),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic action button for card screen bottom row
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color borderColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: borderColor, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
