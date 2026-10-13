import 'package:flutter/material.dart';

import '../services/preferences_store.dart';
import '../theme/app_colors.dart';

enum RecurringType { expense, income }

enum Frequency { daily, weekly, monthly, yearly }

extension FrequencyX on Frequency {
  String get label => switch (this) {
        Frequency.daily => 'Daily',
        Frequency.weekly => 'Weekly',
        Frequency.monthly => 'Monthly',
        Frequency.yearly => 'Yearly',
      };
}

const paymentMethods = ['Card', 'Cash', 'Bank transfer', 'E-wallet'];

// TODO: replace with the user's real categories (Categories page).
const expenseCategories = [
  'Entertainment',
  'Bills & Utilities',
  'Housing',
  'Food & Drink',
  'Shopping',
  'Transport',
  'Education',
  'Health',
  'Insurance',
  'Other',
];
const incomeCategories = [
  'Salary',
  'Allowance',
  'Scholarship',
  'Freelance',
  'Other',
];

class CategoryStyle {
  final IconData icon;
  final Color tint;
  final Color ink;
  const CategoryStyle(this.icon, this.tint, this.ink);
}

CategoryStyle categoryStyleFor(String category) {
  switch (category) {
    case 'Entertainment':
      return const CategoryStyle(
          Icons.movie_outlined, AppColors.goldTint, AppColors.gold);
    case 'Bills & Utilities':
      return const CategoryStyle(
          Icons.lightbulb_outline, AppColors.terracottaTint,
          AppColors.terracottaDark);
    case 'Housing':
      return const CategoryStyle(
          Icons.home_outlined, AppColors.sageTint, AppColors.sage);
    case 'Food & Drink':
      return const CategoryStyle(
          Icons.restaurant_outlined, AppColors.coralTint, AppColors.coral);
    case 'Shopping':
      return const CategoryStyle(Icons.shopping_bag_outlined,
          AppColors.terracottaTint, AppColors.terracottaDark);
    case 'Transport':
      return const CategoryStyle(Icons.directions_bus_outlined,
          AppColors.sageTint, AppColors.sage);
    case 'Education':
      return const CategoryStyle(
          Icons.school_outlined, AppColors.goldTint, AppColors.gold);
    case 'Health':
      return const CategoryStyle(
          Icons.favorite_border, AppColors.coralTint, AppColors.coral);
    case 'Insurance':
      return const CategoryStyle(Icons.shield_outlined,
          AppColors.terracottaTint, AppColors.terracottaDark);
    case 'Salary':
    case 'Allowance':
    case 'Scholarship':
    case 'Freelance':
      return const CategoryStyle(Icons.account_balance_wallet_outlined,
          AppColors.sageTint, AppColors.sage);
    default:
      return const CategoryStyle(Icons.sell_outlined,
          AppColors.backgroundDeep, AppColors.textMuted);
  }
}

class RecurringTransaction {
  final String id;
  final String name;
  final double amount;
  final RecurringType type;
  final Frequency frequency;
  final String category;
  final DateTime startDate;
  final String paymentMethod;
  final String notes;
  final bool active;
  final bool remind;

  const RecurringTransaction({
    required this.id,
    required this.name,
    required this.amount,
    required this.type,
    required this.frequency,
    required this.category,
    required this.startDate,
    this.paymentMethod = 'Card',
    this.notes = '',
    this.active = true,
    this.remind = true,
  });

  RecurringTransaction copyWith({
    String? name,
    double? amount,
    RecurringType? type,
    Frequency? frequency,
    String? category,
    DateTime? startDate,
    String? paymentMethod,
    String? notes,
    bool? active,
    bool? remind,
  }) {
    return RecurringTransaction(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      active: active ?? this.active,
      remind: remind ?? this.remind,
    );
  }

  /// The next date (today or later) this transaction is due.
  DateTime get nextDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    if (!start.isBefore(today)) return start;

    switch (frequency) {
      case Frequency.daily:
        return today;
      case Frequency.weekly:
        final diff = DateTime.utc(today.year, today.month, today.day)
            .difference(DateTime.utc(start.year, start.month, start.day))
            .inDays;
        final steps = (diff / 7).ceil();
        return DateTime(start.year, start.month, start.day + steps * 7);
      case Frequency.monthly:
        final n = (today.year - start.year) * 12 + (today.month - start.month);
        var c = _addMonths(start, n);
        if (c.isBefore(today)) c = _addMonths(start, n + 1);
        return c;
      case Frequency.yearly:
        final n = today.year - start.year;
        var c = _addMonths(start, n * 12);
        if (c.isBefore(today)) c = _addMonths(start, (n + 1) * 12);
        return c;
    }
  }

  int get daysUntilDue {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final due = nextDue;
    return DateTime.utc(due.year, due.month, due.day).difference(today).inDays;
  }

  /// Amount converted to a per-month figure (for the monthly total).
  double get monthlyAmount => switch (frequency) {
        Frequency.daily => amount * 365 / 12,
        Frequency.weekly => amount * 52 / 12,
        Frequency.monthly => amount,
        Frequency.yearly => amount / 12,
      };
}

DateTime _addMonths(DateTime d, int n) {
  final total = d.month - 1 + n;
  final year = d.year + total ~/ 12;
  final month = total % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, d.day > lastDay ? lastDay : d.day);
}

// ---------- formatting helpers ----------

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String shortDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

String formField(DateTime d) =>
    '${d.year} / ${d.month.toString().padLeft(2, '0')} / ${d.day.toString().padLeft(2, '0')}';

String formatMoney(double v) {
  final parts = v.toStringAsFixed(2).split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '$whole.${parts[1]}';
}

/// Symbol of the user's preferred currency. Amounts are only labelled with it,
/// not converted.
String currencySymbol() {
  const symbols = {
    'MYR': 'RM',
    'USD': r'$',
    'SGD': r'S$',
    'JPY': '¥',
    'EUR': '€',
    'GBP': '£',
    'THB': '฿',
    'IDR': 'Rp',
    'AUD': r'A$',
  };
  final code = PreferencesStore.currency.value;
  return symbols[code] ?? code;
}
