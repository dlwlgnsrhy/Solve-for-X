/// Utility methods for DateTime and timestamp handling.
class DateUtils {
  DateUtils._();

  /// Returns the current date/time as an ISO 8601 formatted string.
  static String iso8601Now() {
    return DateTime.now().toIso8601String();
  }

  /// Converts an ISO 8601 timestamp string to a human-readable format.
  /// Returns 'Invalid date' if parsing fails.
  static String formatTimestamp(String timestamp) {
    try {
      final DateTime date = DateTime.parse(timestamp);
      final DateTime now = DateTime.now();

      final String day = _pad(date.day);
      final String month = _monthAbbr(date.month);
      final String year = date.year.toString();
      final String hour = _pad(date.hour);
      final String min = _pad(date.minute);

      final int diff = now.difference(date).inDays;
      if (diff == 0) return 'Today $hour:$min';
      if (diff == 1) return 'Yesterday $hour:$min';
      if (diff < 7) return '$diff days ago';
      return '$day $month $year $hour:$min';
    } catch (_) {
      return 'Invalid date';
    }
  }

  /// Calculates the number of days between the given ISO 8601 date string and now.
  static int daysSince(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return DateTime.now().difference(date).inDays;
    } catch (_) {
      return -1;
    }
  }

  static String _pad(int value) {
    return value.toString().padLeft(2, '0');
  }

  static String _monthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
