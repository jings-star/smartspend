import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/expense.dart';

/// One interface, two storages. Screens only talk to this.
///
///   final repo = ExpenseRepository.current;
///   repo.add(expense);
///   StreamBuilder(stream: repo.watch(), ...)
abstract class ExpenseRepository {
  Stream<List<Expense>> watch();
  Future<void> add(Expense e);
  Future<void> delete(String id);

  /// Logged in -> Firestore. Guest -> memory.
  static ExpenseRepository get current {
    final user = FirebaseAuth.instance.currentUser;
    return user == null
        ? MemoryExpenseRepository.instance
        : FirestoreExpenseRepository(user.uid);
  }
}

/// Guest storage. Lives only while the app is running.
class MemoryExpenseRepository implements ExpenseRepository {
  MemoryExpenseRepository._();
  static final MemoryExpenseRepository instance = MemoryExpenseRepository._();

  final List<Expense> _items = [];
  final StreamController<List<Expense>> _controller =
      StreamController<List<Expense>>.broadcast();

  List<Expense> get items => List.unmodifiable(_items);

  @override
  Stream<List<Expense>> watch() async* {
    yield items; // current data first, then live updates
    yield* _controller.stream;
  }

  @override
  Future<void> add(Expense e) async {
    final withId = Expense(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: e.title,
      amount: e.amount,
      category: e.category,
      date: e.date,
    );
    _items.add(withId);
    _controller.add(items);
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((e) => e.id == id);
    _controller.add(items);
  }

  void clear() {
    _items.clear();
    _controller.add(items);
  }
}

/// Logged-in storage: users/{uid}/expenses
class FirestoreExpenseRepository implements ExpenseRepository {
  FirestoreExpenseRepository(this.uid);
  final String uid;

  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore
      .instance
      .collection('users')
      .doc(uid)
      .collection('expenses');

  @override
  Stream<List<Expense>> watch() => _col
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Expense.fromMap(d.id, d.data())).toList());

  @override
  Future<void> add(Expense e) => _col.add(e.toMap());

  @override
  Future<void> delete(String id) => _col.doc(id).delete();
}
