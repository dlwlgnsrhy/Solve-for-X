import 'package:flutter/material.dart';
import 'package:sfx_imjong_care/core/constants/app_constants.dart';
import 'package:sfx_imjong_care/core/theme/neon_colors.dart';
import 'package:sfx_imjong_care/core/theme/card_template.dart';
import 'package:sfx_imjong_care/features/will_input/domain/entities/will_card.dart';

/// Full share-optimized card image with background, branding, and QR-like footer.
/// Used inside [Screenshot] widget to produce high-quality share images.
/// Instagram-ready with branded header, template badge, watermark footer,
/// and subtle border glow matching template color.
class ShareCardContent extends StatelessWidget {
  final WillCard card;
  final CardTemplate template;

  const ShareCardContent({
    super.key,
    required this.card,
    this.template = CardTemplate.neon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 420,
      height: 780,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A0A14),
            Color(0xFF0D0D1A),
            Color(0xFF080812),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: template.accentColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          // Outer glow matching template color
          BoxShadow(
            color: template.accentColor.withValues(alpha: 0.2),
            blurRadius: 50,
            spreadRadius: -5,
          ),
          // Secondary glow
          BoxShadow(
            color: template.accentColor.withValues(alpha: 0.1),
            blurRadius: 80,
            spreadRadius: -15,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand header with neon glow
            _buildBrandHeader(),
            const SizedBox(height: 12),
            // Template name badge
            _buildTemplateBadge(),
            const SizedBox(height: 14),
            // Card content
            Expanded(
              child: _buildCardBody(),
            ),
            // Footer with watermark
            const SizedBox(height: 16),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  /// Branded header: "SFX 임종 케어" with neon glow effect
  Widget _buildBrandHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: template.accentColor.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // Glow bar
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  template.accentColor,
                  NeonColors.neonCyan,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: template.accentColor.withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Branded text with glow
          Text(
            AppConstants.appName,
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: template.accentColor,
              letterSpacing: 1.5,
              shadows: [
                Shadow(
                  color: template.accentColor.withValues(alpha: 0.6),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Template name badge (e.g., "NEON 템플릿")
  Widget _buildTemplateBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: template.accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: template.accentColor.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        '${template.name.split('/')[0].trim()} 템플릿',
        style: TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: template.accentColor.withValues(alpha: 0.8),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildCardBody() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: template.gradientColors,
        ),
        border: Border.all(
          color: template.accentColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: template.accentColor.withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: template.shadowColors[1].withValues(alpha: 0.18),
            blurRadius: 30,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name section
              _buildName(),
              const SizedBox(height: 18),
              // Divider
              _buildSectionDivider(),
              const SizedBox(height: 18),
              // Values section
              _buildSectionLabel('MY VALUES / 내 가치'),
              const SizedBox(height: 12),
              _buildValues(),
              const SizedBox(height: 18),
              _buildSectionDivider(),
              const SizedBox(height: 18),
              // Will section
              _buildSectionLabel('ONE-LINE WILL / 한 줄 유언'),
              const SizedBox(height: 12),
              _buildWill(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionDivider() {
    return Container(
      height: 0.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            template.accentColor.withValues(alpha: 0.2),
            Colors.transparent,
          ],
        ),
      ),
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
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          '@${card.name.isNotEmpty ? card.name.toUpperCase().replaceAll(' ', '') : 'USER'}',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: template.accentColor.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Orbitron',
        fontSize: 9,
        fontWeight: FontWeight.w600,
        color: Color(0x99FFFFFF),
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildValueItem(String value, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValues() {
    final dotColors = [
      NeonColors.neonGreen,
      NeonColors.neonPink,
      NeonColors.neonCyan,
    ];
    return Column(
      children: List.generate(3, (index) {
        return _buildValueItem(card.values[index], dotColors[index]);
      }),
    );
  }

  Widget _buildWill() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: template.accentColor.withValues(alpha: 0.35),
          width: 1,
        ),
        color: template.accentColor.withValues(alpha: 0.05),
      ),
      child: Text(
        card.will,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          height: 1.4,
          fontStyle: FontStyle.italic,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Watermark footer with URL and App Store text
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppConstants.appName,
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: template.accentColor.withValues(alpha: 0.4),
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'sfx.imjong.care',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 8,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Get it on the App Store',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 7,
              color: Colors.white.withValues(alpha: 0.25),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
