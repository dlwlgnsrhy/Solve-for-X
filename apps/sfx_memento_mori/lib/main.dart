import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sfx_memento_mori/core/storage/preference_service.dart';
import 'package:sfx_memento_mori/core/theme/app_theme.dart';
import 'package:sfx_memento_mori/features/home/presentation/pages/home_page.dart';
import 'package:sfx_memento_mori/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:sfx_memento_mori/features/onboarding/presentation/pages/welcome_page.dart';
import 'package:sfx_memento_mori/features/onboarding/presentation/providers/onboarding_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize preference service
  final prefsService = PreferenceService();
  await prefsService.init();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(
    ProviderScope(
      overrides: [
        preferenceServiceProvider.overrideWithValue(prefsService),
      ],
      child: const SfxMementoMoriApp(),
    ),
  );
}

class SfxMementoMoriApp extends ConsumerWidget {
  const SfxMementoMoriApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferenceServiceProvider);

    final isOnboarded = prefs.isOnboarded && prefs.birthDate != null && prefs.targetAge != null;
    final welcomeSeen = prefs.welcomeSeen;

    // Determine initial route
    Widget home;
    if (isOnboarded) {
      home = const HomePage();
    } else if (welcomeSeen) {
      home = const OnboardingPage();
    } else {
      home = const WelcomePage();
    }

    return MaterialApp(
      title: 'SFX Memento Mori',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: home,
    );
  }
}
