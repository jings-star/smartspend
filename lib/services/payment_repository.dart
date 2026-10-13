import 'package:flutter/foundation.dart';

import '../models/payment_method.dart';
import '../models/payment_transaction.dart';

/// This keeps everything IN MEMORY, so it resets when the app restarts.
/// Later, replace the inside of these functions with Firebase (Firestore).
/// The screens will not need to change.
class PaymentRepository extends ChangeNotifier {
  PaymentRepository._();
  static final PaymentRepository instance = PaymentRepository._();

  final List<PaymentMethod> _methods = [
    const PaymentMethod(
      id: '1',
      type: PaymentType.ewallet,
      title: 'E-wallet',
      isDefault: true,
      transactionCount: 38,
      totalAmount: 612,
      monthlyLimit: 800,
    ),
    const PaymentMethod(
      id: '2',
      type: PaymentType.cash,
      title: 'Cash',
      transactionCount: 14,
      totalAmount: 208,
    ),
    const PaymentMethod(
      id: '3',
      type: PaymentType.card,
      title: 'Card',
      holderName: 'Janice',
      bankName: 'Maybank',
      cardLast4: '4821',
      transactionCount: 9,
      totalAmount: 540,
      monthlyLimit: 500, // already over, so you can see the warning
    ),
    const PaymentMethod(
      id: '4',
      type: PaymentType.bank,
      title: 'Bank transfer',
      holderName: 'Janice',
      bankName: 'Maybank',
      transactionCount: 2,
      totalAmount: 600,
    ),
  ];

  final List<PaymentTransaction> _transactions = _sampleTransactions();

  // ----------------------------------------------------------------
  // READ
  // ----------------------------------------------------------------

  List<PaymentMethod> get methods => List.unmodifiable(_methods);

  PaymentMethod? byId(String id) {
    for (final method in _methods) {
      if (method.id == id) return method;
    }
    return null;
  }

  /// Newest first.
  List<PaymentTransaction> transactionsFor(String methodId) {
    return _transactions.where((t) => t.methodId == methodId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  // ----------------------------------------------------------------
  // CREATE
  // ----------------------------------------------------------------

  Future<void> add(PaymentMethod method) async {
    await _fakeDelay();
    if (method.isDefault) _clearDefaults();
    _methods.add(method);
    _ensureOneDefault();
    notifyListeners();
  }

  // ----------------------------------------------------------------
  // UPDATE
  // ----------------------------------------------------------------

  Future<void> update(PaymentMethod method) async {
    await _fakeDelay();
    final index = _methods.indexWhere((m) => m.id == method.id);
    if (index == -1) return;
    if (method.isDefault) _clearDefaults();
    _methods[index] = method;
    _ensureOneDefault();
    notifyListeners();
  }

  // ----------------------------------------------------------------
  // DELETE
  // ----------------------------------------------------------------

  /// Normal delete (used by the delete button in the edit form).
  Future<void> delete(String id) async {
    await _fakeDelay();
    _methods.removeWhere((m) => m.id == id);
    _ensureOneDefault();
    notifyListeners();
  }

  /// Removes it RIGHT AWAY (used by swipe-to-delete) and returns what was
  /// removed, so it can be put back with [restore] if the user taps Undo.
  ({PaymentMethod method, int index})? removeForUndo(String id) {
    final index = _methods.indexWhere((m) => m.id == id);
    if (index == -1) return null;
    final method = _methods.removeAt(index);
    _ensureOneDefault();
    notifyListeners();
    return (method: method, index: index);
  }

  /// UNDO for [removeForUndo].
  void restore(PaymentMethod method, int index) {
    if (method.isDefault) _clearDefaults();
    final position = index > _methods.length ? _methods.length : index;
    _methods.insert(position, method);
    _ensureOneDefault();
    notifyListeners();
  }

  // ----------------------------------------------------------------
  // helpers
  // ----------------------------------------------------------------

  Future<void> _fakeDelay() {
    return Future.delayed(const Duration(milliseconds: 300));
  }

  void _clearDefaults() {
    for (var i = 0; i < _methods.length; i++) {
      if (_methods[i].isDefault) {
        _methods[i] = _methods[i].copyWith(isDefault: false);
      }
    }
  }

  /// There should always be exactly one default method (if any exist).
  void _ensureOneDefault() {
    if (_methods.isNotEmpty && !_methods.any((m) => m.isDefault)) {
      _methods[0] = _methods[0].copyWith(isDefault: true);
    }
  }

  /// A few sample transactions, with dates counted back from today.
  static List<PaymentTransaction> _sampleTransactions() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime daysAgo(int days) => today.subtract(Duration(days: days));

    return [
      // E-wallet
      PaymentTransaction(id: 't1', methodId: '1', title: 'Lunch · Nasi kandar', amount: 14.50, date: daysAgo(0)),
      PaymentTransaction(id: 't2', methodId: '1', title: 'Ride to work', amount: 18.20, date: daysAgo(1)),
      PaymentTransaction(id: 't3', methodId: '1', title: 'Groceries', amount: 76.90, date: daysAgo(2)),
      PaymentTransaction(id: 't4', methodId: '1', title: 'Coffee', amount: 12.00, date: daysAgo(4)),
      PaymentTransaction(id: 't5', methodId: '1', title: 'Movie tickets', amount: 38.00, date: daysAgo(5)),
      // Cash
      PaymentTransaction(id: 't6', methodId: '2', title: 'Wet market', amount: 32.00, date: daysAgo(0)),
      PaymentTransaction(id: 't7', methodId: '2', title: 'Parking', amount: 6.00, date: daysAgo(2)),
      PaymentTransaction(id: 't8', methodId: '2', title: 'Breakfast', amount: 9.50, date: daysAgo(3)),
      // Card
      PaymentTransaction(id: 't9', methodId: '3', title: 'Online shopping', amount: 189.00, date: daysAgo(1)),
      PaymentTransaction(id: 't10', methodId: '3', title: 'Electricity bill', amount: 120.50, date: daysAgo(3)),
      PaymentTransaction(id: 't11', methodId: '3', title: 'Streaming subscription', amount: 55.00, date: daysAgo(6)),
      // Bank transfer (money coming in)
      PaymentTransaction(id: 't12', methodId: '4', title: 'Transfer from family', amount: 200.00, date: daysAgo(2), isIncome: true),
      PaymentTransaction(id: 't13', methodId: '4', title: 'Part-time income', amount: 400.00, date: daysAgo(5), isIncome: true),
    ];
  }
}
