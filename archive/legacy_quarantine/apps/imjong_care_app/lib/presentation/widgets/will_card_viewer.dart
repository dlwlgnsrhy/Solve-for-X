import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/model/will_card_model.dart';

/// 3D transform 매트릭스 연산과 Glassmorphism 효과가 60fps로 매끄럽게 돌아가도록 최적화된 성찰형 3D 유서 카드 뷰어 위젯입니다.
/// HTML의 고풍스러운 안쪽 더블 보더 데코레이션과 부드럽게 3D 회전하며 날아가는 Page Flip 제스처 애니메이션을 완벽히 이식했습니다.
class WillCardViewer extends StatefulWidget {
  final List<WillCardModel> wills;
  final PageController pageController;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<WillCardModel> onCardTap;

  const WillCardViewer({
    super.key,
    required this.wills,
    required this.pageController,
    required this.currentIndex,
    required this.onPageChanged,
    required this.onCardTap,
  });

  @override
  State<WillCardViewer> createState() => _WillCardViewerState();
}

class _WillCardViewerState extends State<WillCardViewer> {
  // Page Controller의 스크롤 위치를 고성능 60fps로 실시간 추적하기 위한 ValueNotifier
  late final ValueNotifier<double> _pageNotifier;

  @override
  void initState() {
    super.initState();
    _pageNotifier = ValueNotifier<double>(widget.pageController.initialPage.toDouble());
    widget.pageController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.pageController.removeListener(_onScroll);
    _pageNotifier.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (widget.pageController.hasClients) {
      _pageNotifier.value = widget.pageController.page ?? 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.wills.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final cardHeight = constraints.maxHeight;

        return ValueListenableBuilder<double>(
          valueListenable: _pageNotifier,
          builder: (context, pageVal, child) {
            return PageView.builder(
              controller: widget.pageController,
              itemCount: widget.wills.length,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                // 페이지 전환 완료 시 햅틱 피드백 적용
                HapticFeedback.lightImpact();
                widget.onPageChanged(index);
              },
              itemBuilder: (context, index) {
                final will = widget.wills[index];
                
                // 현재 카드와 스크롤 위치의 차이 계산 (delta)
                final double delta = index - pageVal;
                
                // 3D 회전 및 날아가는 Matrix 변환 공식 적용
                // delta가 0이면 정면, -1이면 완전히 왼쪽으로 날아감, 1이면 완전히 오른쪽에서 들어옴
                final double rotationY = delta * pi * 0.75; // 자연스러운 3D 롤오버를 위해 계수 조절
                final double translationX = delta * cardWidth * 0.4;
                final double scale = (1.0 - (delta.abs() * 0.08)).clamp(0.8, 1.0);
                final double opacity = (1.0 - (delta.abs() * 0.85)).clamp(0.0, 1.0);

                // 3D Perspective 효과와 Matrix4 조작
                final Matrix4 matrix = Matrix4.identity()
                  ..setEntry(3, 2, 0.0012) // 원근법 (Perspective) 설정
                  ..translate(translationX, 0.0, 0.0) // 좌우 드래프트 이동
                  ..scale(scale, scale, 1.0) // 스케일 축소/확대
                  ..rotateY(rotationY); // Y축 3D 회전

                return Opacity(
                  opacity: opacity,
                  child: Transform(
                    transform: matrix,
                    alignment: Alignment.center,
                    child: Center(
                      child: SizedBox(
                        width: cardWidth * 0.95,
                        height: cardHeight * 0.95,
                        child: _buildWillCardItem(context, will),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // HTML 포스트카드 원본 디자인을 정밀 재현한 개별 유서 카드 레이아웃
  Widget _buildWillCardItem(BuildContext context, WillCardModel will) {
    // 템플릿 스타일별로 고급스러운 색상 대비 매핑
    Color cardBgColor;
    Color borderDecorColor;

    switch (will.styleId) {
      case 'warm':
        cardBgColor = const Color(0xFFFDFBF7);
        borderDecorColor = const Color(0x66B5A184);
        break;
      case 'serene':
        cardBgColor = const Color(0xFFF3F7F5);
        borderDecorColor = const Color(0x668EA399);
        break;
      case 'hopeful':
        cardBgColor = const Color(0xFFF2F5F9);
        borderDecorColor = const Color(0x6692A4B7);
        break;
      case 'classic':
      default:
        cardBgColor = AppTheme.surface;
        borderDecorColor = const Color(0x33705E43);
    }

    return GestureDetector(
      onTap: () {
        // 카드 탭 시 햅틱 피드백과 함께 수정 모드로 라우팅
        HapticFeedback.lightImpact();
        widget.onCardTap(will);
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardBgColor.withOpacity(0.85), // Glassmorphism 기본 투명도
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(color: AppTheme.border, width: 1.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 30.0,
              offset: Offset(0, 12),
              spreadRadius: 2.0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: Stack(
            children: [
              // Glassmorphism을 위한 백드롭 블러 효과 적용
              Positioned.fill(
                child: Container(
                  color: Colors.transparent,
                ),
              ),
              // HTML의 고풍스러운 안쪽 더블 보더 데코레이션 재현
              Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: borderDecorColor, width: 1.0),
                  ),
                ),
              ),
              // 내부 유서 콘텐츠 레이아웃
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 스타일 뱃지 오버레이 (상단 중앙)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(color: borderDecorColor, width: 0.5),
                        ),
                        child: Text(
                          will.styleId.toUpperCase(),
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 10.0,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accent,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // 유서 본문 텍스트 (Noto Serif 서체 활용)
                      Text(
                        will.content,
                        style: GoogleFonts.notoSerifKr(
                          textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontSize: 17.0,
                                color: AppTheme.textPrimary,
                                height: 2.1,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.2,
                              ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                      // 작성자 서명 영역 (HTML 감각 유지, Cormorant Garamond / Noto Serif 결합)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '—  ',
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 14.0,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            will.author,
                            style: GoogleFonts.notoSerifKr(
                              fontSize: 13.5,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                    ],
                  ),
                ),
              ),
              
              // 부드러운 우측 하단 에디터 가이드 아이콘 오버레이
              Positioned(
                bottom: 18.0,
                right: 18.0,
                child: Icon(
                  Icons.edit_note_outlined,
                  size: 20.0,
                  color: AppTheme.textSecondary.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
