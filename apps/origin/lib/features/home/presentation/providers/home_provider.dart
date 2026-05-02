import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origin/core/services/preference_service.dart';

/// Async provider that initializes [PreferenceService] and returns the
/// current user's ID.
final homeProvider = FutureProvider<String>((ref) async {
  final service = await globalPreferenceService.init();
  return service.userId;
});
