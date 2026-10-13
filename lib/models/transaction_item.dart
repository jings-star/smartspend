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

/// Replace with your real data source (Firestore / SQLite / API).
final List<TransactionItem> sampleTransactions = [
  TransactionItem(
      id: '1', title: 'Village Grocer', category: 'Food', amount: 48,
      type: TxType.expense, date: DateTime(2026, 8, 2), paymentMethod: 'E-wallet'),
  TransactionItem(
      id: '2', title: 'Part-time salary', category: 'Income', amount: 600,
      type: TxType.income, date: DateTime(2026, 8, 1), paymentMethod: 'Bank transfer'),
  TransactionItem(
      id: '3', title: 'Watsons', category: 'Personal Care', amount: 26,
      type: TxType.expense, date: DateTime(2026, 8, 1), paymentMethod: 'Card'),
  TransactionItem(
      id: '4', title: 'Petrol', category: 'Transport', amount: 12,
      type: TxType.expense, date: DateTime(2026, 8, 1), paymentMethod: 'Cash'),
];
