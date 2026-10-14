import 'package:cloud_firestore/cloud_firestore.dart';

/// Example model. Rename/extend the fields to match your own app.
class Expense {
  final String id;
  final String title;
  final double amount; // MYR
  final String category;
  final DateTime date;

  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'amount': amount,
        'category': category,
        'date': Timestamp.fromDate(date),
      };

  factory Expense.fromMap(String id, Map<String, dynamic> map) => Expense(
        id: id,
        title: (map['title'] ?? '') as String,
        amount: ((map['amount'] ?? 0) as num).toDouble(),
        category: (map['category'] ?? 'Other') as String,
        date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}
