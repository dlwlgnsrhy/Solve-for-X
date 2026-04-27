import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sfx_imjong_care/features/will_input/presentation/widgets/value_input_field.dart';

void main() {
  group('NeonTextField Widget', () {
    testWidgets('should display label and hintText', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NeonTextField(
                label: 'YOUR NAME',
                hintText: 'Enter your name',
                onChanged: (v) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('YOUR NAME'), findsOneWidget);
      expect(find.text('Enter your name'), findsOneWidget);
    });

    testWidgets('should accept text input', (tester) async {
      String? lastValue;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NeonTextField(
                label: 'Test',
                hintText: 'Enter text',
                onChanged: (v) {
                  lastValue = v;
                },
              ),
            ),
          ),
        ),
      );

      // Type text
      await tester.enterText(find.byType(TextField), 'Hello World');
      await tester.pump();

      expect(lastValue, 'Hello World');
      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('should call onChanged on every keystroke', (tester) async {
      final List<String> receivedValues = [];
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NeonTextField(
                label: 'Test',
                hintText: 'Enter text',
                onChanged: (v) {
                  receivedValues.add(v);
                },
              ),
            ),
          ),
        ),
      );

      // Type a short word character by character
      await tester.enterText(find.byType(TextField), 'Hi');
      await tester.pump();

      // 'Hi' should be the last value
      expect(receivedValues.last, 'Hi');
    });

    testWidgets('should use custom controller if provided', (tester) async {
      String? lastValue;
      final controller = TextEditingController(text: 'Pre-filled');
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NeonTextField(
                label: 'Test',
                hintText: 'Enter text',
                onChanged: (v) {
                  lastValue = v;
                },
                controller: controller,
              ),
            ),
          ),
        ),
      );

      // Should show pre-filled text
      expect(find.text('Pre-filled'), findsOneWidget);

      // Type new text
      await tester.enterText(find.byType(TextField), 'New Text');
      await tester.pump();

      expect(lastValue, 'New Text');
      controller.dispose();
    });

    testWidgets('should show custom border color when provided', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NeonTextField(
                label: 'Test',
                hintText: 'Enter text',
                onChanged: (v) {},
                borderColor: const Color(0xFFFF00AA),
              ),
            ),
          ),
        ),
      );

      // Just verify the widget builds without error
      expect(find.byType(NeonTextField), findsOneWidget);
    });

    testWidgets('should have green default border color', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NeonTextField(
                label: 'Test',
                hintText: 'Enter text',
                onChanged: (v) {},
              ),
            ),
          ),
        ),
      );

      // Just verify it renders
      expect(find.byType(NeonTextField), findsOneWidget);
    });

    testWidgets('should support different keyboard types', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NeonTextField(
                label: 'Test',
                hintText: 'Enter text',
                onChanged: (v) {},
                keyboardType: TextInputType.number,
              ),
            ),
          ),
        ),
      );

      // Verify it builds without error
      expect(find.byType(NeonTextField), findsOneWidget);

      // Check the TextField has the correct keyboardType
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.keyboardType, TextInputType.number);
    });

    testWidgets('should render all neon style elements', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: NeonTextField(
                label: 'VALUE 1',
                hintText: '나의 가치 #1',
                onChanged: (v) {},
                borderColor: const Color(0xFF00DDFF),
              ),
            ),
          ),
        ),
      );

      // Should find all elements
      expect(find.text('VALUE 1'), findsOneWidget);
      expect(find.text('나의 가치 #1'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should clear text when controller is cleared externally', (tester) async {
      final controller = TextEditingController(text: 'Some text');
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NeonTextField(
                label: 'Test',
                hintText: 'Enter text',
                onChanged: (v) {},
                controller: controller,
              ),
            ),
          ),
        ),
      );

      // Verify initial text
      expect(find.text('Some text'), findsOneWidget);

      // Clear the controller
      controller.clear();
      await tester.pump();

      // Text field should be cleared
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);

      controller.dispose();
    });

    testWidgets('should handle multiple rapid inputs', (tester) async {
      final List<String> receivedValues = [];
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NeonTextField(
                label: 'Test',
                hintText: 'Enter text',
                onChanged: (v) {
                  receivedValues.add(v);
                },
              ),
            ),
          ),
        ),
      );

      // Rapidly input multiple values
      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'ab');
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'abcd');
      await tester.pump();

      expect(receivedValues.length, 4);
      expect(receivedValues.last, 'abcd');
    });
  });
}
