import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/model/will_card_model.dart';
import '../provider/will_provider.dart';

/// 사용자가 실제로 유서를 작성하고 기존 유서를 불러와 수정할 수 있는 정밀 입력 화면입니다.
/// 메모리 누수를 원천 차단하기 위한 Dispose 생명주기 관리 및 실시간 유효성 검증, 햅틱 피드백이 적용되었습니다.
class WillEditorScreen extends ConsumerStatefulWidget {
  final WillCardModel? editWill;

  const WillEditorScreen({
    super.key,
    this.editWill,
  });

  /// 생성 모드 혹은 수정 모드에 따른 부드러운 라우팅 모션 빌더
  static Route<bool?> route({WillCardModel? editWill}) {
    return PageRouteBuilder<bool?>(
      pageBuilder: (context, animation, secondaryAnimation) => WillEditorScreen(editWill: editWill),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurveTween(curve: Curves.easeInOutCubic);
        final slideIn = Tween<Offset>(
          begin: const Offset(0.0, 0.25),
          end: Offset.zero,
        ).chain(curve);
        final fadeIn = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(curve);

        return FadeTransition(
          opacity: animation.drive(fadeIn),
          child: SlideTransition(
            position: animation.drive(slideIn),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 350),
    );
  }

  @override
  ConsumerState<WillEditorScreen> createState() => _WillEditorScreenState();
}

class _WillEditorScreenState extends ConsumerState<WillEditorScreen> {
  // 메모리 누수를 철저히 방지하기 위해 생명주기를 수동 관리하는 컨트롤러 및 노드
  late final TextEditingController _contentController;
  late final TextEditingController _authorController;
  late final FocusNode _contentFocusNode;
  late final FocusNode _authorFocusNode;

  final _formKey = GlobalKey<FormState>();

  // 실시간 유효성 검증 및 카운트용 상태 값
  String _selectedStyle = 'classic';
  int _contentLength = 0;
  bool _isFormValid = false;

  // 글자 수 최대 한도 설정
  static const int maxContentLength = 150;
  static const int maxAuthorLength = 12;

  @override
  void initState() {
    super.initState();
    final initialContent = widget.editWill?.content ?? '';
    final initialAuthor = widget.editWill?.author ?? '';
    
    _selectedStyle = widget.editWill?.styleId ?? 'classic';
    _contentLength = initialContent.length;

    // 컨트롤러 및 포커스 노드 인스턴스 정밀 생성
    _contentController = TextEditingController(text: initialContent);
    _authorController = TextEditingController(text: initialAuthor);
    _contentFocusNode = FocusNode();
    _authorFocusNode = FocusNode();

    // 입력 실시간 감지를 통한 60fps 인터랙션 바인딩
    _contentController.addListener(_onContentChanged);
    _authorController.addListener(_validateFormSilently);
    
    // 포커스 해제 이벤트 리스너 - 포커스 아웃 시 터치 키보드 자연스럽게 내리기
    _contentFocusNode.addListener(_onFocusChange);
    _authorFocusNode.addListener(_onFocusChange);

    // 초기 폼 상태 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateFormSilently();
    });
  }

  @override
  void dispose() {
    // 메모리 누수(State Update Leak) 방지를 위해 이벤트 리스너 제거
    _contentController.removeListener(_onContentChanged);
    _authorController.removeListener(_validateFormSilently);
    _contentFocusNode.removeListener(_onFocusChange);
    _authorFocusNode.removeListener(_onFocusChange);

    // 컨트롤러 및 포커스 노드 생명주기 완벽 해제 (Dispose)
    _contentController.dispose();
    _authorController.dispose();
    _contentFocusNode.dispose();
    _authorFocusNode.dispose();
    
    super.dispose();
  }

  void _onContentChanged() {
    setState(() {
      _contentLength = _contentController.text.length;
    });
    
    // 글자 수 한도에 다다랐을 때 햅틱 경고 전달
    if (_contentLength >= maxContentLength) {
      HapticFeedback.heavyImpact();
    }
    _validateFormSilently();
  }

  void _onFocusChange() {
    // 포커스 해제 시 햅틱 피드백과 함께 유효성 검증
    if (!_contentFocusNode.hasFocus && !_authorFocusNode.hasFocus) {
      HapticFeedback.selectionClick();
    }
  }

  void _validateFormSilently() {
    final hasContent = _contentController.text.trim().isNotEmpty;
    final hasAuthor = _authorController.text.trim().isNotEmpty;
    final isWithinLimits = _contentController.text.length <= maxContentLength &&
                           _authorController.text.length <= maxAuthorLength;

    final isValid = hasContent && hasAuthor && isWithinLimits;
    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  // 템플릿 선택 시 물리적인 터치 피드백을 동반한 상태 업데이트
  void _selectStyle(String styleId) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedStyle = styleId;
    });
  }

  // 최종 유서 데이터 영속화 저장 액션
  void _saveWill() {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.vibrate();
      return;
    }

    // 저장 시점에 명확한 중간 충격 물리 햅틱 렌더링
    HapticFeedback.mediumImpact();

    final isEditMode = widget.editWill != null;
    final content = _contentController.text.trim();
    final author = _authorController.text.trim();

    if (isEditMode) {
      final updatedWill = widget.editWill!.copyWith(
        content: content,
        author: author,
        styleId: _selectedStyle,
        updatedAt: DateTime.now(),
      );
      ref.read(willStateProvider.notifier).updateWill(updatedWill);
    } else {
      final newWill = WillCardModel(
        uuid: 'will-${DateTime.now().millisecondsSinceEpoch}',
        content: content,
        author: author,
        styleId: _selectedStyle,
        updatedAt: DateTime.now(),
      );
      ref.read(willStateProvider.notifier).createWill(newWill);
    }

    Navigator.of(context).pop(true);
  }

  // 삭제 확정 모달 다이얼로그
  void _confirmDelete() {
    if (widget.editWill == null) return;
    
    HapticFeedback.vibrate();
    
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.background,
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: AppTheme.border),
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
          ),
          title: Text(
            '기록을 지우시겠습니까?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.accent,
                  fontSize: 18.0,
                ),
          ),
          content: const Text(
            '한 번 지워진 소중한 유서 카드는 다시 복구할 수 없습니다.',
            style: TextStyle(
              color: AppTheme.textPrimary,
              height: 1.5,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                '취소',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text(
                '삭제',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                ref.read(willStateProvider.notifier).deleteWill(widget.editWill!.uuid);
                Navigator.of(dialogContext).pop(); // 다이얼로그 닫기
                Navigator.of(context).pop(true); // 에디터 화면도 닫으며 삭제 성공 알림
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('마지막 장이 정갈하게 정리되었습니다.'),
                    backgroundColor: AppTheme.accent,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.editWill != null;
    final theme = Theme.of(context);


    // 카드 스타일에 따른 에디터 폼 배경 색상 변환
    Color previewBgColor;
    Color borderDecorColor;

    switch (_selectedStyle) {
      case 'warm':
        previewBgColor = const Color(0xFFFDFBF7);
        borderDecorColor = const Color(0xFFB5A184).withOpacity(0.3);
        break;
      case 'serene':
        previewBgColor = const Color(0xFFF3F7F5);
        borderDecorColor = const Color(0xFF8EA399).withOpacity(0.3);
        break;
      case 'hopeful':
        previewBgColor = const Color(0xFFF2F5F9);
        borderDecorColor = const Color(0xFF92A4B7).withOpacity(0.3);
        break;
      case 'classic':
      default:
        previewBgColor = AppTheme.surface;
        borderDecorColor = AppTheme.border;
    }

    return GestureDetector(
      // 여백 터치 시 키보드 숨김 처리 및 메모리 누수 방지
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18.0),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            isEditMode ? '유서 다듬기' : '새로운 유서 기록',
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppTheme.accent,
              fontSize: 18.0,
              letterSpacing: 1.0,
            ),
          ),
          actions: [
            if (isEditMode)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22.0),
                onPressed: _confirmDelete,
                tooltip: '기록 삭제',
              ),
            if (_isFormValid)
              TextButton(
                onPressed: _saveWill,
                child: Text(
                  '완료',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Text(
                    '완료',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary.withOpacity(0.4),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // [1] 프리미엄 카드 템플릿 선택기
                        Text(
                          '템플릿 스타일',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStyleOption('classic', '클래식', AppTheme.surface, AppTheme.accent),
                            _buildStyleOption('warm', '단온', const Color(0xFFFDFBF7), const Color(0xFFB5A184)),
                            _buildStyleOption('serene', '정온', const Color(0xFFF3F7F5), const Color(0xFF8EA399)),
                            _buildStyleOption('hopeful', '희망', const Color(0xFFF2F5F9), const Color(0xFF92A4B7)),
                          ],
                        ),
                        const SizedBox(height: 32.0),

                        // [2] 3D 엽서 레이아웃 감각의 실시간 프리뷰 영역
                        Text(
                          '작성 화면 프리뷰',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          height: 220.0,
                          decoration: BoxDecoration(
                            color: previewBgColor,
                            borderRadius: BorderRadius.circular(4.0),
                            border: Border.all(color: AppTheme.border, width: 1.0),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x05000000),
                                blurRadius: 16.0,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // 안쪽 고급 보더 라인
                              Positioned.fill(
                                child: Container(
                                  margin: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: borderDecorColor, width: 1.0),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Center(
                                          child: SingleChildScrollView(
                                            child: Text(
                                              _contentController.text.isEmpty
                                                  ? '이곳에 당신의 소중한 생의 마지막\n기록이 부드럽게 새겨집니다.'
                                                  : _contentController.text,
                                              style: GoogleFonts.notoSerifKr(
                                                fontSize: 14.5,
                                                color: _contentController.text.isEmpty
                                                    ? AppTheme.textSecondary.withOpacity(0.5)
                                                    : AppTheme.textPrimary,
                                                height: 1.8,
                                                fontWeight: FontWeight.w400,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12.0),
                                      Text(
                                        _authorController.text.isEmpty
                                            ? '— 서명'
                                            : '— ${_authorController.text}',
                                        style: GoogleFonts.notoSerifKr(
                                          fontSize: 12.0,
                                          color: AppTheme.textSecondary,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32.0),

                        // [3] 본문 입력 영역 (TextField)
                        Text(
                          '마지막 한 문장',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        TextFormField(
                          controller: _contentController,
                          focusNode: _contentFocusNode,
                          maxLines: 5,
                          textInputAction: TextInputAction.newline,
                          style: GoogleFonts.notoSerifKr(
                            fontSize: 15.0,
                            color: AppTheme.textPrimary,
                            height: 1.6,
                          ),
                          decoration: InputDecoration(
                            hintText: '우리가 함께한 소중한 시간들을 따뜻한 기억으로 간직해주렴.',
                            hintStyle: GoogleFonts.notoSerifKr(
                              color: AppTheme.textSecondary.withOpacity(0.4),
                              fontSize: 14.0,
                            ),
                            fillColor: AppTheme.surface,
                            filled: true,
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: AppTheme.border),
                              borderRadius: BorderRadius.all(Radius.circular(6.0)),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: AppTheme.accent, width: 1.2),
                              borderRadius: BorderRadius.all(Radius.circular(6.0)),
                            ),
                            errorBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.redAccent, width: 1.0),
                              borderRadius: BorderRadius.all(Radius.circular(6.0)),
                            ),
                            focusedErrorBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.redAccent, width: 1.2),
                              borderRadius: BorderRadius.all(Radius.circular(6.0)),
                            ),
                            contentPadding: const EdgeInsets.all(16.0),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '기억하고 싶은 내용을 정성껏 채워주세요.';
                            }
                            if (value.length > maxContentLength) {
                              return '내용은 최대 $maxContentLength자까지 작성 가능합니다.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 6.0),
                        
                        // 우아한 글자 수 세기 인디케이터
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '$_contentLength / $maxContentLength',
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 13.0,
                              color: _contentLength > maxContentLength
                                  ? Colors.redAccent
                                  : AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20.0),

                        // [4] 서명 입력 영역
                        Text(
                          '작성자 서명',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        TextFormField(
                          controller: _authorController,
                          focusNode: _authorFocusNode,
                          maxLength: maxAuthorLength,
                          textInputAction: TextInputAction.done,
                          style: GoogleFonts.notoSerifKr(
                            fontSize: 14.5,
                            color: AppTheme.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: '이름 혹은 남기고 싶은 칭호',
                            hintStyle: GoogleFonts.notoSerifKr(
                              color: AppTheme.textSecondary.withOpacity(0.4),
                              fontSize: 14.0,
                            ),
                            fillColor: AppTheme.surface,
                            filled: true,
                            counterText: '', // 기본 카운터 숨김
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: AppTheme.border),
                              borderRadius: BorderRadius.all(Radius.circular(6.0)),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: AppTheme.accent, width: 1.2),
                              borderRadius: BorderRadius.all(Radius.circular(6.0)),
                            ),
                            errorBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.redAccent, width: 1.0),
                              borderRadius: BorderRadius.all(Radius.circular(6.0)),
                            ),
                            focusedErrorBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.redAccent, width: 1.2),
                              borderRadius: BorderRadius.all(Radius.circular(6.0)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '기록에 남길 서명을 입력해주세요.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 40.0),

                        // [5] 하단 저장 버튼
                        SizedBox(
                          width: double.infinity,
                          height: 52.0,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accent,
                              foregroundColor: AppTheme.background,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              disabledBackgroundColor: AppTheme.textSecondary.withOpacity(0.12),
                              disabledForegroundColor: AppTheme.textSecondary.withOpacity(0.4),
                            ),
                            onPressed: _isFormValid ? _saveWill : null,
                            child: Text(
                              isEditMode ? '수정 내용 저장' : '이 유서 등록하기',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: _isFormValid ? AppTheme.background : AppTheme.textSecondary.withOpacity(0.4),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24.0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // 프리미엄 템플릿 스타일 선택 버블 아이템 빌더
  Widget _buildStyleOption(String styleId, String name, Color bgColor, Color borderStyleColor) {
    final isSelected = _selectedStyle == styleId;

    return GestureDetector(
      onTap: () => _selectStyle(styleId),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 58.0,
            height: 58.0,
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(
                color: isSelected ? AppTheme.accent : AppTheme.border.withOpacity(0.4),
                width: isSelected ? 2.5 : 1.0,
              ),
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.accent.withOpacity(0.15),
                      blurRadius: 10.0,
                      spreadRadius: 2.0,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 22.0, color: AppTheme.accent)
                : null,
          ),
          const SizedBox(height: 6.0),
          Text(
            name,
            style: GoogleFonts.notoSerifKr(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppTheme.accent : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
