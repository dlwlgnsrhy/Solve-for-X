import 'package:flutter_test/flutter_test.dart';

import 'package:origin/core/services/review_service.dart';

void main() {
  group('ReviewService', () {
    test('shouldPromptReview returns true when no prior prompt', () {
      final service = ReviewService();
      expect(service.shouldPromptReview(), isTrue);
    });

    test('can request review', () async {
      final service = ReviewService();
      // On a real device, this may request a review.
      // On device farm / web, it's a no-op.
      await service.requestReview();
    });
  });
}
