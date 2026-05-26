import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import '../models/will_card.dart';
import '../providers/prompt_deck_provider.dart';
import 'postcard_home_screen.dart';
import '../services/firebase_service.dart';

class WillEditorScreen extends ConsumerStatefulWidget {
  const WillEditorScreen({super.key});

  @override
  ConsumerState<WillEditorScreen> createState() => _WillEditorScreenState();
}

class _WillEditorScreenState extends ConsumerState<WillEditorScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();

  // Standard predefined answers mapping to questions for smart auto-filling
  final Map<String, String> _templateAnswers = {
    "Q. 사랑하는 이들에게 평소 말하지 못했던, 가슴속 깊이 묻어둔 고마운 기억은 무엇인가요?":
        "가장 힘들고 지쳤던 밤, 묵묵히 내 어깨를 토닥여주던 당신의 그 따스한 손길이 기억납니다. 늘 곁에 있어줘서 참 고마웠습니다.",
    "Q. 내가 떠난 후, 남겨진 사람들이 나를 기억할 때 떠올려 주었으면 하는 모습이 있나요?":
        "기억할 때 슬퍼하기보다는, 늘 활짝 웃으며 긍정적인 에너지를 건네던 사람으로 웃으며 추억해 주었으면 좋겠습니다.",
    "Q. 인생의 마지막 여정에서 가장 아름다웠던 한 순간을 고른다면 언제인가요?":
        "눈이 부시도록 맑은 날, 우리 가족이 함께 떠나 마음껏 웃고 떠들었던 소소한 여행길이 내 삶의 가장 찬란한 봄날이었습니다.",
    "Q. 지금 당장 내일 떠난다면, 가장 미안해서 마음 한구석이 아련해지는 사람은 누구인가요?":
        "내가 조금 더 다정하게 안아주고 더 많은 시간을 함께 보내지 못했던 우리 아이에게 미안한 마음이 아스라이 밀려옵니다.",
    "Q. 남겨진 소중한 이들에게 남기는 마지막 조언이나 응원의 한마디는 무엇인가요?":
        "인생의 거친 파도가 닥쳐도, 서로의 손을 꼭 쥐고 한 걸음씩 걸어 나간다면 반드시 따스한 햇살이 비칠 것입니다. 용기를 잃지 마세요.",
    "Q. 인생을 돌아보며 나 스스로에게 가장 칭찬해주고 싶은 나의 자랑스러운 선택은 무엇인가요?":
        "수많은 고난과 역경 속에서도, 타인을 배려하고 나 자신을 지키며 정직하게 삶의 길을 묵묵히 걸어온 선택이 참 자랑스럽습니다.",
    "Q. 나의 소중한 물건이나 유품을 누구에게 어떤 마음으로 전하고 싶나요?":
        "내가 항상 소중하게 지니고 다니며 일기를 적던 오래된 가죽 다이어리를 내 절친한 친구에게 전해 따뜻했던 추억의 한 조각으로 나누고 싶습니다."
  };

  void _applyTemplate(String question) {
    HapticFeedback.lightImpact();
    final answer = _templateAnswers[question] ?? "진심을 담아 유서를 써보세요.";
    _contentController.text = answer;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('성찰 답변 가이드라인이 주입되었습니다.'),
        backgroundColor: AppTheme.terracottaAccent,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _generatePostcard() async {
    if (_contentController.text.trim().isEmpty) {
      HapticFeedback.vibrate();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: Text('작성 오류', style: Theme.of(context).textTheme.titleLarge),
          content: Text('마지막 편지의 내용을 입력해 주세요.', style: Theme.of(context).textTheme.bodyMedium),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('확인', style: TextStyle(color: AppTheme.terracottaAccent)),
            ),
          ],
        ),
      );
      return;
    }

    final author = _authorController.text.trim().isEmpty ? '익명' : _authorController.text.trim();
    final promptState = ref.read(promptDeckProvider);

    final newCard = WillCardModel(
      id: 'will-${DateTime.now().millisecondsSinceEpoch}',
      author: author,
      content: _contentController.text,
      questionPrompt: promptState.currentQuestion,
      createdAt: DateTime.now(),
    );

    HapticFeedback.heavyImpact();
    
    // Show Loading Modal Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.terracottaAccent),
      ),
    );

    bool isUploaded = false;
    try {
      // Lazy load auth session to guarantee valid user tokens
      final firebaseService = FirebaseService();
      if (firebaseService.currentUid == null) {
        await firebaseService.signInAnonymously();
      }
      isUploaded = await firebaseService.uploadWill(newCard);
    } catch (e) {
      debugPrint("SRE Core Alert: Network/Firebase Persistence Bypass. $e");
    }

    // Close Loading Modal
    if (mounted) Navigator.pop(context);

    // Show status snackbar on failure but continue route fallback
    if (!isUploaded && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('오프라인 환경으로 전환되어 로컬 엽서 뷰어로 안전하게 연결합니다.'),
          backgroundColor: AppTheme.espressoTextLight,
          duration: Duration(seconds: 3),
        ),
      );
    }

    if (mounted) {
      // Navigate to viewer screen with custom slide transition
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              PostcardHomeScreen(customWillCard: newCard),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final promptState = ref.watch(promptDeckProvider);

    return Scaffold(
      backgroundColor: AppTheme.creamBg,
      appBar: AppBar(
        title: Text(
          'WRITE WILL',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: AppTheme.espressoText,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Reflection Question Deck Box (Postcard Style Header)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(color: AppTheme.sepiaBorder, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'REFLECTION QUESTION',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: AppTheme.terracottaAccent,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.shuffle, size: 18, color: AppTheme.terracottaAccent),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                ref.read(promptDeckProvider.notifier).shuffleQuestions();
                              },
                              tooltip: '셔플',
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios, size: 14, color: AppTheme.espressoTextLight),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                ref.read(promptDeckProvider.notifier).prevQuestion();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.espressoTextLight),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                ref.read(promptDeckProvider.notifier).nextQuestion();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      promptState.currentQuestion,
                      style: GoogleFonts.notoSerifKr(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                        color: AppTheme.espressoText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _applyTemplate(promptState.currentQuestion),
                      icon: const Icon(Icons.auto_awesome, size: 16, color: AppTheme.terracottaAccent),
                      label: Text(
                        '이 질문의 답변 템플릿 가져오기',
                        style: GoogleFonts.notoSerifKr(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.terracottaAccent,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.sepiaBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Will Input Form (Underlined Vintage Paper Style)
              Text(
                '편지 내용',
                style: GoogleFonts.notoSerifKr(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.espressoText,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(color: AppTheme.sepiaBorder, width: 1.5),
                ),
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _contentController,
                  maxLines: 8,
                  style: GoogleFonts.notoSerifKr(
                    fontSize: 15,
                    height: 1.8,
                    color: AppTheme.espressoText,
                  ),
                  decoration: InputDecoration(
                    hintText: '여기에 진심을 담아 마지막 한마디를 적어 내려가 보세요...\n(상단의 성찰 질문을 활용하면 보다 편하게 적을 수 있습니다)',
                    hintStyle: GoogleFonts.notoSerifKr(
                      fontSize: 14,
                      color: AppTheme.espressoTextLight.withOpacity(0.4),
                    ),
                    fillColor: Colors.transparent,
                    filled: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 3. Sender/Author Name Input (Signature Guideline)
              Text(
                '서명인 이름',
                style: GoogleFonts.notoSerifKr(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.espressoText,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(color: AppTheme.sepiaBorder, width: 1.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: TextField(
                  controller: _authorController,
                  style: GoogleFonts.notoSerifKr(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.espressoText,
                  ),
                  decoration: InputDecoration(
                    hintText: '이름을 적어주세요 (기본값: 익명)',
                    hintStyle: GoogleFonts.notoSerifKr(
                      fontSize: 14,
                      color: AppTheme.espressoTextLight.withOpacity(0.4),
                    ),
                    fillColor: Colors.transparent,
                    filled: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 4. Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generatePostcard,
                  icon: const Icon(Icons.auto_awesome, color: AppTheme.creamBg),
                  label: Text(
                    '3D 아날로그 엽서 생성하기',
                    style: GoogleFonts.notoSerifKr(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.creamBg,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.terracottaAccent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    elevation: 2,
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
