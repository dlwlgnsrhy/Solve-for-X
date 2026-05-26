import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../core/app_theme.dart';
import '../models/will_card.dart';
import 'will_editor_screen.dart';

class PostcardHomeScreen extends StatefulWidget {
  final WillCardModel? customWillCard;
  const PostcardHomeScreen({super.key, this.customWillCard});

  @override
  State<PostcardHomeScreen> createState() => _PostcardHomeScreenState();
}

class _PostcardHomeScreenState extends State<PostcardHomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFront = true;
  final ScreenshotController _screenshotController = ScreenshotController();

  // Active card getter: prefers customWillCard if passed, otherwise falls back to sample
  WillCardModel get _activeCard => widget.customWillCard ?? _sampleCard;

  Future<void> _captureAndShare() async {
    HapticFeedback.mediumImpact();
    
    // Show quick progress loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.terracottaAccent),
      ),
    );

    try {
      final imageBytes = await _screenshotController.capture(
        pixelRatio: 3.0, // High-resolution pixel ratio
      );

      // Close loading indicator
      if (mounted) Navigator.pop(context);

      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = await File('${directory.path}/imjong_postcard.png').create();
        await imagePath.writeAsBytes(imageBytes);

        // Trigger native share dialog
        await Share.shareXFiles(
          [XFile(imagePath.path)],
          text: '임종 케어 엽서가 마음을 담아 배달되었습니다.\n온전한 감동을 동적 웹페이지에서도 만나보세요.',
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Capture & Share Error: $e");
    }
  }

  // Temporary sample card data
  final WillCardModel _sampleCard = WillCardModel(
    id: 'sample-1',
    author: '홍길동',
    content: '내가 먼저 떠나도 슬퍼하지 마세요.\n우리가 나누었던 그 따스했던 미소와 다정한 말들은\n바람이 되어 언제나 당신 곁에 머물 것입니다.\n사랑합니다, 그리고 고맙습니다.',
    questionPrompt: 'Q1. 사랑하는 이들에게 남기고 싶은 마지막 한마디는 무엇인가요?',
    createdAt: DateTime.now(),
  );

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
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppTheme.espressoText),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppTheme.cardBg,
                  title: Text('아날로그 엽서 사용법', style: Theme.of(context).textTheme.titleLarge),
                  content: Text('엽서를 터치하면 3D 플립 애니메이션과 함께 앞뒷면이 전환됩니다. 아날로그 감성의 마음을 전해보세요.',
                      style: Theme.of(context).textTheme.bodyMedium),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('확인', style: TextStyle(color: AppTheme.terracottaAccent)),
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
                '엽서를 터치하여 돌려보세요',
                style: GoogleFonts.notoSerifKr(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.espressoTextLight.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
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
                                    child: _buildCardBack(),
                                  )
                                : _buildCardFront(),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _toggleCard,
                      icon: const Icon(Icons.flip, color: AppTheme.terracottaAccent),
                      label: Text(
                        _isFront ? '뒷면 보기' : '앞면 보기',
                        style: GoogleFonts.notoSerifKr(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.terracottaAccent,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.terracottaAccent, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _captureAndShare,
                      icon: const Icon(Icons.share, color: AppTheme.creamBg),
                      label: Text(
                        '엽서 이미지 공유',
                        style: GoogleFonts.notoSerifKr(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.creamBg,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.terracottaAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: widget.customWillCard == null
          ? FloatingActionButton.extended(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WillEditorScreen()),
                );
              },
              backgroundColor: AppTheme.terracottaAccent,
              icon: const Icon(Icons.edit, color: AppTheme.creamBg),
              label: Text(
                '유서 작성하기',
                style: GoogleFonts.notoSerifKr(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.creamBg,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
              ),
            )
          : null,
    );
  }

  Widget _buildCardFront() {
    return Container(
      width: double.infinity,
      height: 420,
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(4.0), // 4px sharp edge
        border: Border.all(color: AppTheme.sepiaBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
                  color: AppTheme.sepiaBorder.withOpacity(0.8),
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
                if (_activeCard.questionPrompt != null) ...[
                  Text(
                    'Reflection Question',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.terracottaAccent,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _activeCard.questionPrompt!,
                    style: GoogleFonts.notoSerifKr(
                      fontSize: 16,
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
                    _buildAddressLine('Sender: ${_activeCard.author}'),
                    const SizedBox(height: 12),
                    _buildAddressLine('Date: ${_activeCard.createdAt.year}. ${_activeCard.createdAt.month}. ${_activeCard.createdAt.day}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      width: double.infinity,
      height: 420,
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: AppTheme.sepiaBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
                  color: AppTheme.sepiaBorder.withOpacity(0.8),
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
                      'MY LAST WILL',
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
                      _activeCard.content,
                      style: GoogleFonts.notoSerifKr(
                        fontSize: 15,
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
                      '서명: ',
                      style: GoogleFonts.notoSerifKr(
                        fontSize: 14,
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
                        _activeCard.author,
                        style: GoogleFonts.notoSerifKr(
                          fontSize: 14,
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
          // Stamp borders (wavy pattern representation)
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(2.0),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.terracottaAccent.withOpacity(0.3),
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

  Widget _buildAddressLine(String text) {
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
        style: GoogleFonts.notoSerifKr(
          fontSize: 14,
          color: AppTheme.espressoTextLight,
        ),
      ),
    );
  }
}
