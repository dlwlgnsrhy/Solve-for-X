import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: ImjongCareApp(),
    ),
  );
}

/// 임종 케어 유서 저작 플랫폼 앱의 진입점(Entry Point) 위젯입니다.
/// 최고 아키텍처 수준의 반응형 테마 및 Riverpod 전역 상태 환경을 바인딩합니다.
class ImjongCareApp extends StatelessWidget {
  const ImjongCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Imjong Care',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
