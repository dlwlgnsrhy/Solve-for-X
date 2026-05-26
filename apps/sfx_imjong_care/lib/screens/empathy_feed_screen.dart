import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import '../models/will_card.dart';
import '../services/firebase_service.dart';
import 'postcard_home_screen.dart';

class EmpathyFeedScreen extends StatefulWidget {
  const EmpathyFeedScreen({super.key});

  @override
  State<EmpathyFeedScreen> createState() => _EmpathyFeedScreenState();
}

class _EmpathyFeedScreenState extends State<EmpathyFeedScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamBg,
      appBar: AppBar(
        title: Text(
          'EMPATHY FEED',
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.espressoText),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
      ),
      body: StreamBuilder<List<WillCardModel>>(
        stream: _firebaseService.getPublicWillsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.terracottaAccent),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  '피드를 불러오는 도중 오류가 발생했습니다.\n네트워크 연결을 확인해 주세요.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSerifKr(color: AppTheme.espressoTextLight, height: 1.6),
                ),
              ),
            );
          }

          final wills = snapshot.data ?? [];
          
          if (wills.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border, size: 48, color: AppTheme.sepiaBorder),
                  const SizedBox(height: 16),
                  Text(
                    '첫 번째 따뜻한 이야기를 공유해 주세요.',
                    style: GoogleFonts.notoSerifKr(
                      fontSize: 15,
                      color: AppTheme.espressoTextLight,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            itemCount: wills.length,
            itemBuilder: (context, index) {
              final will = wills[index];
              return _FeedCardItem(
                will: will,
                firebaseService: _firebaseService,
              );
            },
          );
        },
      ),
    );
  }
}

// Optimized Leaf Component for Isolated Reactive Rendering (Jank-Free 60fps)
class _FeedCardItem extends StatelessWidget {
  final WillCardModel will;
  final FirebaseService firebaseService;

  const _FeedCardItem({
    required this.will,
    required this.firebaseService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: AppTheme.sepiaBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(4.0),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostcardHomeScreen(customWillCard: will),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (will.questionPrompt != null) ...[
                  Text(
                    will.questionPrompt!,
                    style: GoogleFonts.notoSerifKr(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.terracottaAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  will.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSerifKr(
                    fontSize: 14,
                    height: 1.6,
                    color: AppTheme.espressoText,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '— ${will.author}',
                      style: GoogleFonts.notoSerifKr(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.espressoTextLight,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        firebaseService.likeWill(will.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.sepiaBorder),
                          borderRadius: BorderRadius.circular(2.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.favorite,
                              size: 14,
                              color: AppTheme.heartStampRed,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '공감 ${will.likes}',
                              style: GoogleFonts.notoSerifKr(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.espressoTextLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
