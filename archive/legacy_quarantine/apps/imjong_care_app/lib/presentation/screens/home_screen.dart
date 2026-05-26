import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/model/will_card_model.dart';
import '../provider/will_provider.dart';
import '../widgets/will_card_viewer.dart';
import 'will_editor_screen.dart';

/// 임종 케어 유서 저작 플랫폼의 메인 대시보드 화면입니다.
/// 3D transform이 적용된 [WillCardViewer]와 독립된 [WillEditorScreen]을 긴밀하게 연동하여 
/// 60fps 성능과 깊이 있는 UX 가치를 실현합니다.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final PageController _pageController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    // 3D 회전 카드 뷰가 양옆에 자연스럽게 걸치도록 viewportFraction 최적 조절
    _pageController = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 새로운 유서 작성을 위해 에디터 화면으로 이동
  Future<void> _navigateToAddWill(BuildContext context) async {
    HapticFeedback.lightImpact();
    final result = await Navigator.of(context).push(
      WillEditorScreen.route(),
    );
    
    if (result == true) {
      // 새로운 카드가 성공적으로 등록되었을 때, 리스트의 가장 끝 카드로 스무스하게 롤링
      final length = ref.read(willStateProvider).length;
      if (length > 0) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_pageController.hasClients) {
            _pageController.animateToPage(
              length - 1,
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
    }
  }

  /// 기존 유서를 편집하기 위해 에디터 화면(수정 모드)으로 이동
  Future<void> _navigateToEditWill(BuildContext context, WillCardModel will) async {
    final result = await Navigator.of(context).push(
      WillEditorScreen.route(editWill: will),
    );

    if (result == true) {
      // 삭제 등으로 리스트 개수가 줄어들었을 경우 현재 인덱스 유효성 보정
      final length = ref.read(willStateProvider).length;
      if (_currentPageIndex >= length && length > 0) {
        setState(() {
          _currentPageIndex = length - 1;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wills = ref.watch(willStateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '마지막 장을 기록하다',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppTheme.accent,
            letterSpacing: 2.0,
            fontSize: 19.0,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppTheme.accent, size: 22.0),
            onPressed: () => _showAboutDialog(context),
            tooltip: '플랫폼 안내',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20.0),
            // 상단 페이지 흐름 도트 인디케이터
            _buildPageIndicator(wills.length),
            const SizedBox(height: 24.0),
            
            // 메인 3D 성찰형 카드 뷰어 영역 (PageView 내장)
            Expanded(
              child: wills.isEmpty
                  ? _buildEmptyState(context)
                  : WillCardViewer(
                      wills: wills,
                      pageController: _pageController,
                      currentIndex: _currentPageIndex,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPageIndex = index;
                        });
                      },
                      onCardTap: (will) => _navigateToEditWill(context, will),
                    ),
            ),
            const SizedBox(height: 28.0),
            
            // 하단 조작 네비게이터 바
            _buildBottomControls(context, wills),
            const SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }

  // 슬라이드 흐름을 차분하게 연출해주는 프리미엄 인디케이터
  Widget _buildPageIndicator(int count) {
    if (count <= 0) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isCurrent = index == _currentPageIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          width: isCurrent ? 20.0 : 6.0,
          height: 6.0,
          decoration: BoxDecoration(
            color: isCurrent ? AppTheme.accent : AppTheme.border.withOpacity(0.4),
            borderRadius: BorderRadius.circular(3.0),
          ),
        );
      }),
    );
  }

  // 등록된 유서가 없을 때의 아름답고 아날로그한 엠프티 안내 뷰
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => _navigateToAddWill(context),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
          padding: const EdgeInsets.all(40.0),
          decoration: BoxDecoration(
            color: AppTheme.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(4.0),
            border: Border.all(color: AppTheme.border.withOpacity(0.4)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_stories_outlined,
                size: 52.0,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: 24.0),
              Text(
                '아직 기록된 유서가 없습니다.',
                style: GoogleFonts.notoSerifKr(
                  fontSize: 16.0,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10.0),
              Text(
                '여기를 가볍게 탭하여 첫 번째\n마지막 문장을 세상에 남겨보세요.',
                style: GoogleFonts.notoSerifKr(
                  fontSize: 13.0,
                  color: AppTheme.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 아날로그 카드 넘기기 및 추가 네비게이션 컨트롤 바
  Widget _buildBottomControls(BuildContext context, List<WillCardModel> wills) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 이전 카드 버튼 (루프 스크롤 지원)
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 30.0),
            color: AppTheme.textSecondary,
            onPressed: wills.isEmpty
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    if (_currentPageIndex > 0) {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOutCubic,
                      );
                    } else {
                      _pageController.animateToPage(
                        wills.length - 1,
                        duration: const Duration(milliseconds: 550),
                        curve: Curves.easeInOutCubic,
                      );
                    }
                  },
          ),
          
          // 유서 저작 독립 액션 버튼
          OutlinedButton.icon(
            icon: const Icon(Icons.add, size: 15.0),
            label: const Text('카드 추가'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textPrimary,
              side: const BorderSide(color: AppTheme.border, width: 1.0),
              padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 12.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              textStyle: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            onPressed: () => _navigateToAddWill(context),
          ),
          
          // 다음 카드 버튼 (루프 스크롤 지원)
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 30.0),
            color: AppTheme.textSecondary,
            onPressed: wills.isEmpty
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    if (_currentPageIndex < wills.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOutCubic,
                      );
                    } else {
                      _pageController.animateToPage(
                        0,
                        duration: const Duration(milliseconds: 550),
                        curve: Curves.easeInOutCubic,
                      );
                    }
                  },
          ),
        ],
      ),
    );
  }

  // 앱 저작자 크레딧 안내 팝업
  void _showAboutDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    showAboutDialog(
      context: context,
      applicationName: 'Imjong Care — 마지막 장',
      applicationVersion: '1.2.0 (Premium Ed.)',
      applicationIcon: const Icon(
        Icons.auto_stories,
        color: AppTheme.accent,
        size: 32.0,
      ),
      children: [
        const SizedBox(height: 12.0),
        Text(
          '임종 케어는 인생의 마지막 장을 정갈하고 품격 있게 정비할 수 있도록 조력하는 전인적 유서 저작 플랫폼입니다.',
          style: GoogleFonts.notoSerifKr(fontSize: 13.0, height: 1.6, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 10.0),
        Text(
          'Designed with HSL Acoustic Color tokens and bound with Cormorant Garamond & Noto Serif KR.',
          style: GoogleFonts.cormorantGaramond(fontSize: 12.0, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}
