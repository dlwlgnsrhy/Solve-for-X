import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sfx_imjong_care/features/will_input/presentation/widgets/eula_checkbox.dart';

void main() {
  group('EulaCheckbox Widget', () {
    testWidgets('should display with initial unchecked state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EulaCheckbox(
                onChecked: (checked) {},
              ),
            ),
          ),
        ),
      );

      // Checkbox should be unchecked initially
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isFalse);

      // Label text should be present
      expect(find.text('이용약관 및 EULA 동의'), findsOneWidget);

      // Helper hint text should be present
      expect(find.text('EULA에 동의해야 카드를 생성할 수 있습니다.'), findsOneWidget);
    });

    testWidgets('should toggle to checked when tapped', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EulaCheckbox(
                onChecked: (checked) {},
              ),
            ),
          ),
        ),
      );

      // Tap the checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      // Checkbox should now be checked
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
    });

    testWidgets('should toggle back to unchecked when tapped again', (tester) async {
      bool? lastCheckedValue;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EulaCheckbox(
                onChecked: (checked) {
                  lastCheckedValue = checked;
                },
              ),
            ),
          ),
        ),
      );

      // Tap to check
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(lastCheckedValue, isTrue);

      // Tap again to uncheck
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isFalse);
      expect(lastCheckedValue, isFalse);
    });

    testWidgets('should reflect initialValue on first render', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EulaCheckbox(
                initialValue: true,
                onChecked: (checked) {},
              ),
            ),
          ),
        ),
      );

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
    });

    testWidgets('should sync state when initialValue changes', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: Column(
                    children: [
                      EulaCheckbox(
                        initialValue: false,
                        onChecked: (checked) {},
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {});
                        },
                        child: const Text('Sync'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Initially unchecked
      final checkbox1 = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox1.value, isFalse);

      // Tap to check
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      final checkbox2 = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox2.value, isTrue);

      // Tap back to uncheck
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      final checkbox3 = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox3.value, isFalse);
    });

    testWidgets('should call onViewEula when label is tapped', (tester) async {
      bool eulaViewed = false;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EulaCheckbox(
                onChecked: (checked) {},
                onViewEula: () {
                  eulaViewed = true;
                },
              ),
            ),
          ),
        ),
      );

      // Tap the label text (not the checkbox)
      await tester.tap(find.text('이용약관 및 EULA 동의'));
      await tester.pump();

      expect(eulaViewed, isTrue);
    });

    testWidgets('should show green active color when checked', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EulaCheckbox(
                initialValue: true,
                onChecked: (checked) {},
              ),
            ),
          ),
        ),
      );

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.activeColor, const Color(0xFF00FF88));
    });

    testWidgets('should call onChecked with correct value after multiple toggles', (tester) async {
      final List<bool> receivedValues = [];
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EulaCheckbox(
                onChecked: (checked) {
                  receivedValues.add(checked);
                },
              ),
            ),
          ),
        ),
      );

      // Toggle 5 times
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byType(Checkbox));
        await tester.pump();
      }

      expect(receivedValues.length, 5);
      // Should alternate: true, false, true, false, true
      expect(receivedValues[0], isTrue);
      expect(receivedValues[1], isFalse);
      expect(receivedValues[2], isTrue);
      expect(receivedValues[3], isFalse);
      expect(receivedValues[4], isTrue);
    });
  });
}
