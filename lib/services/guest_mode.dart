import 'package:flutter/foundation.dart';

/// True when the user chose "Continue as guest".
/// Memory only: resets whenever the app is fully closed.
class GuestMode {
  static final ValueNotifier<bool> isGuest = ValueNotifier(false);
}
