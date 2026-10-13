import 'package:flutter/foundation.dart';

/// Holds the user's three preferences so the Profile page and the
/// Preferences page always show the same values.
///
/// TODO: load these from your backend / local storage on login, and save
/// them whenever they change (add a listener on each notifier).
class PreferencesStore {
  static final currency = ValueNotifier<String>('MYR');
  static final budgetStyle = ValueNotifier<String>('50 / 30 / 20 Rule');
  static final role = ValueNotifier<String>('Student');
}
