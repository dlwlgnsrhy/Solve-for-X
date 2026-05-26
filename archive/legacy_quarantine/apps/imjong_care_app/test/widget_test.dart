// This is a basic Flutter widget test for Imjong Care App.
// We verify that the main application mounts safely and the title is visible.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imjong_care_app/main.dart';

void main() {
  testWidgets('Imjong Care App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: ImjongCareApp(),
      ),
    );

    // Verify that the title text is correctly displayed.
    expect(find.text('마지막 장을 기록하다'), findsOneWidget);
  });
}
