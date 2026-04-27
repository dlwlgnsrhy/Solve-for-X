import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sfx_imjong_care/core/constants/app_constants.dart';
import 'package:sfx_imjong_care/core/services/app_storage.dart';
import 'package:sfx_imjong_care/core/theme/neon_colors.dart';
import 'package:sfx_imjong_care/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:sfx_imjong_care/features/will_input/presentation/screens/will_input_screen.dart';

void main() {
  runApp(const ProviderScope(child: SfxImjongCareApp()));
}

class SfxImjongCareApp extends StatelessWidget {
  const SfxImjongCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: NeonColors.background,
        colorScheme: ColorScheme.dark(
          primary: NeonColors.neonGreen,
          secondary: NeonColors.neonPink,
          surface: NeonColors.surface,
          onSurface: Colors.white,
        ),
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: const TextStyle(
            color: Color(0x66AAAAAA),
            fontSize: 14,
          ),
          border: InputBorder.none,
          filled: false,
        ),
      ),
      themeMode: ThemeMode.dark,
      home: const _AppRoot(),
    );
  }
}

/// Root widget that checks onboarding status and routes accordingly.
class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  late Future<bool> _onboardingFuture;

  @override
  void initState() {
    super.initState();
    _onboardingFuture = AppStorage.isOnboardingCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _onboardingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0A0A0F),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF88)),
              ),
            ),
          );
        }
        final completed = snapshot.data ?? false;
        if (completed) {
          return const WillInputScreen();
        } else {
          return const OnboardingScreen();
        }
      },
    );
  }
}
