import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import '../models/will_card.dart';
import '../providers/prompt_deck_provider.dart';
import '../providers/language_provider.dart';
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

  void _applyTemplate(String question) {
    HapticFeedback.lightImpact();
    final locale = ref.read(languageProvider);
    final trans = LocalizationPack(locale);
    final answer = LocalizedQuestions.getTemplate(locale, question);
    _contentController.text = answer;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(trans.translate('template_applied')),
        backgroundColor: AppTheme.terracottaAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _generatePostcard() async {
    final locale = ref.read(languageProvider);
    final trans = LocalizationPack(locale);

    if (_contentController.text.trim().isEmpty) {
      HapticFeedback.vibrate();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: Text(
            trans.translate('error_title'),
            style: GoogleFonts.notoSerifKr(
              fontWeight: FontWeight.bold,
              color: AppTheme.espressoText,
            ),
          ),
          content: Text(
            trans.translate('error_empty_content'),
            style: GoogleFonts.notoSerifKr(color: AppTheme.espressoText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                trans.translate('close'),
                style: const TextStyle(color: AppTheme.terracottaAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
      return;
    }

    final defaultAnon = locale == LanguageLocale.en ? 'Anonymous' : '익명';
    final author = _authorController.text.trim().isEmpty ? defaultAnon : _authorController.text.trim();
    final promptState = ref.read(promptDeckProvider);
    final activeQuestion = LocalizedQuestions.getQuestions(locale)[promptState.currentQuestionIndex];

    final newCard = WillCardModel(
      id: 'will-${DateTime.now().millisecondsSinceEpoch}',
      author: author,
      content: _contentController.text,
      questionPrompt: activeQuestion,
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
        SnackBar(
          content: Text(trans.translate('offline_fallback')),
          backgroundColor: AppTheme.espressoTextLight,
          duration: const Duration(seconds: 3),
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
    final locale = ref.watch(languageProvider);
    final trans = LocalizationPack(locale);

    final activeQuestion = LocalizedQuestions.getQuestions(locale)[promptState.currentQuestionIndex];
    final questionLabel = locale == LanguageLocale.en ? 'REFLECTION QUESTION' : '성찰 질문';

    return Scaffold(
      backgroundColor: AppTheme.creamBg,
      appBar: AppBar(
        title: Text(
          trans.translate('write_will_title'),
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
        iconTheme: const IconThemeData(color: AppTheme.espressoText),
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
                          questionLabel,
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
                              tooltip: locale == LanguageLocale.en ? 'Shuffle' : '셔플',
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
                      activeQuestion,
                      style: GoogleFonts.notoSerifKr(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                        color: AppTheme.espressoText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _applyTemplate(activeQuestion),
                      icon: const Icon(Icons.auto_awesome, size: 16, color: AppTheme.terracottaAccent),
                      label: Text(
                        trans.translate('get_template'),
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
                trans.translate('letter_content'),
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
                    hintText: trans.translate('content_hint'),
                    hintStyle: GoogleFonts.notoSerifKr(
                      fontSize: 14,
                      color: AppTheme.espressoTextLight.withValues(alpha: 0.4),
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
                trans.translate('author_signature'),
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
                    hintText: trans.translate('author_hint'),
                    hintStyle: GoogleFonts.notoSerifKr(
                      fontSize: 14,
                      color: AppTheme.espressoTextLight.withValues(alpha: 0.4),
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
                    trans.translate('generate_card'),
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
