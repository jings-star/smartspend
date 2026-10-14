enum PaymentType { ewallet, card, bank, cash }

/// One payment method (one row on the dashboard).
class PaymentMethod {
  final String id;
  final PaymentType type;

  /// The name shown on the dashboard, e.g. "E-wallet" or "Card •••• 4821".
  final String title;

  final String? holderName;
  final String? bankName;

  /// We only keep the LAST 4 digits of a card, never the full number.
  final String? cardLast4;

  final bool isDefault;
  final int transactionCount;
  final double totalAmount;

  /// Optional spending limit per month (null = no limit).
  final double? monthlyLimit;

  const PaymentMethod({
    required this.id,
    required this.type,
    required this.title,
    this.holderName,
    this.bankName,
    this.cardLast4,
    this.isDefault = false,
    this.transactionCount = 0,
    this.totalAmount = 0,
    this.monthlyLimit,
  });

  // ------------------------------------------------------------------
  // Firebase stores data as a "Map" (name -> value). These two functions
  // translate between our PaymentMethod and that Map.
  // ------------------------------------------------------------------

  /// PaymentMethod  ->  Map  (to save in Firestore)
  /// The id is NOT in the map, because it is the name of the document.
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'title': title,
      'holderName': holderName,
      'bankName': bankName,
      'cardLast4': cardLast4,
      'isDefault': isDefault,
      'transactionCount': transactionCount,
      'totalAmount': totalAmount,
      'monthlyLimit': monthlyLimit,
    };
  }

  /// Map  ->  PaymentMethod  (when we read from Firestore)
  factory PaymentMethod.fromMap(String id, Map<String, dynamic> map) {
    return PaymentMethod(
      id: id,
      type: PaymentType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => PaymentType.cash,
      ),
      title: map['title'] as String? ?? 'Payment method',
      holderName: map['holderName'] as String?,
      bankName: map['bankName'] as String?,
      cardLast4: map['cardLast4'] as String?,
      isDefault: map['isDefault'] as bool? ?? false,
      transactionCount: (map['transactionCount'] as num?)?.toInt() ?? 0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0,
      monthlyLimit: (map['monthlyLimit'] as num?)?.toDouble(),
    );
  }

  // ------------------------------------------------------------------

  /// Bank transfers are money coming IN, so they show a "+" and are not
  /// counted in "Spend share by method".
  bool get isIncome => type == PaymentType.bank;

  /// How much of the limit is used: 0.5 = 50%, 1.2 = 120%.
  /// null if there is no limit (or this method is income).
  double? get limitUsage {
    final limit = monthlyLimit;
    if (isIncome || limit == null || limit <= 0) return null;
    return totalAmount / limit;
  }

  bool get isOverLimit => (limitUsage ?? 0) > 1;

  bool get isNearLimit {
    final usage = limitUsage ?? 0;
    return usage >= 0.8 && usage <= 1;
  }

  PaymentMethod copyWith({bool? isDefault}) {
    return PaymentMethod(
      id: id,
      type: type,
      title: title,
      holderName: holderName,
      bankName: bankName,
      cardLast4: cardLast4,
      isDefault: isDefault ?? this.isDefault,
      transactionCount: transactionCount,
      totalAmount: totalAmount,
      monthlyLimit: monthlyLimit,
    );
  }
}
