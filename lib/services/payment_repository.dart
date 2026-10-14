import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/payment_method.dart';
import '../models/payment_transaction.dart';

/// Saves payment methods in Cloud Firestore (the "filing cabinet").
///
/// Where the data lives:   users / {your user id} / payment_methods / {id}
/// So every user has their own drawer, and nobody sees anyone else's.
///
/// The screens did not change. They still use: methods, byId, add, update,
/// delete, removeForUndo, restore. Only the inside of this file is new.
class PaymentRepository extends ChangeNotifier {
  PaymentRepository._() {
    // Whenever someone logs in or out, start or stop listening to their data.
    FirebaseAuth.instance.authStateChanges().listen(_onUserChanged);
  }
  static final PaymentRepository instance = PaymentRepository._();

  /// The "table" name. It is typed ONLY here, so it is easy to rename.
  static const String _collectionName = 'payment_methods';

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<PaymentMethod> _methods = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  /// The id of the person who is logged in right now.
  String get _userId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Please log in first.');
    return user.uid;
  }

  /// The drawer that belongs to one user.
  CollectionReference<Map<String, dynamic>> _collectionFor(String uid) {
    return _db.collection('users').doc(uid).collection(_collectionName);
  }

  /// The drawer of the person who is logged in right now.
  CollectionReference<Map<String, dynamic>> get _collection =>
      _collectionFor(_userId);

  /// Everything we save for one payment method:
  /// the fields from toMap(), plus the two keys from your database table.
  Map<String, dynamic> _dataToSave(PaymentMethod method, bool isDefault) {
    return {
      ...method.toMap(),
      'payMethodID': method.id, // PK in your table
      'userID': _userId, // FK in your table (Users.userID)
      'isDefault': isDefault,
    };
  }

  // ----------------------------------------------------------------
  // READ  (live: the screen updates by itself when the data changes)
  // ----------------------------------------------------------------

  List<PaymentMethod> get methods => List.unmodifiable(_methods);

  PaymentMethod? byId(String id) {
    for (final method in _methods) {
      if (method.id == id) return method;
    }
    return null;
  }

  void _onUserChanged(User? user) {
    _subscription?.cancel();
    _subscription = null;
    _methods = [];
    notifyListeners();

    if (user == null) return; // logged out: nothing to listen to

    // .snapshots() = "tell me now, and tell me again every time it changes".
    _subscription = _collectionFor(user.uid).snapshots().listen(
      (snapshot) {
        _methods = snapshot.docs
            .map((doc) => PaymentMethod.fromMap(doc.id, doc.data()))
            .toList();
        notifyListeners();
      },
      onError: (Object error) => debugPrint('Firestore read error: $error'),
    );
  }

  /// Transactions are not in Firebase yet (that is a later lesson).
  List<PaymentTransaction> transactionsFor(String methodId) => const [];

  /// Document ids made from the time, so they stay in the order we created them.
  String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  // ----------------------------------------------------------------
  // CREATE
  // ----------------------------------------------------------------

  Future<void> add(PaymentMethod method) async {
    final others = _methods.where((m) => m.id != method.id).toList();
    // The first method is always the default.
    final isDefault = method.isDefault || others.isEmpty;

    // A batch = several changes saved together, all or nothing.
    final batch = _db.batch();
    if (isDefault) {
      for (final other in others.where((m) => m.isDefault)) {
        batch.update(_collection.doc(other.id), {'isDefault': false});
      }
    }
    batch.set(_collection.doc(method.id), _dataToSave(method, isDefault));
    await batch.commit();
  }

  // ----------------------------------------------------------------
  // UPDATE
  // ----------------------------------------------------------------

  Future<void> update(PaymentMethod method) async {
    final others = _methods.where((m) => m.id != method.id).toList();
    final isDefault = method.isDefault || others.isEmpty;

    final batch = _db.batch();
    if (isDefault) {
      for (final other in others.where((m) => m.isDefault)) {
        batch.update(_collection.doc(other.id), {'isDefault': false});
      }
    } else if (!others.any((m) => m.isDefault)) {
      // Nobody would be the default anymore, so pick the first one.
      batch.update(_collection.doc(others.first.id), {'isDefault': true});
    }
    batch.set(_collection.doc(method.id), _dataToSave(method, isDefault));
    await batch.commit();
  }

  // ----------------------------------------------------------------
  // DELETE
  // ----------------------------------------------------------------

  /// Normal delete (used by the bin button in the edit form).
  Future<void> delete(String id) {
    final wasDefault = byId(id)?.isDefault ?? false;
    return _deleteDocument(id, wasDefault);
  }

  /// Swipe-to-delete: disappears from the screen RIGHT AWAY, is deleted in
  /// Firebase in the background, and returns what it removed for Undo.
  ({PaymentMethod method, int index})? removeForUndo(String id) {
    final index = _methods.indexWhere((m) => m.id == id);
    if (index == -1) return null;

    final method = _methods.removeAt(index);
    notifyListeners();

    unawaited(
      _deleteDocument(method.id, method.isDefault).catchError(
        (Object error) => debugPrint('Firestore delete error: $error'),
      ),
    );
    return (method: method, index: index);
  }

  /// UNDO for [removeForUndo]: show it again and save it again.
  void restore(PaymentMethod method, int index) {
    final position = index > _methods.length ? _methods.length : index;
    _methods.insert(position, method);
    notifyListeners();

    unawaited(
      add(method).catchError(
        (Object error) => debugPrint('Firestore restore error: $error'),
      ),
    );
  }

  Future<void> _deleteDocument(String id, bool wasDefault) async {
    await _collection.doc(id).delete();

    // If we deleted the default, give the "default" tag to someone else.
    if (wasDefault) {
      final remaining = _methods.where((m) => m.id != id).toList();
      if (remaining.isNotEmpty) {
        await _collection.doc(remaining.first.id).update({'isDefault': true});
      }
    }
  }
}