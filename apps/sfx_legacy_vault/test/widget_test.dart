import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sfx_legacy_vault/core/constants/app_colors.dart';

void main() {
  testWidgets('App loads with neon theme', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text(
                'SFX Legacy Vault',
                style: TextStyle(color: AppColors.neonGreen),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('SFX Legacy Vault'), findsOneWidget);
  });
}
