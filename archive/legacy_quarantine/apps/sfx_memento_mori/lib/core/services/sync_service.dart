import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

/// Service for synchronizing local Memento Mori data with the SFX Basecamp unified DB.
class SyncService {
  static const String _syncEndpoint = 'https://brand-web-gamma.vercel.app/api/memento-mori/sync';

  /// Synchronizes birth date and target age with the central PostgreSQL backend.
  /// Upholds the robust, offline-resilient local-first principle (fails silently without breaking UX).
  Future<bool> syncProfile({
    required DateTime birthDate,
    required int targetAge,
    required bool eulaAccepted,
  }) async {
    final Map<String, dynamic> payload = {
      'birth_date': birthDate.toIso8601String(),
      'target_age': targetAge,
      'eula_accepted': eulaAccepted,
      'device_timestamp': DateTime.now().toIso8601String(),
    };

    try {
      developer.log('Initiating profile synchronization with Basecamp DB...', name: 'SyncService');
      final response = await http.post(
        Uri.parse(_syncEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        developer.log('Profile successfully synchronized with central Basecamp PostgreSQL database!', name: 'SyncService');
        return true;
      } else {
        developer.log(
          'Synchronization rejected by server (Status Code: ${response.statusCode}). Payload: ${response.body}',
          name: 'SyncService',
          level: 900,
        );
        return false;
      }
    } catch (e, stackTrace) {
      // Robust offline fallback: Fail silently and log locally.
      developer.log(
        'Offline fallback triggered. Data preserved locally in SharedPreferences. Exception: $e',
        name: 'SyncService',
        error: e,
        stackTrace: stackTrace,
        level: 500,
      );
      return false;
    }
  }
}
