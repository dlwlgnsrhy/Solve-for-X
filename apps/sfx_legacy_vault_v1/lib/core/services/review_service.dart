import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages in-app review prompts.
///
/// Tracks total ping count across all vaults and prompts for a review
/// after the user creates their first vault and pings 5+ times.
class ReviewServiceNotifier extends Notifier<bool> {
  static const String _pingCountKey = 'total_ping_count';
  static const String _reviewPromptedKey = 'review_prompted';
  static const int kReviewThreshold = 5;

  final InAppReview _inAppReview = InAppReview.instance;

  @override
  bool build() => false; // true means review is ready to be shown

  /// Increment the global ping counter stored in SharedPreferences.
  /// Returns true if the threshold has been reached and review should be shown.
  Future<bool> incrementPingCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_pingCountKey) ?? 0;
    final newCount = currentCount + 1;
    await prefs.setInt(_pingCountKey, newCount);

    final alreadyPrompted = prefs.getBool(_reviewPromptedKey) ?? false;

    if (newCount >= kReviewThreshold && !alreadyPrompted) {
      state = true;
      return true;
    }
    return false;
  }

  /// Mark review as prompted so it won't be shown again.
  Future<void> markReviewPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reviewPromptedKey, true);
    state = false;
  }

  /// Try to show the in-app review dialog.
  Future<void> requestReview() async {
    final available = await _inAppReview.isAvailable();
    if (available) {
      await _inAppReview.requestReview();
    }
    await markReviewPrompted();
  }

  /// Get the current ping count without modifying it.
  Future<int> getPingCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_pingCountKey) ?? 0;
  }

  /// Reset review state (for testing).
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pingCountKey, 0);
    await prefs.setBool(_reviewPromptedKey, false);
    state = false;
  }
}

final reviewServiceProvider = NotifierProvider<ReviewServiceNotifier, bool>(
  ReviewServiceNotifier.new,
);
