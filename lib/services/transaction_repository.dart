import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/transaction_item.dart';

/// Keeps all transactions in ONE place.
///
///   Guest (not logged in) -> kept in MEMORY (gone when the app closes)
///   Logged in             -> saved in Firestore:
///                            users / {user id} / transactions / {id}
///
/// Every user has their own drawer, so a new account starts EMPTY and can
/// only ever see its own data.
class TransactionRepository extends ChangeNotifier {
  TransactionRepository._() {
    // Whenever someone logs in or out, switch to the right data.
    FirebaseAuth.instance.authStateChanges().listen(_onUserChanged);
  }
  static final TransactionRepository instance = TransactionRepository._();

  /// The "table" name. Typed only here.
  static const String _collectionName = 'transactions';

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<TransactionItem> _guestItems = []; // used when logged out
  List<TransactionItem> _cloudItems = []; // used when logged in
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  bool get _loggedIn => FirebaseAuth.instance.currentUser != null;

  String get _userId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Please log in first.');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> _collectionFor(String uid) {
    return _db.collection('users').doc(uid).collection(_collectionName);
  }

  CollectionReference<Map<String, dynamic>> get _collection =>
      _collectionFor(_userId);

  // ----------------------------------------------------------------
  // READ
  // ----------------------------------------------------------------

  /// The transactions of whoever is using the app right now.
  List<TransactionItem> get items =>
      List.unmodifiable(_loggedIn ? _cloudItems : _guestItems);

  void _onUserChanged(User? user) {
    _subscription?.cancel();
    _subscription = null;

    // Forget the previous user's data right away (so nobody sees it).
    _cloudItems = [];
    notifyListeners();

    if (user == null) return; // logged out: guest memory is used again

    _subscription = _collectionFor(user.uid).snapshots().listen(
      (snapshot) {
        _cloudItems = snapshot.docs
            .map((doc) => _fromDocument(doc.id, doc.data()))
            .toList();
        notifyListeners();
      },
      onError: (Object error) =>
          debugPrint('Firestore transactions read error: $error'),
    );
  }

  // ----------------------------------------------------------------
  // CREATE
  // ----------------------------------------------------------------

  Future<void> addAll(List<TransactionItem> newItems) async {
    if (newItems.isEmpty) return;

    if (!_loggedIn) {
      _guestItems.addAll(newItems);
      notifyListeners();
      return;
    }

    final batch = _db.batch();
    for (final item in newItems) {
      batch.set(_collection.doc(item.id), _toDocument(item));
    }
    await batch.commit();
  }

  // ----------------------------------------------------------------
  // UPDATE  (one transaction can become several, when it is split)
  // ----------------------------------------------------------------

  Future<void> replace(String oldId, List<TransactionItem> newItems) async {
    if (!_loggedIn) {
      final index = _guestItems.indexWhere((t) => t.id == oldId);
      if (index == -1) return;
      _guestItems
        ..removeAt(index)
        ..insertAll(index, newItems);
      notifyListeners();
      return;
    }

    final batch = _db.batch();
    // If the id stays the same, set() below simply overwrites it.
    if (!newItems.any((t) => t.id == oldId)) {
      batch.delete(_collection.doc(oldId));
    }
    for (final item in newItems) {
      batch.set(_collection.doc(item.id), _toDocument(item));
    }
    await batch.commit();
  }

  // ----------------------------------------------------------------
  // DELETE
  // ----------------------------------------------------------------

  Future<void> delete(String id) async {
    if (!_loggedIn) {
      _guestItems.removeWhere((t) => t.id == id);
      notifyListeners();
      return;
    }
    await _collection.doc(id).delete();
  }

  // ----------------------------------------------------------------
  // GUEST -> ACCOUNT
  // ----------------------------------------------------------------

  /// Copies the guest's transactions into the account that just logged in,
  /// then clears the guest memory. Safe to call many times: with nothing to
  /// copy it does nothing, and saving the same id twice never duplicates.
  Future<void> migrateGuestData() async {
    if (!_loggedIn || _guestItems.isEmpty) return;

    final guestItems = List<TransactionItem>.of(_guestItems);

    // Firestore allows up to 500 writes per batch, so we save in chunks.
    for (var start = 0; start < guestItems.length; start += 400) {
      final batch = _db.batch();
      for (final item in guestItems.skip(start).take(400)) {
        batch.set(_collection.doc(item.id), _toDocument(item));
      }
      await batch.commit();
    }

    _guestItems.clear();
    notifyListeners();
  }

  // ----------------------------------------------------------------
  // TransactionItem  <->  Firestore Map
  // ----------------------------------------------------------------

  Map<String, dynamic> _toDocument(TransactionItem item) {
    return {
      'transactionID': item.id, // PK
      'userID': _userId, // FK (Users.userID)
      'notes': item.title,
      'category': item.category,
      'amount': item.amount,
      'type': item.type.name, // 'income' or 'expense'
      'date': Timestamp.fromDate(item.date),
      'paymentMethod': item.paymentMethod,
      'receiptPath': item.receiptPath,
    };
  }

  TransactionItem _fromDocument(String id, Map<String, dynamic> map) {
    final rawDate = map['date'];
    return TransactionItem(
      id: id,
      title: (map['notes'] ?? map['title']) as String? ?? '',
      category: map['category'] as String? ?? 'Other',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      type: map['type'] == 'income' ? TxType.income : TxType.expense,
      date: rawDate is Timestamp ? rawDate.toDate() : DateTime.now(),
      paymentMethod: map['paymentMethod'] as String? ?? '',
      receiptPath: map['receiptPath'] as String?,
    );
  }
}
