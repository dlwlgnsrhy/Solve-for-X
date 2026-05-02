import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sfx_legacy_vault/core/config/firebase_options.dart';
import 'package:sfx_legacy_vault/core/theme/app_theme.dart';
import 'package:sfx_legacy_vault/features/auth/presentation/providers/auth_provider.dart';
import 'package:sfx_legacy_vault/features/auth/presentation/screens/login_screen.dart';
import 'package:sfx_legacy_vault/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:sfx_legacy_vault/features/onboarding/presentation/screens/eula_screen.dart';
import 'package:sfx_legacy_vault/features/onboarding/presentation/screens/setup_required_screen.dart';
import 'package:sfx_legacy_vault/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:sfx_legacy_vault/features/vault/presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try Firebase initialization with graceful error handling
  bool firebaseConfigured = true;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    firebaseConfigured = false;
    // Store the failure flag so we can retry or demo
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('firebase_configured', false);
  }

  runApp(
    ProviderScope(
      child: SFXLegacyVaultApp(firebaseConfigured: firebaseConfigured),
    ),
  );
}

/// Tracks whether Firebase is configured and supports retry/demo mode.
class FirebaseConfigNotifier extends Notifier<AsyncValue<bool>> {
  @override
  AsyncValue<bool> build() => const AsyncValue.loading();

  Future<void> setConfigured(bool value) async {
    state = AsyncValue.data(value);
    if (value) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('firebase_configured', true);
    }
  }

  Future<void> retryInitialization() async {
    state = const AsyncValue.loading();
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
        name: 'retry_init',
      );
      await setConfigured(true);
    } catch (e) {
      // Firebase config is still placeholder — keep showing setup screen
      await setConfigured(false);
    }
  }

  Future<void> acceptDemoMode() async {
    await setConfigured(false);
  }
}

final firebaseConfigProvider =
    NotifierProvider<FirebaseConfigNotifier, AsyncValue<bool>>(
        FirebaseConfigNotifier.new);

class SFXLegacyVaultApp extends ConsumerWidget {
  final bool firebaseConfigured;

  const SFXLegacyVaultApp({super.key, required this.firebaseConfigured});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize onboarding checks
    ref.read(welcomeAcceptedProvider.notifier).init();
    ref.read(onboardingProvider.notifier).init();

    // Set up the Firebase config provider with the result from main()
    ref
        .read(firebaseConfigProvider.notifier)
        .setConfigured(firebaseConfigured);

    final configState = ref.watch(firebaseConfigProvider);

    return MaterialApp(
      title: 'SFX Legacy Vault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: configState.when(
        data: (configured) {
          if (!configured) {
            return const SetupRequiredScreen();
          }
          return _MainFlowWidget();
        },
        loading: () => const _SplashScreen(),
        error: (_, __) => const SetupRequiredScreen(),
      ),
    );
  }
}

/// Internal widget that handles the normal app flow after Firebase is ready.
class _MainFlowWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final welcomeAccepted = ref.watch(welcomeAcceptedProvider);
    final eulaAccepted = ref.watch(onboardingProvider);

    if (!welcomeAccepted) {
      return const WelcomeScreen();
    }

    if (!eulaAccepted) {
      return const EulaScreen();
    }

    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
      loading: () => const _SplashScreen(),
      error: (_, __) => const LoginScreen(),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0A0A0F),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF00FF88)),
            SizedBox(height: 16),
            Text(
              'SFX Legacy Vault',
              style: TextStyle(
                color: Color(0xFF00FF88),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
