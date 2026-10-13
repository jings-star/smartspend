class PaymentValidators {
  static String? notEmpty(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  /// If [optional] is true, an empty box is fine (used when editing a card).
  static String? cardNumber(String? value, {bool optional = false}) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return optional ? null : 'Please enter the card number';
    }
    if (digits.length < 13 || digits.length > 19) {
      return 'A card number has 13 to 19 digits';
    }
    return null;
  }

  /// The monthly limit is optional. If something is typed, it must be > 0.
  static String? limit(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final number = double.tryParse(text);
    if (number == null || number <= 0) return 'Enter an amount above 0';
    return null;
  }
}
