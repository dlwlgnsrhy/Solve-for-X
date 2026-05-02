import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origin/core/services/preference_service.dart';
import 'package:origin/core/services/database_service.dart';
import 'package:origin/core/theme/app_theme.dart';
import 'package:origin/features/welcome/welcome_page.dart';
import 'package:origin/features/home/presentation/screens/home_screen.dart';
import 'package:origin/features/onboarding/presentation/widgets/keystroke_capture_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await globalPreferenceService.init();
  await globalDatabaseService.init();
  runApp(const ProviderScope(child: OriginApp()));
}

class OriginApp extends ConsumerWidget {
  const OriginApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Origin',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: _determineRoute(),
      routes: {
        '/welcome': (_) => const WelcomePage(),
        '/keystroke-capture': (_) => const KeystrokeCapturePage(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }

  String _determineRoute() {
    if (globalPreferenceService.isOnboarded) {
      return '/home';
    }
    return '/welcome';
  }
}
