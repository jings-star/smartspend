import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// A short, friendly error message the screens can show as it is.
class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}

/// Talks to Firebase Authentication (the "ID card office") and saves each
/// user's profile in Firestore (users / {user id}).
/// The screens call these same functions as before, so they do not change.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Accounts made before the profile existed get one now.
      final user = credential.user;
      if (user != null) await _saveProfile(user);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyMessage(e));
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) return;

      // Save the name on the new account.
      await user.updateDisplayName(name);

      // Save the profile in Firestore (your USERS table).
      await _saveProfile(user, name: name);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyMessage(e));
    }
  }

  Future<void> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO: needs the google_sign_in package (we can add it later).
  }

  Future<void> sendPasswordReset({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyMessage(e));
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// Creates  users / {uid}  with the user's details, only if it does not
  /// exist yet. If saving fails, login still works (we just print the reason).
  Future<void> _saveProfile(User user, {String? name}) async {
    try {
      final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);

      final snapshot = await ref.get();
      if (snapshot.exists) return; // already saved before

      await ref.set({
        'userID': user.uid,
        'name': name ?? user.displayName ?? '',
        'email': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Could not save profile: $e');
    }
  }

  /// Turns Firebase's error codes into normal sentences.
  String _friendlyMessage(FirebaseAuthException e) {
    // The real reason is printed in the Debug Console to help you fix problems.
    debugPrint('Firebase Auth error code: ${e.code}');

    switch (e.code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Wrong email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'too-many-requests':
        return 'Too many tries. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}