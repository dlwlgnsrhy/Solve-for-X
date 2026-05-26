import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sfx_imjong_care/main.dart';

void main() {
  testWidgets('Imjong Care Postcard Home Screen Smoke Test', (WidgetTester tester) async {
    // Build our app under ProviderScope and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // Verify that the AppBar title 'POSTCARD' is present.
    expect(find.text('POSTCARD'), findsOneWidget);

    // Verify that the instructions text is present.
    expect(find.text('엽서를 터치하여 돌려보세요'), findsOneWidget);

    // Verify info button is present and tap it.
    final infoButtonFinder = find.byIcon(Icons.info_outline);
    expect(infoButtonFinder, findsOneWidget);
    await tester.tap(infoButtonFinder);
    await tester.pumpAndSettle();

    // Verify that the instruction dialog appears with title '아날로그 엽서 사용법'.
    expect(find.text('아날로그 엽서 사용법'), findsOneWidget);

    // Tap confirm button on the dialog to close it.
    final closeButtonFinder = find.text('확인');
    expect(closeButtonFinder, findsOneWidget);
    await tester.tap(closeButtonFinder);
    await tester.pumpAndSettle();

    // Dialog should be gone
    expect(find.text('아날로그 엽서 사용법'), findsNothing);
  });
}
