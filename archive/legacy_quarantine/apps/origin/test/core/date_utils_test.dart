import 'package:flutter_test/flutter_test.dart';

import 'package:origin/core/utils/date_utils.dart';

void main() {
  group('DateUtils', () {
    test('iso8601Now returns valid ISO 8601 string', () {
      final now = DateUtils.iso8601Now();
      expect(now, isNotEmpty);
      final parsed = DateTime.parse(now);
      expect(parsed, isNotNull);
    });

    test('formatTimestamp returns human readable string', () {
      final timestamp = '2026-04-30T12:00:00.000';
      final formatted = DateUtils.formatTimestamp(timestamp);
      expect(formatted, isNotEmpty);
      expect(formatted, isNot(equals('Invalid date')));
    });

    test('formatTimestamp returns Invalid date for bad input', () {
      final formatted = DateUtils.formatTimestamp('not-a-date');
      expect(formatted, equals('Invalid date'));
    });

    test('daysSince calculates correct days', () {
      final pastDate = DateUtils.iso8601Now();
      final days = DateUtils.daysSince(pastDate);
      expect(days, greaterThanOrEqualTo(0));
    });

    test('daysSince returns -1 for invalid date', () {
      final days = DateUtils.daysSince('not-a-date');
      expect(days, equals(-1));
    });
  });
}
