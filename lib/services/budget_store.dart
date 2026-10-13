import 'package:flutter/foundation.dart';

import '../models/budget.dart';
import '../models/recurring_transaction.dart' show expenseCategories;

/// Holds the budgets and notifies listeners on every change.
///
/// TODO: in-memory only. To persist, call your backend / local DB inside
/// add(), update() and delete(), and load the list on login. Also, "spent"
/// is typed in by the user for now; later you can compute it from the
/// logged transactions of each category.
class BudgetStore extends ChangeNotifier {
  BudgetStore._();
  static final BudgetStore instance = BudgetStore._();

  // TODO: start with an empty list once real data is connected.
  final List<Budget> _items = [
    const Budget(
        id: 'b1', category: 'Food & Drink', amount: 600, spent: 410.20),
    const Budget(id: 'b2', category: 'Transport', amount: 250, spent: 238.50),
    const Budget(id: 'b3', category: 'Shopping', amount: 300, spent: 364.90),
    const Budget(
        id: 'b4', category: 'Entertainment', amount: 150, spent: 71.90),
    const Budget(
        id: 'b5', category: 'Bills & Utilities', amount: 1150, spent: 528.90),
  ];

  List<Budget> get items => List.unmodifiable(_items);

  String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  /// Categories that don't have a budget yet. Pass [keep] to also include the
  /// category of the budget being edited.
  List<String> availableCategories({String? keep}) => expenseCategories
      .where((c) => c == keep || !_items.any((b) => b.category == c))
      .toList();

  void add(Budget b) {
    _items.add(b);
    notifyListeners();
  }

  void update(Budget b) {
    final i = _items.indexWhere((e) => e.id == b.id);
    if (i == -1) return;
    _items[i] = b;
    notifyListeners();
  }

  void delete(String id) {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
