import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Shared preferences so the Profile page and Preferences page always match.
class PreferencesStore {
  static final currency = ValueNotifier<String>('MYR');
  static final budgetStyle = ValueNotifier<String>('50 / 30 / 20 Rule');
  static final role = ValueNotifier<String>('Student');
  static final language = ValueNotifier<String>('English');
  static final theme = ValueNotifier<String>('Light'); // Light | Dark | System

  static ThemeMode toThemeMode(String t) => switch (t) {
        'Dark' => ThemeMode.dark,
        'System' => ThemeMode.system,
        _ => ThemeMode.light,
      };

  static DocumentReference<Map<String, dynamic>>? get _doc {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return null; // guest: memory only
    return FirebaseFirestore.instance.collection('users').doc(u.uid);
  }

  /// Call after login (and on app start when already logged in).
  static Future<void> load() async {
    final doc = _doc;
    if (doc == null) return;
    try {
      final data = (await doc.get()).data()?['preferences']
          as Map<String, dynamic>?;
      if (data == null) return;
      currency.value = (data['currency'] as String?) ?? currency.value;
      budgetStyle.value =
          (data['budgetStyle'] as String?) ?? budgetStyle.value;
      role.value = (data['role'] as String?) ?? role.value;
      language.value = (data['language'] as String?) ?? language.value;
      theme.value = (data['theme'] as String?) ?? theme.value;
    } catch (_) {
      // offline: keep current values
    }
  }

  /// Call after changing any value.
  static Future<void> save() async {
    final doc = _doc;
    if (doc == null) return;
    try {
      await doc.set({
        'preferences': {
          'currency': currency.value,
          'budgetStyle': budgetStyle.value,
          'role': role.value,
          'language': language.value,
          'theme': theme.value,
        },
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Call on logout so the next user doesn't see the previous values.
  static void reset() {
    currency.value = 'MYR';
    budgetStyle.value = '50 / 30 / 20 Rule';
    role.value = 'Student';
    language.value = 'English';
    theme.value = 'Light';
  }
}