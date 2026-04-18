import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:life_log_v8/domain/domain.dart';
import 'package:life_log_v8/main.dart';
import 'package:life_log_v8/presentation/providers/checkin_provider.dart';

class _MockRepository extends Mock implements PlannerRepository {}

void main() {
  testWidgets('CheckinScreen loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          plannerRepositoryProvider.overrideWithValue(_MockRepository()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Today's Check-in"), findsOneWidget);
  });
}
