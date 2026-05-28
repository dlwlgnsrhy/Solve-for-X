import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/will_card.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize and Sign in Anonymously
  Future<UserCredential?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      debugPrint("Firebase Auth: Signed in anonymously. UID: ${userCredential.user?.uid}");
      return userCredential;
    } catch (e) {
      debugPrint("Firebase Auth Error (Safeguarded in debug mode): $e");
      return null;
    }
  }

  // Get current user UID
  String? get currentUid {
    final realUid = _auth.currentUser?.uid;
    if (realUid == null && kDebugMode) {
      // Return safe fallback mock UID to prevent app crash when Firebase Auth encounters simulator keychain bug
      return "local-mock-uid-1234567890";
    }
    return realUid;
  }

  // Upload Will Postcard to Cloud Firestore
  Future<bool> uploadWill(WillCardModel will) async {
    try {
      final uid = currentUid;
      if (uid == null) {
        debugPrint("Firebase Firestore: Upload failed due to null Auth session.");
        return false;
      }

      await _firestore.collection('wills').doc(will.id).set({
        ...will.toMap(),
        'userId': uid,
        'uploadedAt': FieldValue.serverTimestamp(),
      });
      debugPrint("Firebase Firestore: Will uploaded successfully. ID: ${will.id}");
      return true;
    } catch (e) {
      debugPrint("Firebase Firestore Upload Error: $e");
      return false;
    }
  }

  // Stream of public wills for the Empathy Feed (Real-time sync)
  Stream<List<WillCardModel>> getPublicWillsStream() {
    return _firestore
        .collection('wills')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return WillCardModel.fromMap(data);
      }).toList();
    });
  }

  // Like a Will card incrementor
  Future<void> likeWill(String willId) async {
    try {
      await _firestore.collection('wills').doc(willId).update({
        'likes': FieldValue.increment(1),
      });
      debugPrint("Firebase Firestore: Liked will $willId");
    } catch (e) {
      debugPrint("Firebase Firestore Like Error: $e");
    }
  }
}
