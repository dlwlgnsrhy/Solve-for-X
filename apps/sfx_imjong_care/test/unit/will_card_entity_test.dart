import 'package:flutter_test/flutter_test.dart';
import 'package:sfx_imjong_care/features/will_input/domain/entities/will_card.dart';

void main() {
  group('WillCard', () {
    group('constructor', () {
      test('should create instance with valid data', () {
        const card = WillCard(
          name: '테스트 사용자',
          values: ['자유', '진실', '평화'],
          will: '행복하게 살아라',
        );
        expect(card.name, '테스트 사용자');
        expect(card.values, hasLength(3));
        expect(card.values[0], '자유');
        expect(card.values[1], '진실');
        expect(card.values[2], '평화');
        expect(card.will, '행복하게 살아라');
      });

      test('should create instance with empty values', () {
        const card = WillCard(
          name: '',
          values: ['', '', ''],
          will: '',
        );
        expect(card.name, isEmpty);
        expect(card.values, hasLength(3));
        expect(card.will, isEmpty);
      });
    });

    group('copyWith', () {
      test('should create new instance with updated name', () {
        const card = WillCard(
          name: '기존이름',
          values: ['자유', '진실', '평화'],
          will: '기존유언',
        );
        final newCard = card.copyWith(name: '새이름');
        expect(newCard.name, '새이름');
        expect(newCard.values, card.values);
        expect(newCard.will, card.will);
      });

      test('should create new instance with updated will', () {
        const card = WillCard(
          name: '테스트',
          values: ['자유', '진실', '평화'],
          will: '기존유언',
        );
        final newCard = card.copyWith(will: '새유언');
        expect(newCard.name, card.name);
        expect(newCard.values, card.values);
        expect(newCard.will, '새유언');
      });

      test('should create new instance with updated values', () {
        const card = WillCard(
          name: '테스트',
          values: ['자유', '진실', '평화'],
          will: '유언',
        );
        final newCard = card.copyWith(values: ['새가치1', '새가치2', '새가치3']);
        expect(newCard.name, card.name);
        expect(newCard.values[0], '새가치1');
        expect(newCard.values[1], '새가치2');
        expect(newCard.values[2], '새가치3');
        expect(newCard.will, card.will);
      });

      test('should not mutate original instance', () {
        const card = WillCard(
          name: '기존이름',
          values: ['자유', '진실', '평화'],
          will: '기존유언',
        );
        card.copyWith(name: '새이름');
        expect(card.name, '기존이름');
      });
    });

    group('equality', () {
      test('should be equal to another WillCard with same data', () {
        const card1 = WillCard(
          name: '테스트',
          values: ['자유', '진실', '평화'],
          will: '행복하게 살아라',
        );
        const card2 = WillCard(
          name: '테스트',
          values: ['자유', '진실', '평화'],
          will: '행복하게 살아라',
        );
        expect(card1, equals(card2));
      });

      test('should not be equal if name is different', () {
        const card1 = WillCard(
          name: '테스트1',
          values: ['자유', '진실', '평화'],
          will: '유언',
        );
        const card2 = WillCard(
          name: '테스트2',
          values: ['자유', '진실', '평화'],
          will: '유언',
        );
        expect(card1, isNot(equals(card2)));
      });

      test('should not be equal if values are different', () {
        const card1 = WillCard(
          name: '테스트',
          values: ['자유', '진실', '평화'],
          will: '유언',
        );
        const card2 = WillCard(
          name: '테스트',
          values: ['자유', '진실', '행복'],
          will: '유언',
        );
        expect(card1, isNot(equals(card2)));
      });

      test('should not be equal if will is different', () {
        const card1 = WillCard(
          name: '테스트',
          values: ['자유', '진실', '평화'],
          will: '유언1',
        );
        const card2 = WillCard(
          name: '테스트',
          values: ['자유', '진실', '평화'],
          will: '유언2',
        );
        expect(card1, isNot(equals(card2)));
      });

      test('should be equal with same values in different order', () {
        // Actually this tests if order matters - it should NOT be equal
        const card1 = WillCard(
          name: '테스트',
          values: ['자유', '진실', '평화'],
          will: '유언',
        );
        const card2 = WillCard(
          name: '테스트',
          values: ['평화', '진실', '자유'],
          will: '유언',
        );
        expect(card1, isNot(equals(card2)));
      });

      test('should be identical to itself', () {
        const card = WillCard(
          name: '테스트',
          values: ['자유', '진실', '평화'],
          will: '유언',
        );
        expect(card, equals(card));
      });
    });

    group('serialization', () {
      test('should convert to map correctly', () {
        const card = WillCard(
          name: '테스트 사용자',
          values: ['자유', '진실', '평화'],
          will: '행복하게 살아라',
        );
        final map = card.toMap();
        expect(map['name'], '테스트 사용자');
        expect(map['values'], ['자유', '진실', '평화']);
        expect(map['will'], '행복하게 살아라');
      });

      test('should create from map correctly', () {
        final map = {
          'name': '테스트 사용자',
          'values': ['자유', '진실', '평화'],
          'will': '행복하게 살아라',
        };
        final card = WillCard.fromMap(map);
        expect(card.name, '테스트 사용자');
        expect(card.values, hasLength(3));
        expect(card.values[0], '자유');
        expect(card.values[1], '진실');
        expect(card.values[2], '평화');
        expect(card.will, '행복하게 살아라');
      });

      test('should round-trip through map correctly', () {
        const original = WillCard(
          name: '테스트',
          values: ['가치1', '가치2', '가치3'],
          will: '유언',
        );
        final map = original.toMap();
        final restored = WillCard.fromMap(map);
        expect(restored, equals(original));
      });

      test('should handle empty string values in map', () {
        final map = {
          'name': '',
          'values': ['', '', ''],
          'will': '',
        };
        final card = WillCard.fromMap(map);
        expect(card.name, isEmpty);
        expect(card.values, hasLength(3));
        expect(card.will, isEmpty);
      });
    });

    group('toString', () {
      test('should return readable string representation', () {
        const card = WillCard(
          name: '테스트',
          values: ['자유', '진실', '평화'],
          will: '유언',
        );
        final str = card.toString();
        expect(str, contains('WillCard'));
        expect(str, contains('테스트'));
        expect(str, contains('자유'));
        expect(str, contains('유언'));
      });
    });

    group('hashCode', () {
      test('should return same hashCode for equal cards', () {
        const card1 = WillCard(
          name: '테스트',
          values: ['자유', '진실', '평화'],
          will: '유언',
        );
        const card2 = WillCard(
          name: '테스트',
          values: ['자유', '진실', '평화'],
          will: '유언',
        );
        expect(card1.hashCode, equals(card2.hashCode));
      });

      test('should return different hashCode for different cards', () {
        const card1 = WillCard(
          name: '테스트1',
          values: ['자유', '진실', '평화'],
          will: '유언',
        );
        const card2 = WillCard(
          name: '테스트2',
          values: ['자유', '진실', '평화'],
          will: '유언',
        );
        expect(card1.hashCode, isNot(equals(card2.hashCode)));
      });

      test('should be consistent for same card', () {
        const card = WillCard(
          name: '테스트',
          values: ['자유', '진실', '평화'],
          will: '유언',
        );
        expect(card.hashCode, equals(card.hashCode));
      });
    });

    group('edge cases', () {
      test('should handle long name', () {
        final longName = 'a' * 1000;
        final card = WillCard(
          name: longName,
          values: ['가치1', '가치2', '가치3'],
          will: '유언',
        );
        expect(card.name, longName);
        expect(card.name.length, 1000);
      });

      test('should handle long values', () {
        final longValue = '가' * 100;
        final card = WillCard(
          name: '테스트',
          values: [longValue, longValue, longValue],
          will: '유언',
        );
        expect(card.values[0].length, 100);
      });

      test('should handle unicode characters in name', () {
        const card = WillCard(
          name: '김철수 🎯',
          values: ['자유', '진실', '평화'],
          will: '행복하게 살아라 💫',
        );
        expect(card.name, '김철수 🎯');
        expect(card.will, '행복하게 살아라 💫');
      });

      test('should handle special characters in values', () {
        final card = WillCard(
          name: '테스트',
          values: ['A > B', 'X & Y', 'C + D'],
          will: '유언! @ # \$',
        );
        expect(card.values[0], 'A > B');
        expect(card.values[1], 'X & Y');
        expect(card.values[2], 'C + D');
        expect(card.will, '유언! @ # \$');
      });
    });
  });
}
