import 'package:flutter/material.dart';
import '../models/transaction_item.dart';

const _monthsLong = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];
const _monthsShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

String monthLong(DateTime d) => _monthsLong[d.month - 1];
String monthShort(DateTime d) => _monthsShort[d.month - 1];

/// "July 2026"
String monthYear(DateTime d) => '${_monthsLong[d.month - 1]} ${d.year}';

/// "Jul 2026"
String monthShortYear(DateTime d) => '${_monthsShort[d.month - 1]} ${d.year}';

/// "RM3,200" (decimals only when needed)
String fmtMoney(double v) {
  final whole = v == v.roundToDouble();
  final s = whole ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  final parts = s.split('.');
  final neg = parts[0].startsWith('-');
  final digits = neg ? parts[0].substring(1) : parts[0];
  final withCommas = digits.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
  return '${neg ? '-' : ''}RM$withCommas${parts.length > 1 ? '.${parts[1]}' : ''}';
}

// ---------------------------------------------------------------------------
// Category colours (Food / Shopping / Transport get their own, rest = gold)
// ---------------------------------------------------------------------------

const Map<String, int> _catColors = {
  'Food': 0xFFB0543F,
  'Shopping': 0xFF7B5EBA,
  'Transport': 0xFF4F6FAE,
  'Other': 0xFFBE8A3F,
};

int catColorInt(String category) => _catColors[category] ?? 0xFFBE8A3F;
Color catColor(String category) => Color(catColorInt(category));

String catEmoji(String category) =>
    category == 'Other' ? '📦' : (kCategoryEmoji[category] ?? '📦');

// ---------------------------------------------------------------------------
// Date helpers
// ---------------------------------------------------------------------------

DateTime monthOf(DateTime d) => DateTime(d.year, d.month);

bool sameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

/// Week buckets: days 1-7 = week 0, 8-14 = 1, 15-21 = 2, 22+ = 3.
int weekOfMonth(DateTime d) => ((d.day - 1) ~/ 7).clamp(0, 3).toInt();

/// All distinct months that have transactions, oldest first.
List<DateTime> monthsIn(List<TransactionItem> all) {
  final set = <DateTime>{for (final t in all) monthOf(t.date)};
  final list = set.toList()..sort();
  return list;
}

// ---------------------------------------------------------------------------
// Stats
// ---------------------------------------------------------------------------

class PeriodStats {
  PeriodStats({
    required this.start,
    required this.end,
    required this.income,
    required this.expense,
    required this.categories,
    this.prevIncome,
    this.prevExpense,
  });

  final DateTime start;
  final DateTime end;
  final double income;
  final double expense;

  /// Expense categories, biggest first.
  final List<MapEntry<String, double>> categories;

  /// Previous month figures (null if there is no earlier data).
  final double? prevIncome;
  final double? prevExpense;

  double get balance => income - expense;
  double get savedPct => income <= 0 ? 0 : balance / income;

  static int scoreFor(double income, double expense) {
    if (income <= 0) return 0;
    final s = 50 + (income - expense) / income * 100;
    return s.round().clamp(0, 100).toInt();
  }

  int get healthScore => scoreFor(income, expense);

  int? get prevScore => (prevIncome == null || prevExpense == null)
      ? null
      : scoreFor(prevIncome!, prevExpense!);

  String get healthLabel {
    final s = healthScore;
    if (s >= 80) return 'Excellent';
    if (s >= 65) return 'Good';
    if (s >= 50) return 'Fair';
    return 'Needs attention';
  }

  /// % change in spending vs previous month (null when unknown).
  double? get expenseChangePct =>
      (prevExpense == null || prevExpense == 0)
          ? null
          : (expense - prevExpense!) / prevExpense! * 100;

  /// For the current calendar month this extrapolates spending to month end;
  /// for past months it is simply the final balance.
  double get projectedBalance {
    final now = DateTime.now();
    final isCurrentMonth =
        start.year == now.year && start.month == now.month && start.day == 1;
    if (isCurrentMonth) {
      final days = DateTime(now.year, now.month + 1, 0).day;
      return income - (expense / now.day) * days;
    }
    return balance;
  }

  double get totalExpenseForPct => expense <= 0 ? 1 : expense;

  static PeriodStats range(
      List<TransactionItem> all, DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    double inc = 0, exp = 0;
    final cats = <String, double>{};
    for (final t in all) {
      final d = DateTime(t.date.year, t.date.month, t.date.day);
      if (d.isBefore(s) || d.isAfter(e)) continue;
      if (t.type == TxType.income) {
        inc += t.amount;
      } else {
        exp += t.amount;
        cats[t.category] = (cats[t.category] ?? 0) + t.amount;
      }
    }
    final list = cats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return PeriodStats(
        start: s, end: e, income: inc, expense: exp, categories: list);
  }

  /// Stats for a whole calendar month, including previous-month comparison.
  static PeriodStats month(List<TransactionItem> all, DateTime m) {
    final cur = range(all, DateTime(m.year, m.month, 1),
        DateTime(m.year, m.month + 1, 0));
    final pm = DateTime(m.year, m.month - 1);
    final prev = range(all, DateTime(pm.year, pm.month, 1),
        DateTime(pm.year, pm.month + 1, 0));
    final hasPrev = prev.income > 0 || prev.expense > 0;
    return PeriodStats(
      start: cur.start,
      end: cur.end,
      income: cur.income,
      expense: cur.expense,
      categories: cur.categories,
      prevIncome: hasPrev ? prev.income : null,
      prevExpense: hasPrev ? prev.expense : null,
    );
  }
}

class Totals {
  const Totals(this.income, this.expense);
  final double income;
  final double expense;
}

/// Income / expense for each of the 4 weeks of [month].
List<Totals> weeklyTotals(List<TransactionItem> all, DateTime month) {
  final inc = List<double>.filled(4, 0);
  final exp = List<double>.filled(4, 0);
  for (final t in all) {
    if (!sameMonth(t.date, month)) continue;
    final w = weekOfMonth(t.date);
    if (t.type == TxType.income) {
      inc[w] += t.amount;
    } else {
      exp[w] += t.amount;
    }
  }
  return [for (var i = 0; i < 4; i++) Totals(inc[i], exp[i])];
}

/// Income / expense for each month in [months].
List<Totals> monthlyTotals(List<TransactionItem> all, List<DateTime> months) {
  return [
    for (final m in months)
      () {
        final s = PeriodStats.range(
            all, DateTime(m.year, m.month, 1), DateTime(m.year, m.month + 1, 0));
        return Totals(s.income, s.expense);
      }()
  ];
}

/// One slice of the category pie (top 3 categories + "Other").
class PieGroup {
  PieGroup(this.label, this.amount, this.names);
  final String label;
  final double amount;
  final Set<String> names;
  Color get color => catColor(label);
}

List<PieGroup> pieGroups(PeriodStats s) {
  final cats = s.categories;
  final groups = <PieGroup>[
    for (final e in cats.take(3)) PieGroup(e.key, e.value, {e.key}),
  ];
  final rest = cats.skip(3).toList();
  if (rest.isNotEmpty) {
    groups.add(PieGroup('Other', rest.fold(0.0, (s, e) => s + e.value),
        rest.map((e) => e.key).toSet()));
  }
  return groups;
}

/// Share (0-1) of the last week's spending that went to [names].
double lastWeekShare(
    List<TransactionItem> all, DateTime month, Set<String> names) {
  double total = 0, part = 0;
  for (final t in all) {
    if (t.type != TxType.expense || !sameMonth(t.date, month)) continue;
    if (weekOfMonth(t.date) != 3) continue;
    total += t.amount;
    if (names.contains(t.category)) part += t.amount;
  }
  return total <= 0 ? 0 : part / total;
}

/// Expense records of [names] in [month], grouped by week index (0-3).
Map<int, List<TransactionItem>> recordsByWeek(
    List<TransactionItem> all, DateTime month, Set<String> names) {
  final map = <int, List<TransactionItem>>{};
  final list = all
      .where((t) =>
          t.type == TxType.expense &&
          sameMonth(t.date, month) &&
          names.contains(t.category))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  for (final t in list) {
    map.putIfAbsent(weekOfMonth(t.date), () => []).add(t);
  }
  return map;
}

// ---------------------------------------------------------------------------
// Sample data (Apr - Jul 2026) so the dashboard matches the design.
// TODO: remove and pass your real transactions to DashboardScreen instead.
// ---------------------------------------------------------------------------

const _titles = <String, List<String>>{
  'Food': ['Grab Food', 'Restoran', 'Mamak'],
  'Shopping': ['Uniqlo', 'Shopee order', 'Zalora'],
  'Transport': ['Petrol', 'Grab ride', "Touch 'n Go reload"],
  'Bills': ['Phone bill', 'Electricity', 'Wi-Fi'],
  'Personal Care': ['Watsons', 'Salon', 'Pharmacy'],
  'Health': ['Clinic', 'Vitamins', 'Pharmacy'],
};

List<TransactionItem> buildDashboardSample() {
  final out = <TransactionItem>[];
  var n = 0;

  void add(int m, int d, String title, String cat, double amt, TxType type) {
    out.add(TransactionItem(
      id: 'ds${n++}',
      title: title,
      category: cat,
      amount: amt,
      type: type,
      date: DateTime(2026, m, d),
      paymentMethod: 'E-wallet',
    ));
  }

  void split(int m, String cat, double total) {
    final a = (total * 0.4).roundToDouble();
    final b = (total * 0.35).roundToDouble();
    final c = total - a - b;
    final t = _titles[cat] ?? [cat, cat, cat];
    add(m, 4, t[0], cat, a, TxType.expense);
    add(m, 13, t[1], cat, b, TxType.expense);
    add(m, 23, t[2], cat, c, TxType.expense);
  }

  void income(int m, double total) {
    final salary = (total * 0.85).roundToDouble();
    add(m, 1, 'Part-time salary', 'Income', salary, TxType.income);
    add(m, 1, 'Allowance', 'Income', total - salary, TxType.income);
  }

  final plans = <(int, double, Map<String, double>)>[
    (4, 3000, {'Food': 520, 'Shopping': 330, 'Transport': 250, 'Bills': 400, 'Personal Care': 100}),
    (5, 3100, {'Food': 560, 'Shopping': 350, 'Transport': 260, 'Bills': 400, 'Health': 80}),
    (6, 2080, {'Food': 600, 'Shopping': 450, 'Transport': 280, 'Bills': 400, 'Personal Care': 140}),
  ];
  for (final p in plans) {
    income(p.$1, p.$2);
    p.$3.forEach((cat, total) => split(p.$1, cat, total));
  }

  // July 2026 - detailed Food records as in the design (12 transactions).
  income(7, 3200);
  const food = <(int, String, double)>[
    (2, 'Grab Food — Nasi Lemak', 45),
    (4, 'Restoran Ali — Dinner', 60),
    (6, '7-Eleven — Snacks', 15),
    (9, 'FoodPanda — Chicken Rice', 40),
    (11, 'Mamak — Supper', 50),
    (13, 'NSK — Groceries', 110),
    (16, 'Grab Food — Burger', 40),
    (19, 'Restaurant — Family dinner', 140),
    (23, 'FoodPanda — Dinner set', 45),
    (26, 'Mamak — Breakfast', 55),
    (28, 'NSK — Groceries', 100),
    (30, 'Kopi — Coffee', 20),
  ];
  for (final f in food) {
    add(7, f.$1, f.$2, 'Food', f.$3, TxType.expense);
  }
  split(7, 'Shopping', 480);
  split(7, 'Transport', 300);
  split(7, 'Bills', 400);
  split(7, 'Personal Care', 140);
  split(7, 'Health', 100);

  return out;
}
