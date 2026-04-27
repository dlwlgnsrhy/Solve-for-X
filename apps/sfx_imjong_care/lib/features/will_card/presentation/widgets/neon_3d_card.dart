import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:screenshot/screenshot.dart';
import 'package:sfx_imjong_care/core/constants/app_constants.dart';
import 'package:sfx_imjong_care/core/theme/neon_colors.dart';
import 'package:sfx_imjong_care/core/theme/card_template.dart';
import 'package:sfx_imjong_care/features/will_input/domain/entities/will_card.dart';

class Neon3DWillCard extends StatelessWidget {
  final WillCard card;
  final ScreenshotController? screenshotController;
  final CardTemplate template;

  const Neon3DWillCard({
    super.key,
    required this.card,
    this.screenshotController,
    this.template = CardTemplate.neon,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.004)
            ..rotateX(-0.08)
            ..rotateY(0.08),
          alignment: Alignment.center,
          child: screenshotController != null
              ? Screenshot(
                  controller: screenshotController!,
                  child: _WillCardContent(card: card, template: template),
                )
              : _WillCardContent(card: card, template: template),
        )
            .animate()
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1, 1),
              duration: 700.ms,
              curve: Curves.easeOutBack,
            )
            .then()
            .fadeIn(duration: 500.ms);
      },
    );
  }
}

class _WillCardContent extends StatelessWidget {
  final WillCard card;
  final CardTemplate template;

  const _WillCardContent({required this.card, required this.template});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 310,
      constraints: const BoxConstraints(maxHeight: 520),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: template.gradientColors,
        ),
        border: Border.all(
          color: template.borderColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: template.accentColor.withValues(alpha: 0.35),
            blurRadius: 30,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: template.shadowColors[1].withValues(alpha: 0.25),
            blurRadius: 40,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: template.shadowColors[0].withValues(alpha: 0.18),
            blurRadius: 50,
            spreadRadius: 0,
            offset: const Offset(-4, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBrandHeader(context),
                const Divider(height: 32, thickness: 0.5, color: Color(0x33FFFFFF)),
                _buildName(),
                const SizedBox(height: 28),
                _buildSectionLabel('MY VALUES / 내 가치'),
                const SizedBox(height: 16),
                _buildValues(),
                const SizedBox(height: 24),
                _buildDivider(),
                const SizedBox(height: 24),
                _buildSectionLabel('ONE-LINE WILL / 한 줄 유언'),
                const SizedBox(height: 16),
                _buildWill(),
                const SizedBox(height: 24),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: [template.accentColor, NeonColors.neonCyan],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          AppConstants.cardTitle,
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: template.accentColor,
            letterSpacing: 1.5,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slide(
      begin: const Offset(-0.3, 0),
      end: const Offset(0, 0),
    );
  }

  Widget _buildName() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          card.name,
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ).animate().fadeIn(duration: 500.ms).slide(
          begin: const Offset(0, 0.3),
          end: const Offset(0, 0),
        ),
        const SizedBox(height: 4),
        Text(
          '@${card.name.isNotEmpty ? card.name.toUpperCase().replaceAll(' ', '') : 'USER'}',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: NeonColors.neonCyan,
          ),
        ).animate().fadeIn(
          duration: 500.ms,
          delay: 150.ms,
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Orbitron',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color(0x99FFFFFF),
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildValueItem(
    String value,
    Color dotColor,
    int index,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: index < 2 ? 12 : 0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ).animate().fadeIn(
        duration: 400.ms,
        delay: (index * 200).ms,
      ),
    );
  }

  Widget _buildValues() {
    final dotColors = template.shadowColors.length >= 3
        ? [template.shadowColors[0], template.shadowColors[1], template.shadowColors[2]]
        : [template.accentColor, NeonColors.neonPink, NeonColors.neonCyan];
    return Column(
      children: List.generate(3, (index) {
        return _buildValueItem(
          card.values[index],
          dotColors[index % dotColors.length],
          index,
        );
      }),
    );
  }

  Widget _buildDivider() {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withAlpha(60),
            width: 0.5,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildWill() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: template.accentColor.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Text(
        card.will,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          height: 1.5,
          fontStyle: FontStyle.italic,
        ),
      ).animate().fadeIn(
        duration: 600.ms,
        delay: 200.ms,
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppConstants.cardTitle,
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Color(0x44FFFFFF),
            letterSpacing: 1.5,
          ),
        ),
        Text(
          'sfx.imjong.care',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            color: Color(0x44FFFFFF),
          ),
        ),
      ],
    );
  }
}
