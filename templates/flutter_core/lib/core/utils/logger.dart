
import 'dart:developer' as dev;

class AppLogger {
  static void i(String message) => dev.log('[INFO] $message');
  static void e(String message, [Object? error]) => dev.log('[ERROR] $error: $message', error: error);
}
