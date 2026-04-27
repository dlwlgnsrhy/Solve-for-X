import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sfx_legacy_vault/features/auth/data/firebase_auth_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuthService>(
  (ref) => FirebaseAuthService(),
);

final authStateProvider = StreamProvider<User?>((ref) {
  final service = ref.watch(firebaseAuthProvider);
  return service.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final service = ref.watch(firebaseAuthProvider);
  return service.currentUser;
});
