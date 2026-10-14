enum TxType { income, expense }

enum SortOption {
  dateNewest('Date, newest first'),
  dateOldest('Date, oldest first'),
  amountHigh('Amount, high to low'),
  amountLow('Amount, low to high');

  final String label;
  const SortOption(this.label);
}

const Map<String, String> kCategoryEmoji = {
  'Food': '🍜',
  'Shopping': '🛍️',
  'Transport': '🚌',
  'Bills': '🧾',
  'Personal Care': '🧴',
  'Entertainment': '🎬',
  'Health': '💊',
  'Income': '💰',
};

const List<String> kExpenseCategories = [
  'Food',
  'Shopping',
  'Transport',
  'Bills',
  'Personal Care',
  'Entertainment',
  'Health',
  'Education',
];

const List<String> kPaymentMethods = ['E-wallet', 'Cash', 'Card', 'Bank transfer'];

class TransactionItem {
  final String id;
  final String title;
  final String category;
  final double amount;
  final TxType type;
  final DateTime date;
  final String paymentMethod;

  /// Optional receipt file path / URL.
  final String? receiptPath;

  const TransactionItem({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.type,
    required this.date,
    required this.paymentMethod,
    this.receiptPath,
  });

  String get emoji => kCategoryEmoji[category] ?? '📦';
}


