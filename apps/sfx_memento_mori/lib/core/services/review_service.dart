import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:sfx_memento_mori/core/storage/preference_service.dart';
import 'package:sfx_memento_mori/features/onboarding/presentation/providers/onboarding_provider.dart';

/// Service for managing in-app review prompts.
class ReviewService {
  final InAppReview _inAppReview = InAppReview.instance;
  final PreferenceService _prefs;

  ReviewService(this._prefs);

  /// Checks if the user should be prompted for a review.
  /// Conditions:
  /// - First launch was 7+ days ago
  /// - Review has not been prompted yet
  bool shouldPromptReview() {
    if (_prefs.reviewPrompted) return false;

    final firstLaunch = _prefs.firstLaunchDate;
    if (firstLaunch == null) return false;

    final daysSinceFirstLaunch =
        DateTime.now().difference(firstLaunch).inDays;
    return daysSinceFirstLaunch >= 7;
  }

  /// Prompts the user for an in-app review if available.
  Future<void> promptReview() async {
    if (_prefs.reviewPrompted) return;

    final isAvailable = await _inAppReview.isAvailable();
    if (isAvailable) {
      await _inAppReview.requestReview();
    }

    await _prefs.setReviewPrompted(true);
  }
}

/// Provider for the review service.
final reviewServiceProvider = Provider<ReviewService>((ref) {
  final prefs = ref.watch(preferenceServiceProvider);
  return ReviewService(prefs);
});
