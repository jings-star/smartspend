import 'package:firebase_auth/firebase_auth.dart';

import 'expense_repository.dart';
import 'transaction_repository.dart';

/// Copies what the guest entered into their new account, then clears memory.
/// Safe to call any time: does nothing if not logged in or no guest data.
Future<void> migrateGuestData() async {
  await TransactionRepository.instance.migrateGuestData();

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final memory = MemoryExpenseRepository.instance;
  final guestItems = memory.items;
  if (guestItems.isEmpty) return;

  final cloud = FirestoreExpenseRepository(user.uid);
  for (final e in guestItems) {
    await cloud.add(e);
  }
  memory.clear();
}


