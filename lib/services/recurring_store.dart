import 'package:flutter/foundation.dart';

import '../models/recurring_transaction.dart';

/// Holds the recurring transactions and notifies listeners on every change.
///
/// TODO: this is in-memory only. To persist, call your backend / local DB
/// inside add(), update() and delete(), and load the list on login.
class RecurringStore extends ChangeNotifier {
  RecurringStore._();
  static final RecurringStore instance = RecurringStore._();

  // TODO: start with an empty list once real data is connected.
  final List<RecurringTransaction> _items = _demoData();

  List<RecurringTransaction> get items => List.unmodifiable(_items);

  String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  void add(RecurringTransaction t) {
    _items.add(t);
    notifyListeners();
  }

  void update(RecurringTransaction t) {
    final i = _items.indexWhere((e) => e.id == t.id);
    if (i == -1) return;
    _items[i] = t;
    notifyListeners();
  }

  void delete(String id) {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}

List<RecurringTransaction> _demoData() {
  final now = DateTime.now();
  DateTime inDays(int d) => DateTime(now.year, now.month, now.day + d);

  return [
    RecurringTransaction(
      id: 'demo1',
      name: 'Spotify Premium',
      amount: 16.90,
      type: RecurringType.expense,
      frequency: Frequency.monthly,
      category: 'Entertainment',
      startDate: inDays(2),
    ),
    RecurringTransaction(
      id: 'demo2',
      name: 'Netflix',
      amount: 55.00,
      type: RecurringType.expense,
      frequency: Frequency.monthly,
      category: 'Entertainment',
      startDate: inDays(3),
    ),
    RecurringTransaction(
      id: 'demo3',
      name: 'TNB Electricity Bill',
      amount: 145.30,
      type: RecurringType.expense,
      frequency: Frequency.monthly,
      category: 'Bills & Utilities',
      startDate: inDays(9),
    ),
    RecurringTransaction(
      id: 'demo4',
      name: 'Studio Apartment Rent',
      amount: 1200.00,
      type: RecurringType.expense,
      frequency: Frequency.monthly,
      category: 'Housing',
      startDate: inDays(16),
      paymentMethod: 'Bank transfer',
    ),
    RecurringTransaction(
      id: 'demo5',
      name: 'Gym Membership',
      amount: 89.00,
      type: RecurringType.expense,
      frequency: Frequency.monthly,
      category: 'Health',
      startDate: inDays(20),
      active: false,
    ),
  ];
}
