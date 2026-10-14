import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction_item.dart';
import 'ai_service.dart';

/// Asks the server about free text like "Starbucks RM18.50".
/// Returns {title, amount, category, type, source}, or null if the server is unreachable.
Future<Map<String, dynamic>?> suggestFromText(String text) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  try {
    return await categorize(text, userId: uid);
  } catch (e) {
    debugPrint('categorize failed: $e');
    return null;
  }
}

/// Returns just the expense category, or null if unknown.
Future<String?> suggestCategory(String title, double? amount) async {
  final text = amount == null ? title : '$title RM$amount';
  final r = await suggestFromText(text);
  final c = r?['category'] as String?;
  return (c != null && kExpenseCategories.contains(c)) ? c : null;
}

/// Call when a transaction is saved or the user picks a category.
/// Never blocks saving.
void rememberCategory(String title, String category, {bool income = false}) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null || title.trim().isEmpty) return;
  learnCategory(uid, title, category, type: income ? 'income' : 'expense');
}