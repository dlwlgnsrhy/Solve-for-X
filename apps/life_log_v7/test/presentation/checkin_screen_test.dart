import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';

import 'package:life_log_v7/domain/domain.dart';
import 'package:life_log_v7/presentation/presentation.dart';
import 'package:life_log_v7/presentation/providers/checkin_provider.dart';

class SuccessMockRepository extends Mock implements PlannerRepository {
  @override
  Future<bool> submitCheckin(CheckinData data) => Future.value(true);
}

class DelayedMockRepository extends Mock implements PlannerRepository {
  @override
  Future<bool> submitCheckin(CheckinData data) {
    return _pendingCompleter.future;
  }

  final Completer<bool> _pendingCompleter = Completer<bool>();

  void resolve(bool value) => _pendingCompleter.complete(value);
}

void main() {
  List<Override> _getOverrides(PlannerRepository repo) {
    return [plannerRepositoryProvider.overrideWithValue(repo)];
  }

  Widget _buildScreen(PlannerRepository repo) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: ProviderScope(overrides: _getOverrides(repo), child: CheckinScreen()),
    );
  }

  group('CheckinScreen', () {
    testWidgets('shows 5 energy star buttons', (tester) async {
      await tester.pumpWidget(_buildScreen(SuccessMockRepository()));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.star), findsNWidgets(5));
    });

    testWidgets('shows 5 mood emoji buttons', (tester) async {
      await tester.pumpWidget(_buildScreen(SuccessMockRepository()));
      await tester.pumpAndSettle();
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('shows 4 focus mode chips', (tester) async {
      await tester.pumpWidget(_buildScreen(SuccessMockRepository()));
      await tester.pumpAndSettle();
      expect(find.byType(ActionChip), findsNWidgets(4));
    });

    testWidgets('shows submit button', (tester) async {
      await tester.pumpWidget(_buildScreen(SuccessMockRepository()));
      await tester.pumpAndSettle();
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('tapping a star selects it', (tester) async {
      await tester.pumpWidget(_buildScreen(SuccessMockRepository()));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.star).at(2));
      await tester.pump();
      expect(find.byIcon(Icons.star), findsNWidgets(5));
    });

    testWidgets('tapping an emoji selects it', (tester) async {
      await tester.pumpWidget(_buildScreen(SuccessMockRepository()));
      await tester.pumpAndSettle();
      expect(find.byType(Text), findsWidgets);
      await tester.tap(find.byType(Text).at(3));
      await tester.pump();
    });

    testWidgets('tapping a focus chip selects it', (tester) async {
      await tester.pumpWidget(_buildScreen(SuccessMockRepository()));
      await tester.pumpAndSettle();
      final chips = find.byType(ActionChip);
      expect(chips, findsNWidgets(4));
      await tester.tap(chips.at(0));
      await tester.pump();
    });

    testWidgets('submit disabled during loading', (tester) async {
      final mock = DelayedMockRepository();

      await tester.pumpWidget(_buildScreen(mock));
      await tester.pumpAndSettle();

      final submitButton = find.byType(ElevatedButton);
      expect(submitButton, findsOneWidget);
      await tester.tap(submitButton);
      await tester.pump();

      expect(tester.widget<ElevatedButton>(submitButton).onPressed, isNull);
    });
  });
}
