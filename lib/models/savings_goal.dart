import 'package:flutter/material.dart';

enum GoalCategory {
  emergency('🛟', Color(0xFFEBDCD3)),
  travel('✈️', Color(0xFFDDE6F3)),
  gadget('💻', Color(0xFFDDEBE0)),
  education('🎓', Color(0xFFE4DDF3));

  final String emoji;
  final Color tint;
  const GoalCategory(this.emoji, this.tint);
}

class SavingsGoal {
  final String id;
  final String name;
  final GoalCategory category;
  final double target;
  final double saved;
  final DateTime targetDate;
  final DateTime? completedDate;

  const SavingsGoal({
    required this.id,
    required this.name,
    required this.category,
    required this.target,
    required this.saved,
    required this.targetDate,
    this.completedDate,
  });

  bool get isCompleted => saved >= target;

  double get progress =>
      target <= 0 ? 0 : (saved / target).clamp(0.0, 1.0).toDouble();

  double get remaining =>
      (target - saved).clamp(0.0, double.infinity).toDouble();

  /// Whole months from now until the target month (minimum 1).
  int get monthsLeft {
    final now = DateTime.now();
    final m = (targetDate.year - now.year) * 12 + targetDate.month - now.month;
    return m < 1 ? 1 : m;
  }

  double get monthlyNeeded => remaining / monthsLeft;

  SavingsGoal copyWith({
    String? name,
    GoalCategory? category,
    double? target,
    double? saved,
    DateTime? targetDate,
    DateTime? completedDate,
  }) =>
      SavingsGoal(
        id: id,
        name: name ?? this.name,
        category: category ?? this.category,
        target: target ?? this.target,
        saved: saved ?? this.saved,
        targetDate: targetDate ?? this.targetDate,
        completedDate: completedDate ?? this.completedDate,
      );
}

const _mon = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

/// "Dec 2026"
String fmtMonthYear(DateTime d) => '${_mon[d.month - 1]} ${d.year}';

/// "RM5,000" (no decimals when whole)
String fmtRm(double v) {
  final whole = v == v.roundToDouble();
  final s = whole ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  final parts = s.split('.');
  final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
  return 'RM$intPart${parts.length > 1 ? '.${parts[1]}' : ''}';
}

/// TODO: replace with your service / database.
final List<SavingsGoal> sampleGoals = [
  SavingsGoal(
    id: 'g1',
    name: 'Emergency Fund',
    category: GoalCategory.emergency,
    target: 5000,
    saved: 3250,
    targetDate: DateTime(2026, 12),
  ),
  SavingsGoal(
    id: 'g2',
    name: 'Japan Trip',
    category: GoalCategory.travel,
    target: 3200,
    saved: 896,
    targetDate: DateTime(2027, 3),
  ),
  SavingsGoal(
    id: 'g3',
    name: 'New Laptop',
    category: GoalCategory.gadget,
    target: 4000,
    saved: 4000,
    targetDate: DateTime(2026, 6),
    completedDate: DateTime(2026, 6),
  ),
];
