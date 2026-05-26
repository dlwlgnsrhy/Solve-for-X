import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_theme.dart';
import '../models/will_card.dart';
import '../providers/language_provider.dart';
import 'will_editor_screen.dart';
import 'empathy_feed_screen.dart';
import 'legal_guide_screen.dart';

class PostcardHomeScreen extends ConsumerStatefulWidget {
  final WillCardModel? customWillCard;
  const PostcardHomeScreen({super.key, this.customWillCard});

  @override
  ConsumerState<PostcardHomeScreen> createState() => _PostcardHomeScreenState();
}

class _PostcardHomeScreenState extends ConsumerState<PostcardHomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFront = true;
  final ScreenshotController _screenshotController = ScreenshotController();

  WillCardModel _getSampleCard(LanguageLocale locale) {
    final trans = LocalizationPack(locale);
    return WillCardModel(
      id: 'sample-1',
      author: trans.translate('sample_author'),
      content: trans.translate('sample_content'),
      questionPrompt: trans.translate('sample_question'),
      createdAt: DateTime.now(),
    );
  }

  WillCardModel _getActiveCard(LanguageLocale locale) {
    return widget.customWillCard ?? _getSampleCard(locale);
  }

  Future<void> _captureAndShare(LocalizationPack trans) async {
    if (_flipController.isAnimating) return;
    HapticFeedback.mediumImpact();
    
    // Show quick progress loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.terracottaAccent),
      ),
    );

    File? imageFile;
    try {
      final imageBytes = await _screenshotController.capture(
        pixelRatio: 3.0, // High-resolution pixel ratio
      );

      // Close loading indicator
      if (mounted) Navigator.pop(context);

      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        imageFile = await File('${directory.path}/imjong_postcard_${DateTime.now().millisecondsSinceEpoch}.png').create();
        await imageFile.writeAsBytes(imageBytes);

        // Trigger native share dialog
        await Share.shareXFiles(
          [XFile(imageFile.path)],
          text: trans.translate('post_card') == 'POST CARD'
              ? 'My sincere will postcard has been delivered. Feel the warmth.'
              : '임종 케어 엽서가 마음을 담아 배달되었습니다.\n온전한 감동을 느껴보세요.',
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to capture postcard image.'),
              backgroundColor: AppTheme.heartStampRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing postcard: $e'),
            backgroundColor: AppTheme.heartStampRed,
          ),
        );
      }
      debugPrint("Capture & Share Error: $e");
    } finally {
      try {
        if (imageFile != null && await imageFile.exists()) {
          await imageFile.delete();
          debugPrint("SRE Disk Cache Safeguard: Cleared temporary screenshot file.");
        }
      } catch (err) {
        debugPrint("SRE Disk Cache Clear Error: $err");
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleCard() {
    HapticFeedback.mediumImpact();
    if (_isFront) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);
    final trans = LocalizationPack(locale);
    final activeCard = _getActiveCard(locale);

    return Scaffold(
      backgroundColor: AppTheme.creamBg,
      appBar: AppBar(
        leading: widget.customWillCard != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.espressoText),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
              )
            : null,
        title: Text(
          'POSTCARD',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: AppTheme.espressoText,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Elegant language switcher
          TextButton.icon(
            key: const ValueKey('lang_toggle_btn'),
            onPressed: () {
              HapticFeedback.selectionClick();
              ref.read(languageProvider.notifier).toggleLanguage();
            },
            icon: const Icon(Icons.language, size: 16, color: AppTheme.espressoText),
            label: Text(
              locale == LanguageLocale.ko ? 'EN' : '한글',
              style: GoogleFonts.cormorantGaramond(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.espressoText,
              ),
            ),
          ),
          if (widget.customWillCard == null)
            IconButton(
              icon: const Icon(Icons.forum_outlined, color: AppTheme.espressoText),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EmpathyFeedScreen()),
                );
              },
              tooltip: locale == LanguageLocale.en ? 'Empathy Feed' : '공감 피드',
            ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppTheme.espressoText),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppTheme.cardBg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                  title: Text(
                    trans.translate('info_guide'), 
                    style: GoogleFonts.notoSerifKr(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.espressoText,
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trans.translate('info_step1'),
                          style: GoogleFonts.notoSerifKr(fontSize: 13, height: 1.5, color: AppTheme.espressoText),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          trans.translate('info_step2'),
                          style: GoogleFonts.notoSerifKr(fontSize: 13, height: 1.5, color: AppTheme.espressoText),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          trans.translate('info_step3'),
                          style: GoogleFonts.notoSerifKr(fontSize: 13, height: 1.5, color: AppTheme.espressoText),
                        ),
                      ],
                    ),
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
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                trans.translate('tap_to_flip'),
                style: locale == LanguageLocale.en
                    ? GoogleFonts.cormorantGaramond(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.espressoTextLight.withValues(alpha: 0.7),
                      )
                    : GoogleFonts.notoSerifKr(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.espressoTextLight.withValues(alpha: 0.7),
                      ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: Screenshot(
                    controller: _screenshotController,
                    child: GestureDetector(
                      onTap: _toggleCard,
                      child: AnimatedBuilder(
                        animation: _flipAnimation,
                        builder: (context, child) {
                          final angle = _flipAnimation.value * pi;
                          final isUnder = angle > pi / 2;

                          return Transform(
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001) // perspective
                              ..rotateY(angle),
                            alignment: Alignment.center,
                            child: isUnder
                                ? Transform(
                                    transform: Matrix4.identity()..rotateY(pi),
                                    alignment: Alignment.center,
                                    child: _buildCardBack(locale, activeCard),
                                  )
                                : _buildCardFront(locale, activeCard),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Zero-Overlap Bottom Action Grid
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _toggleCard,
                          icon: const Icon(Icons.flip, color: AppTheme.terracottaAccent),
                          label: Text(
                            trans.translate(_isFront ? 'view_back' : 'view_front'),
                            style: GoogleFonts.notoSerifKr(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.terracottaAccent,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.terracottaAccent, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _captureAndShare(trans),
                          icon: const Icon(Icons.share, color: AppTheme.terracottaAccent),
                          label: Text(
                            trans.translate('share_postcard'),
                            style: GoogleFonts.notoSerifKr(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.terracottaAccent,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.terracottaAccent, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.customWillCard == null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const WillEditorScreen()),
                          );
                        },
                        icon: const Icon(Icons.edit, color: AppTheme.creamBg),
                        label: Text(
                          trans.translate('write_will'),
                          style: GoogleFonts.notoSerifKr(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.creamBg,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.terracottaAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LegalGuideScreen(
                              customWillCard: widget.customWillCard,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.gavel, color: AppTheme.creamBg),
                      label: Text(
                        trans.translate('legal_guide'),
                        style: GoogleFonts.notoSerifKr(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.creamBg,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.espressoText,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        elevation: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardFront(LanguageLocale locale, WillCardModel activeCard) {
    final trans = LocalizationPack(locale);
    final questionLabel = locale == LanguageLocale.en ? 'Reflection Question' : '성찰 질문';

    return Container(
      width: double.infinity,
      height: 420,
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(4.0), // 4px sharp edge
        border: Border.all(color: AppTheme.sepiaBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 10px inner margin dotted guide line
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2.0),
                border: Border.all(
                  color: AppTheme.sepiaBorder.withValues(alpha: 0.8),
                  style: BorderStyle.solid,
                  width: 1.0,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top header: POSTCARD, Heart Stamp
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'POST CARD',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3.0,
                            color: AppTheme.terracottaAccent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 60,
                          height: 1.5,
                          color: AppTheme.terracottaAccent,
                        ),
                      ],
                    ),
                    // Heart Stamp
                    _buildHeartStamp(),
                  ],
                ),
                const Spacer(),
                // Question / Prompt
                if (activeCard.questionPrompt != null) ...[
                  Text(
                    questionLabel,
                    style: locale == LanguageLocale.en
                        ? GoogleFonts.cormorantGaramond(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.terracottaAccent,
                          )
                        : GoogleFonts.notoSerifKr(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.terracottaAccent,
                          ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    activeCard.questionPrompt!,
                    style: locale == LanguageLocale.en
                        ? GoogleFonts.cormorantGaramond(
                            fontSize: 16,
                            height: 1.4,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.espressoText,
                          )
                        : GoogleFonts.notoSerifKr(
                            fontSize: 15,
                            height: 1.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.espressoText,
                          ),
                  ),
                ],
                const Spacer(),
                // Bottom lines & signature guidelines
                Column(
                  children: [
                    _buildAddressLine(locale, '${trans.translate('sender')}: ${activeCard.author}'),
                    const SizedBox(height: 12),
                    _buildAddressLine(locale, '${trans.translate('date')}: ${activeCard.createdAt.year}. ${activeCard.createdAt.month}. ${activeCard.createdAt.day}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(LanguageLocale locale, WillCardModel activeCard) {
    final trans = LocalizationPack(locale);

    return Container(
      width: double.infinity,
      height: 420,
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: AppTheme.sepiaBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 10px inner margin
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2.0),
                border: Border.all(
                  color: AppTheme.sepiaBorder.withValues(alpha: 0.8),
                  width: 1.0,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      trans.translate('my_last_will'),
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: AppTheme.terracottaAccent,
                      ),
                    ),
                    const Icon(Icons.favorite, color: AppTheme.heartStampRed, size: 18),
                  ],
                ),
                const Divider(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      activeCard.content,
                      style: locale == LanguageLocale.en
                          ? GoogleFonts.cormorantGaramond(
                              fontSize: 16,
                              height: 1.6,
                              color: AppTheme.espressoText,
                            )
                          : GoogleFonts.notoSerifKr(
                              fontSize: 14,
                              height: 1.8,
                              color: AppTheme.espressoText,
                            ),
                    ),
                  ),
                ),
                const Divider(height: 24),
                // Signature Line
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${trans.translate('signature')}: ',
                      style: locale == LanguageLocale.en
                          ? GoogleFonts.cormorantGaramond(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: AppTheme.espressoTextLight,
                            )
                          : GoogleFonts.notoSerifKr(
                              fontSize: 13,
                              color: AppTheme.espressoTextLight,
                            ),
                    ),
                    Container(
                      width: 120,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppTheme.espressoText, width: 1.0),
                        ),
                      ),
                      alignment: Alignment.centerRight,
                      child: Text(
                        activeCard.author,
                        style: locale == LanguageLocale.en
                            ? GoogleFonts.cormorantGaramond(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.espressoText,
                              )
                            : GoogleFonts.notoSerifKr(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.espressoText,
                              ),
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

  Widget _buildHeartStamp() {
    return Container(
      width: 54,
      height: 64,
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        border: Border.all(color: AppTheme.terracottaAccent, width: 1.0),
        borderRadius: BorderRadius.circular(2.0),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(2.0),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.terracottaAccent.withValues(alpha: 0.3),
                  style: BorderStyle.solid,
                ),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.favorite,
                color: AppTheme.heartStampRed,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                'LOVE',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.terracottaAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressLine(LanguageLocale locale, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 6),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.sepiaBorder, width: 1.0),
        ),
      ),
      child: Text(
        text,
        style: locale == LanguageLocale.en
            ? GoogleFonts.cormorantGaramond(
                fontSize: 15,
                color: AppTheme.espressoTextLight,
              )
            : GoogleFonts.notoSerifKr(
                fontSize: 13,
                color: AppTheme.espressoTextLight,
              ),
      ),
    );
  }
}
