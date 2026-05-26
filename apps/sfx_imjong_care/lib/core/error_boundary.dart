import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'app_theme.dart';

class CustomErrorBoundary extends StatelessWidget {
  final FlutterErrorDetails errorDetails;

  const CustomErrorBoundary({
    super.key,
    required this.errorDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(4.0), // 4px sharp edge
                border: Border.all(color: AppTheme.sepiaBorder, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SYSTEM NOTICE',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          color: AppTheme.terracottaAccent,
                        ),
                      ),
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppTheme.heartStampRed,
                        size: 20,
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Text(
                    '잠시 마음의 정돈이 필요합니다',
                    style: GoogleFonts.notoSerifKr(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.espressoText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '앱 구동 중 예기치 못한 작은 오류가 발생했습니다.\n당신의 소중한 기록은 안전하며, 아래의 상세 오류 정보를 복사하여 개발진에게 전달해 주시면 빠르게 보완하겠습니다.',
                    style: GoogleFonts.notoSerifKr(
                      fontSize: 14,
                      height: 1.6,
                      color: AppTheme.espressoTextLight,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Error Log Viewer
                  Container(
                    width: double.infinity,
                    height: 140,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: AppTheme.creamBg,
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(color: AppTheme.sepiaBorder, width: 1.0),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        errorDetails.toString(),
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 11,
                          color: AppTheme.espressoText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: errorDetails.toString()));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('오류 로그가 클립보드에 복사되었습니다.'),
                                backgroundColor: AppTheme.espressoText,
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 16, color: AppTheme.terracottaAccent),
                          label: Text(
                            '오류 복사하기',
                            style: GoogleFonts.notoSerifKr(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.terracottaAccent,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.terracottaAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Simple way to restart the app screen or navigate to home
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const RestartWidget(),
                              ),
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.refresh, size: 16, color: AppTheme.creamBg),
                          label: Text(
                            '다시 시작하기',
                            style: GoogleFonts.notoSerifKr(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.creamBg,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.terracottaAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
      ),
    );
  }
}

class RestartWidget extends StatelessWidget {
  const RestartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Safely redirects or restarts the app based on runtime platform
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (Platform.isIOS) {
          // Safe Soft Reset for iOS to bypass App Store rejection:
          // Instantly clear stack and push new clean instance of root launcher instead of force crash
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        } else {
          SystemNavigator.pop(); // Android standard back-stack pop to exit safely
        }
      } catch (e) {
        // Safe fallback router reset
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    });
    return const Scaffold(
      backgroundColor: AppTheme.creamBg,
      body: Center(
        child: CircularProgressIndicator(color: AppTheme.terracottaAccent),
      ),
    );
  }
}
