/// Utility functions for deadline and date calculations.
abstract final class DateUtils {
  DateUtils._();

  /// Returns the number of hours remaining until the deadline.
  static int hoursUntilDeadline(DateTime lastActive, int deadlineDays) {
    final deadline = lastActive.add(Duration(days: deadlineDays));
    final now = DateTime.now();
    if (now.isAfter(deadline)) {
      return 0;
    }
    return deadline.difference(now).inHours;
  }

  /// Returns the number of days remaining (whole days).
  static int daysRemaining(DateTime lastActive, int deadlineDays) {
    final deadline = lastActive.add(Duration(days: deadlineDays));
    final now = DateTime.now();
    if (now.isAfter(deadline)) {
      return 0;
    }
    return deadline.difference(now).inDays;
  }

  /// Returns percentage of deadline elapsed (0.0 to 1.0).
  static double deadlineProgress(DateTime lastActive, int deadlineDays) {
    final deadline = lastActive.add(Duration(days: deadlineDays));
    final totalDuration = deadline.difference(lastActive).inMilliseconds;
    final elapsed = DateTime.now().difference(lastActive).inMilliseconds;
    if (elapsed <= 0) return 0.0;
    if (elapsed >= totalDuration) return 1.0;
    return elapsed / totalDuration;
  }

  /// Formats a timestamp as a readable string.
  static String formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'N/A';
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return timestamp.toString().split('.').first;
  }

  /// Returns countdown components for a vault deadline.
  static Map<String, int> countdownComponents(DateTime lastActive, int deadlineDays) {
    final deadline = lastActive.add(Duration(days: deadlineDays));
    final now = DateTime.now();
    final remaining = deadline.difference(now);

    if (remaining.isNegative) {
      return {'days': 0, 'hours': 0, 'minutes': 0, 'seconds': 0};
    }

    return {
      'days': remaining.inDays,
      'hours': remaining.inHours % 24,
      'minutes': remaining.inMinutes % 60,
      'seconds': remaining.inSeconds % 60,
    };
  }

  /// Returns total remaining seconds until deadline (clamped to 0).
  static int remainingSeconds(DateTime lastActive, int deadlineDays) {
    final deadline = lastActive.add(Duration(days: deadlineDays));
    final remaining = deadline.difference(DateTime.now()).inSeconds;
    return remaining.clamp(0, 999999999);
  }
}
