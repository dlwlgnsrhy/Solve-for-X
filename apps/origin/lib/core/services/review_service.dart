import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing in-app review prompts.
class ReviewService {
  final InAppReview _inAppReview = InAppReview.instance;
  static const String _keyLastReviewPrompt = 'last_review_prompt';

  SharedPreferences? _prefs;

  /// Initialize the service with SharedPreferences instance.
  Future<ReviewService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  /// Checks if the user should be prompted for a review.
  /// Prompts if at least 3 days have passed since the last prompt.
  bool shouldPromptReview() {
    final lastPromptStr = _prefs?.getString(_keyLastReviewPrompt);
    if (lastPromptStr == null) return true;

    try {
      final lastPrompt = DateTime.parse(lastPromptStr);
      final now = DateTime.now();
      final difference = now.difference(lastPrompt);
      return difference.inDays >= 3;
    } catch (_) {
      return true;
    }
  }

  /// Prompts the user for an in-app review if available.
  Future<void> requestReview() async {
    final available = await _inAppReview.isAvailable();
    if (available) {
      await _inAppReview.requestReview();
    }

    // Record the prompt timestamp
    await _prefs?.setString(_keyLastReviewPrompt, DateTime.now().toIso8601String());
  }
}

/// Async lazy-initialized singleton provider.
final globalReviewService = ReviewService();

/// Provider for the review service.
final reviewServiceProvider = Provider<ReviewService>((ref) {
  return globalReviewService;
});
