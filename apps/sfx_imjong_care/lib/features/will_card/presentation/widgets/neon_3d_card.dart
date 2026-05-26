import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:screenshot/screenshot.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sfx_imjong_care/core/constants/app_constants.dart';
import 'package:sfx_imjong_care/core/theme/neon_colors.dart';
import 'package:sfx_imjong_care/core/theme/card_template.dart';
import 'package:sfx_imjong_care/features/will_input/domain/entities/will_card.dart';

class Neon3DWillCard extends StatefulWidget {
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
  State<Neon3DWillCard> createState() => _Neon3DWillCardState();
}

class _Neon3DWillCardState extends State<Neon3DWillCard>
    with SingleTickerProviderStateMixin {
  // Drag rotation states (Pitch and Yaw)
  double _dragX = 0.0; // rotation around X-axis (up/down)
  double _dragY = 0.0; // rotation around Y-axis (left/right)

  // Flip animation controller (Y-axis 180deg flip)
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: math.pi).animate(
      CurvedAnimation(
        parent: _flipController,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxW = constraints.maxWidth;
        final double maxH = constraints.maxHeight;
        final bool needsScaling = maxW < 310 || maxH < 480;

        Widget cardBody = GestureDetector(
          onTap: _toggleFlip,
          onPanUpdate: (details) {
            setState(() {
              // Convert drag offsets to slight rotations.
              // We restrict X and Y rotations to keep 3D effects natural and prevent clipping.
              _dragY += details.delta.dx * 0.005;
              _dragX -= details.delta.dy * 0.005;

              // Keep drag angles within reasonable bounds (-0.4 to 0.4 rad)
              _dragX = _dragX.clamp(-0.4, 0.4);
              _dragY = _dragY.clamp(-0.4, 0.4);
            });
          },
          onPanEnd: (_) => _resetDragRotation(),
          onPanCancel: _resetDragRotation,
          child: AnimatedBuilder(
            animation: _flipAnimation,
            builder: (context, child) {
              // Combine flip animation (left/right) and real-time drag rotations.
              final double flipAngle = _flipAnimation.value;
              final double finalRotationY = _dragY + flipAngle;
              final double finalRotationX = _dragX;

              // Perspective matrix
              final Matrix4 matrix = Matrix4.identity()
                ..setEntry(3, 2, 0.0012) // Subtle perspective (prevents clipping)
                ..rotateX(finalRotationX)
                ..rotateY(finalRotationY);

              // Determine which side is showing based on final angle
              final bool isBackShowing = (finalRotationY.abs() % (math.pi * 2)) > (math.pi / 2) &&
                  (finalRotationY.abs() % (math.pi * 2)) < (math.pi * 1.5);

              Widget currentSide;
              if (isBackShowing) {
                // If the back is showing, we flip it horizontally so it reads normally
                currentSide = Transform(
                  transform: Matrix4.identity()..rotateY(math.pi),
                  alignment: Alignment.center,
                  child: _WillCardBackContent(
                    card: widget.card,
                    template: widget.template,
                  ),
                );
              } else {
                currentSide = _WillCardFrontContent(
                  card: widget.card,
                  template: widget.template,
                );
              }

              return Transform(
                transform: matrix,
                alignment: Alignment.center,
                child: widget.screenshotController != null
                    ? Screenshot(
                         controller: widget.screenshotController!,
                         child: currentSide,
                       )
                    : currentSide,
              );
            },
          ),
        )
            .animate()
            .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1.0, 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
            )
            .fadeIn(duration: const Duration(milliseconds: 400));

        if (needsScaling) {
          return SizedBox(
            width: maxW,
            height: maxH,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 310,
                height: 480,
                child: cardBody,
              ),
            ),
          );
        }

        return cardBody;
      },
    );
  }

  void _resetDragRotation() {
    // Smoothly transition drag rotation back to zero using setState over time.
    // To avoid complex ticker implementations, we can do a simple frame-by-frame dampening.
    Future.microtask(() async {
      while ((_dragX.abs() > 0.01 || _dragY.abs() > 0.01) && mounted) {
        await Future.delayed(const Duration(milliseconds: 16));
        if (!mounted) return;
        setState(() {
          _dragX *= 0.75;
          _dragY *= 0.75;
        });
      }
      if (mounted) {
        setState(() {
          _dragX = 0.0;
          _dragY = 0.0;
        });
      }
    });
  }
}

class _WillCardFrontContent extends StatelessWidget {
  final WillCard card;
  final CardTemplate template;

  const _WillCardFrontContent({required this.card, required this.template});

  bool get isCream => template == CardTemplate.creamPostcard;
  Color get primaryTextColor => isCream ? const Color(0xFF594F45) : Colors.white;
  Color get secondaryTextColor => isCream ? const Color(0xBB594F45) : const Color(0x99FFFFFF);
  Color get footerTextColor => isCream ? const Color(0x88594F45) : const Color(0x44FFFFFF);
  Color get dividerColor => isCream ? const Color(0x33594F45) : const Color(0x33FFFFFF);

  TextStyle getKoreanStyle({required double fontSize, required FontWeight fontWeight, double? height, FontStyle? fontStyle}) {
    if (isCream) {
      return GoogleFonts.notoSerifKr(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: primaryTextColor,
        height: height,
        fontStyle: fontStyle,
      );
    }
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: primaryTextColor,
      height: height,
      fontStyle: fontStyle,
    );
  }

  TextStyle getEnglishStyle({required double fontSize, required FontWeight fontWeight, double? letterSpacing, Color? customColor}) {
    if (isCream) {
      return GoogleFonts.cormorantGaramond(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: customColor ?? template.accentColor,
        letterSpacing: letterSpacing,
      );
    }
    return TextStyle(
      fontFamily: 'Orbitron',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: customColor ?? template.accentColor,
      letterSpacing: letterSpacing,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isCream) {
      // 100% 사용자가 아침에 직접 디자인한 극강의 미니멀 엽서 아날로그 뷰
      return Container(
        width: 310,
        height: 480,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F5F0), // Cream HSL(38, 40%, 96%)
          border: Border.all(
            color: const Color(0x4D594F45), // hsla(24, 25%, 35%, 0.3)
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(4.0), // 엽서 스타일의 4px sharp corner
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 안쪽 10px 마진의 은은한 가이드 선 (will-card::before 완벽 재현)
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              bottom: 10,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0x1A594F45), // hsla(24, 25%, 35%, 0.1)
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
            ),
            // 본문 텍스트 중앙 배치
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      card.will, // 사용자가 작성한 유언 한 줄이 메인
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSerifKr(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF594F45),
                        height: 2.0, // line-height: 2
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      '— ${card.name.isNotEmpty ? card.name : 'Imjong Care'}',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF8C7E70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 310,
      height: 480,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: template.gradientColors,
        ),
        border: Border.all(
          color: template.borderColor.withValues(alpha: 0.6),
          width: 1.8,
        ),
        boxShadow: isCream
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: template.accentColor.withValues(alpha: 0.04),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: template.accentColor.withValues(alpha: 0.4),
                  blurRadius: 28,
                  spreadRadius: 3,
                ),
                BoxShadow(
                  color: template.shadowColors[1].withValues(alpha: 0.25),
                  blurRadius: 35,
                  spreadRadius: 1,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBrandHeader(),
              Divider(height: 32, thickness: 0.5, color: dividerColor),
              _buildName(),
              const SizedBox(height: 24),
              _buildSectionLabel('MY VALUES / 내 가치'),
              const SizedBox(height: 12),
              Expanded(child: _buildValues()),
              const SizedBox(height: 16),
              _buildDivider(),
              const SizedBox(height: 16),
              _buildSectionLabel('ONE-LINE WILL / 한 줄 유언'),
              const SizedBox(height: 12),
              _buildWill(),
              const SizedBox(height: 20),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Row(
      children: [
        Container(
          width: 8,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: isCream
                  ? [template.accentColor, const Color(0xFF8C7E70)]
                  : [template.accentColor, NeonColors.neonCyan],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          AppConstants.cardTitle,
          style: getEnglishStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    ).animate().fadeIn(duration: const Duration(milliseconds: 400)).slide(
      begin: const Offset(-0.2, 0),
      end: const Offset(0, 0),
    );
  }

  Widget _buildName() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          card.name,
          style: getKoreanStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(duration: const Duration(milliseconds: 500)).slide(
          begin: const Offset(0, 0.2),
          end: const Offset(0, 0),
        ),
        const SizedBox(height: 4),
        Text(
          '@${card.name.isNotEmpty ? card.name.toUpperCase().replaceAll(' ', '') : 'USER'}',
          style: isCream
              ? GoogleFonts.cormorantGaramond(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: template.accentColor.withValues(alpha: 0.8),
                )
              : const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: NeonColors.neonCyan,
                ),
        ).animate().fadeIn(
          duration: const Duration(milliseconds: 500),
          delay: const Duration(milliseconds: 150),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: isCream
          ? GoogleFonts.cormorantGaramond(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: secondaryTextColor,
              letterSpacing: 2,
            )
          : const TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0x99FFFFFF),
              letterSpacing: 2,
            ),
    );
  }

  Widget _buildValueItem(String value, Color dotColor, int index) {
    return Padding(
      padding: EdgeInsets.only(bottom: index < 2 ? 10 : 0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
              boxShadow: isCream
                  ? null
                  : [
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
              style: getKoreanStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ).animate().fadeIn(
        duration: const Duration(milliseconds: 400),
        delay: (index * 150).ms,
      ),
    );
  }

  Widget _buildValues() {
    final dotColors = template.shadowColors.length >= 3
        ? [template.shadowColors[0], template.shadowColors[1], template.shadowColors[2]]
        : [template.accentColor, NeonColors.neonPink, NeonColors.neonCyan];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final val = (card.values.length > index) ? card.values[index] : '';
        return _buildValueItem(
          val,
          dotColors[index % dotColors.length],
          index,
        );
      }),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 0.5,
      color: dividerColor,
    );
  }

  Widget _buildWill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: template.accentColor.withValues(alpha: isCream ? 0.2 : 0.35),
          width: 1,
        ),
        color: isCream ? const Color(0x05594F45) : null,
      ),
      child: Text(
        card.will,
        style: getKoreanStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.4,
          fontStyle: FontStyle.italic,
        ),
      ).animate().fadeIn(
        duration: const Duration(milliseconds: 600),
        delay: const Duration(milliseconds: 200),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppConstants.cardTitle,
          style: isCream
              ? GoogleFonts.cormorantGaramond(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: footerTextColor,
                  letterSpacing: 1.0,
                )
              : const TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Color(0x44FFFFFF),
                  letterSpacing: 1.5,
                ),
        ),
        Text(
          'sfx.imjong.care',
          style: isCream
              ? GoogleFonts.cormorantGaramond(
                  fontSize: 10,
                  color: footerTextColor,
                  fontWeight: FontWeight.w500,
                )
              : const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  color: Color(0x44FFFFFF),
                ),
        ),
      ],
    );
  }
}

class _WillCardBackContent extends StatelessWidget {
  final WillCard card;
  final CardTemplate template;

  const _WillCardBackContent({required this.card, required this.template});

  bool get isCream => template == CardTemplate.creamPostcard;
  Color get primaryTextColor => isCream ? const Color(0xFF594F45) : Colors.white;
  Color get secondaryTextColor => isCream ? const Color(0xBB594F45) : const Color(0x99FFFFFF);
  Color get footerTextColor => isCream ? const Color(0x88594F45) : const Color(0x44FFFFFF);
  Color get dividerColor => isCream ? const Color(0x22594F45) : const Color(0x11FFFFFF);

  TextStyle getKoreanStyle({required double fontSize, required FontWeight fontWeight, double? height, FontStyle? fontStyle}) {
    if (isCream) {
      return GoogleFonts.notoSerifKr(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: primaryTextColor,
        height: height,
        fontStyle: fontStyle,
      );
    }
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: primaryTextColor,
      height: height,
      fontStyle: fontStyle,
    );
  }

  TextStyle getEnglishStyle({required double fontSize, required FontWeight fontWeight, double? letterSpacing, Color? customColor}) {
    if (isCream) {
      return GoogleFonts.cormorantGaramond(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: customColor ?? template.accentColor,
        letterSpacing: letterSpacing,
      );
    }
    return TextStyle(
      fontFamily: 'Orbitron',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: customColor ?? template.accentColor,
      letterSpacing: letterSpacing,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isCream) {
      // 엽서의 클래식한 뒷면 (우표 소인 및 가벼운 아날로그 선)
      return Container(
        width: 310,
        height: 480,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F5F0),
          border: Border.all(
            color: const Color(0x4D594F45),
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(4.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 안쪽 10px 마진 선
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              bottom: 10,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0x1A594F45),
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
            ),
            // 우측 상단 우표(Stamp) 모양 장식 (엽서 감성 극대화)
            Positioned(
              top: 24,
              right: 24,
              child: Container(
                width: 42,
                height: 52,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0x4D594F45),
                    width: 0.8,
                    style: BorderStyle.solid,
                  ),
                  color: const Color(0x0A594F45),
                ),
                child: const Center(
                  child: Icon(
                    Icons.favorite_outline_rounded,
                    size: 16,
                    color: Color(0xFF8C7E70),
                  ),
                ),
              ),
            ),
            // 중앙에 따뜻한 감성 작별 메시지
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.mail_outline_rounded,
                      size: 28,
                      color: Color(0xFF8C7E70),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '우리가 나눈 소중한 시간과 기억들은\n영원히 마음속에서 따뜻하게 빛날 것입니다.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSerifKr(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF594F45),
                        height: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 하단 엽서 소유자 서명 라인
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Column(
                children: [
                  Container(
                    height: 0.5,
                    color: const Color(0x33594F45),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'POSTCARD',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8C7E70),
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        card.name.isNotEmpty ? 'BY. ${card.name.toUpperCase()}' : 'BY. IMJONG CARE',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF594F45),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 310,
      height: 480,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
          colors: template.gradientColors.reversed.toList(),
        ),
        border: Border.all(
          color: template.borderColor.withValues(alpha: 0.6),
          width: 1.8,
        ),
        boxShadow: isCream
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: template.accentColor.withValues(alpha: 0.35),
                  blurRadius: 28,
                  spreadRadius: 3,
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            children: [
              // Top Brand
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(template.icon, color: template.accentColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'MEMORY CARD',
                    style: getEnglishStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Hologram & Sensor Graphic
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: template.accentColor.withValues(alpha: isCream ? 0.3 : 0.4),
                    width: 2,
                  ),
                  boxShadow: isCream
                      ? null
                      : [
                          BoxShadow(
                            color: template.accentColor.withValues(alpha: 0.2),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                ),
                child: Center(
                  child: Icon(
                    Icons.fingerprint_outlined,
                    size: 36,
                    color: template.accentColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Emotional Message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '우리가 나눈 소중한 시간과 기억들은\n영원히 마음속에서 따뜻하게 빛날 것입니다.',
                  textAlign: TextAlign.center,
                  style: getKoreanStyle(
                    fontSize: 13,
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const Spacer(),
              // Tech lines & Barcode style design
              Column(
                children: [
                  Container(
                    height: 1,
                    width: double.infinity,
                    color: dividerColor,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OWNER: ${card.name.isNotEmpty ? card.name.toUpperCase() : 'IMJONG CARE'}',
                            style: isCream
                                ? GoogleFonts.cormorantGaramond(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: footerTextColor,
                                  )
                                : const TextStyle(
                                    fontFamily: 'Orbitron',
                                    fontSize: 8,
                                    color: Color(0x66FFFFFF),
                                  ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'SECURE DIGITAL WILL ENCRYPTED',
                            style: isCream
                                ? GoogleFonts.cormorantGaramond(
                                    fontSize: 7,
                                    color: footerTextColor.withValues(alpha: 0.6),
                                  )
                                : const TextStyle(
                                    fontFamily: 'Orbitron',
                                    fontSize: 6,
                                    color: Color(0x33FFFFFF),
                                  ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCream ? const Color(0x0A594F45) : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.qr_code_2_outlined,
                          size: 24,
                          color: template.accentColor.withValues(alpha: isCream ? 0.9 : 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
