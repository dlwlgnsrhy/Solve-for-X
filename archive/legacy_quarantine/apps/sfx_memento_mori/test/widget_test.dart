import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sfx_memento_mori/core/storage/preference_service.dart';
import 'package:sfx_memento_mori/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:sfx_memento_mori/main.dart';

void main() {
  testWidgets('App loads onboarding screen', (WidgetTester tester) async {
    // Set standard mobile device physical size and device pixel ratio to prevent layout overflows in test environment
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;

    // Reset physical size after the test completes
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Initialize mock in-memory SharedPreferences for the widget test environment
    SharedPreferences.setMockInitialValues({});
    
    final prefsService = PreferenceService();
    await prefsService.init();

    // Build our app and override preferenceServiceProvider with the initialized service
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferenceServiceProvider.overrideWithValue(prefsService),
        ],
        child: const SfxMementoMoriApp(),
      ),
    );

    // Pump in small increments to allow nested and chained Future.delayed tick timers
    // to step forward, execute, and complete their lifecycle safely without leaving pending timers.
    for (int i = 0; i < 70; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Verify that the welcome page title is displayed.
    expect(find.text('MEMENTO MORI'), findsOneWidget);
  });
}
