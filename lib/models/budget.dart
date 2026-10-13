enum BudgetPeriod { weekly, monthly, yearly }

extension BudgetPeriodX on BudgetPeriod {
  String get label => switch (this) {
        BudgetPeriod.weekly => 'Weekly',
        BudgetPeriod.monthly => 'Monthly',
        BudgetPeriod.yearly => 'Yearly',
      };

  /// Multiply a per-period amount by this to get a per-month amount.
  double get monthlyFactor => switch (this) {
        BudgetPeriod.weekly => 52 / 12,
        BudgetPeriod.monthly => 1,
        BudgetPeriod.yearly => 1 / 12,
      };
}

enum BudgetStatus { safe, warning, over }

/// Allowed "alert at" percentages, shown as chips in the budget form.
const budgetAlertThresholds = [50, 70, 80, 90];
const defaultBudgetAlertThreshold = 90;

class Budget {
  final String id;
  final String category;
  final double amount;
  final BudgetPeriod period;
  final double spent;
  final bool alertEnabled;

  /// Percent (50, 70, 80, 90) at which the budget turns to "warning".
  final int alertThreshold;

  /// Optional amounts for weeks 1-4 of the month (set by the Weekly split page).
  final List<double>? weeklySplit;

  const Budget({
    required this.id,
    required this.category,
    required this.amount,
    this.period = BudgetPeriod.monthly,
    this.spent = 0,
    this.alertEnabled = true,
    this.alertThreshold = defaultBudgetAlertThreshold,
    this.weeklySplit,
  });

  Budget copyWith({
    String? category,
    double? amount,
    BudgetPeriod? period,
    double? spent,
    bool? alertEnabled,
    int? alertThreshold,
    List<double>? weeklySplit,
  }) {
    return Budget(
      id: id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      spent: spent ?? this.spent,
      alertEnabled: alertEnabled ?? this.alertEnabled,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      weeklySplit: weeklySplit ?? this.weeklySplit,
    );
  }

  double get progress => amount <= 0 ? 0 : spent / amount;

  int get percent => (progress * 100).round();

  BudgetStatus get status {
    if (progress > 1) return BudgetStatus.over;
    // Remove `alertEnabled &&` if you want the warning colour even when
    // alerts are switched off.
    if (alertEnabled && progress >= alertThreshold / 100) {
      return BudgetStatus.warning;
    }
    return BudgetStatus.safe;
  }
}