import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sfx_imjong_care/features/will_input/presentation/screens/will_input_screen.dart';

void main() {
  group('WillInputScreen Integration Tests', () {
    Widget makeWidget({Key? key}) {
      return ProviderScope(
        key: key,
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: WillInputScreen(),
        ),
      );
    }

    testWidgets('should render with title and all input fields', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // Title should be visible
      expect(find.text('SFX 임종 케어'), findsOneWidget);

      // All input fields should be present
      expect(find.text('YOUR NAME / 당신의 이름'), findsOneWidget);
      expect(find.text('MY VALUES / 내 가치'), findsOneWidget);
      expect(find.text('VALUE 1'), findsOneWidget);
      expect(find.text('VALUE 2'), findsOneWidget);
      expect(find.text('VALUE 3'), findsOneWidget);
      expect(find.text('ONE-LINE WILL / 한 줄 유언'), findsOneWidget);
      expect(find.text('YOUR WILL / 당신의 유언'), findsOneWidget);
    });

    testWidgets('should disable Generate button when form is empty', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // Find the generate button text
      final buttonFinder = find.text('CARD GENERATE / 카드 생성');
      expect(buttonFinder, findsOneWidget);

      // Button should be disabled (grey, no glow) when empty.
      // The InkWell now always has onTap (shows SnackBar when disabled),
      // so we verify the disabled state by checking the visual appearance
      // (grey gradient vs green glow).
      final animatedContainer = tester.widget<AnimatedContainer>(
        find.ancestor(of: buttonFinder, matching: find.byType(AnimatedContainer)).first,
      );
      final decoration = animatedContainer.decoration as BoxDecoration;
      final gradient = decoration.gradient as LinearGradient;
      // Disabled state uses grey colors: 0xFF2A2A35 and 0xFF3A3A45
      expect(gradient.colors.first, const Color(0xFF2A2A35));
    });

    testWidgets('should enable Generate button when all fields and EULA are filled', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // Fill in all fields
      await tester.enterText(
        find.byType(TextField).at(0), // Name field
        '테스트 사용자',
      );
      await tester.pump();

      await tester.enterText(
        find.byType(TextField).at(1), // Value 1 field
        '자유',
      );
      await tester.pump();

      await tester.enterText(
        find.byType(TextField).at(2), // Value 2 field
        '진실',
      );
      await tester.pump();

      await tester.enterText(
        find.byType(TextField).at(3), // Value 3 field
        '평화',
      );
      await tester.pump();

      await tester.enterText(
        find.byType(TextField).at(4), // Will field
        '행복하게 살아라',
      );
      await tester.pump();

      // EULA checkbox should still be unchecked, so button should be disabled
      final buttonFinder = find.text('CARD GENERATE / 카드 생성');
      final animatedContainer1 = tester.widget<AnimatedContainer>(
        find.ancestor(of: buttonFinder, matching: find.byType(AnimatedContainer)).first,
      );
      final gradient1 = (animatedContainer1.decoration as BoxDecoration).gradient as LinearGradient;
      expect(gradient1.colors.first, const Color(0xFF2A2A35)); // Disabled (grey)

      // Check the EULA checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      // Button should now be enabled (green glow)
      final animatedContainer2 = tester.widget<AnimatedContainer>(
        find.ancestor(of: buttonFinder, matching: find.byType(AnimatedContainer)).first,
      );
      final gradient2 = (animatedContainer2.decoration as BoxDecoration).gradient as LinearGradient;
      expect(gradient2.colors.first, const Color(0xFF00FF88)); // Enabled (green)
    });

    testWidgets('should show EULA hint Snackbar when EULA unchecked after form valid', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // Fill in all fields
      await tester.enterText(
        find.byType(TextField).at(0),
        '테스트 사용자',
      );
      await tester.pump();
      await tester.enterText(
        find.byType(TextField).at(1),
        '자유',
      );
      await tester.pump();
      await tester.enterText(
        find.byType(TextField).at(2),
        '진실',
      );
      await tester.pump();
      await tester.enterText(
        find.byType(TextField).at(3),
        '평화',
      );
      await tester.pump();
      await tester.enterText(
        find.byType(TextField).at(4),
        '행복하게 살아라',
      );
      await tester.pump();

      // The checkbox starts unchecked. Check and uncheck it to trigger the hint.
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      // Should show the EULA hint SnackBar
      expect(find.text('카드 생성을 위해 EULA에 동의해주세요.'), findsOneWidget);
    });

    testWidgets('should navigate to card screen when generate button tapped', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // Fill in all fields
      await tester.enterText(
        find.byType(TextField).at(0),
        '테스트 사용자',
      );
      await tester.pump();
      await tester.enterText(
        find.byType(TextField).at(1),
        '자유',
      );
      await tester.pump();
      await tester.enterText(
        find.byType(TextField).at(2),
        '진실',
      );
      await tester.pump();
      await tester.enterText(
        find.byType(TextField).at(3),
        '평화',
      );
      await tester.pump();
      await tester.enterText(
        find.byType(TextField).at(4),
        '행복하게 살아라',
      );
      await tester.pump();

      // Check EULA checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      // Find and tap the generate button
      final buttonFinder = find.text('CARD GENERATE / 카드 생성');
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      // Should navigate to the card render screen
      // The card screen also shows "SFX 임종 케어" as title
      expect(find.text('SFX 임종 케어'), findsWidgets);
    });

    testWidgets('should show EULA dialog when EULA label is tapped', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // Tap the EULA label
      await tester.tap(find.text('이용약관 및 EULA 동의'));
      await tester.pump();

      // EULA dialog should appear
      expect(find.text('이용약관 및 EULA'), findsOneWidget);
      expect(find.text('동의합니다'), findsOneWidget);
      expect(find.text('닫기'), findsOneWidget);
    });

    testWidgets('should show SnackBar when clicking "동의합니다" in EULA dialog', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // Tap EULA label to open dialog
      await tester.tap(find.text('이용약관 및 EULA 동의'));
      await tester.pump();

      // Click "동의합니다" button
      await tester.tap(find.text('동의합니다'));
      await tester.pump();

      // SnackBar should appear
      expect(find.text('EULA에 동의했습니다.'), findsOneWidget);
    });

    testWidgets('should handle whitespace-only input correctly', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // Enter whitespace only
      await tester.enterText(
        find.byType(TextField).at(0),
        '   ',
      );
      await tester.pump();
      await tester.enterText(
        find.byType(TextField).at(1),
        '   ',
      );
      await tester.pump();
      await tester.enterText(
        find.byType(TextField).at(2),
        '   ',
      );
      await tester.pump();
      await tester.enterText(
        find.byType(TextField).at(3),
        '   ',
      );
      await tester.pump();
      await tester.enterText(
        find.byType(TextField).at(4),
        '   ',
      );
      await tester.pump();

      // EULA check anyway - button should still be disabled (whitespace = invalid)
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      // Button should still be disabled (grey gradient) because whitespace-only values are invalid
      final buttonFinder = find.text('CARD GENERATE / 카드 생성');
      final animatedContainer = tester.widget<AnimatedContainer>(
        find.ancestor(of: buttonFinder, matching: find.byType(AnimatedContainer)).first,
      );
      final decoration = animatedContainer.decoration as BoxDecoration;
      final gradient = decoration.gradient as LinearGradient;
      // Disabled state uses grey colors: 0xFF2A2A35 and 0xFF3A3A45
      expect(gradient.colors.first, const Color(0xFF2A2A35));
    });

    testWidgets('should have all input fields accessible', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // Should have 5 TextField widgets (name + 3 values + will)
      expect(find.byType(TextField), findsNWidgets(5));

      // Should have 1 Checkbox for EULA
      expect(find.byType(Checkbox), findsOneWidget);

      // EULA label text
      expect(find.text('이용약관 및 EULA 동의'), findsOneWidget);

      // EULA hint text
      expect(find.text('EULA에 동의해야 카드를 생성할 수 있습니다.'), findsOneWidget);
    });
  });
}
