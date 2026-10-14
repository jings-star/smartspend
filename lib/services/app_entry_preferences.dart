
import 'package:shared_preferences/shared_preferences.dart';

import 'guest_mode.dart';

class AppEntryPreferences {
  static const String _choiceKey = 'smartspend_entry_choice';

  static const String guestChoice = 'guest';
  static const String accountChoice = 'account';

  static String? _choice;

  static String? get choice => _choice;

  static bool get isGuest => _choice == guestChoice;

  static bool get hasChosenEntry => _choice != null;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    _choice = prefs.getString(_choiceKey);

    // Restore the guest-mode state when the app restarts.
    GuestMode.isGuest.value = isGuest;
  }

  static Future<void> chooseGuest() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_choiceKey, guestChoice);
    _choice = guestChoice;

    GuestMode.isGuest.value = true;
  }

  static Future<void> chooseAccount() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_choiceKey, accountChoice);
    _choice = accountChoice;

    GuestMode.isGuest.value = false;
  }

  static Future<void> resetChoice() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_choiceKey);
    _choice = null;

    GuestMode.isGuest.value = false;
  }
}
