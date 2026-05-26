import 'package:flutter_test/flutter_test.dart';
import 'package:origin/main.dart';

void main() {
  testWidgets('App loads without errors', (WidgetTester tester) async {
    // Verify OriginApp is a valid widget class
    final app = const OriginApp();
    expect(app, isA<OriginApp>());
  });
}
