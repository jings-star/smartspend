import 'package:flutter/material.dart';
import '../models/transaction_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard_charts.dart';
import '../widgets/dashboard_data.dart';

/// Opens a white rounded sheet with the standard handle.
Future<T?> showDashSheet<T>(BuildContext context, WidgetBuilder builder,
    {bool tall = false}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    constraints: tall
        ? BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85)
        : null,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: builder,
  );
}

/// Handle + title row (with close button). Put the sheet body in [child].
class SheetShell extends StatelessWidget {
  const SheetShell({
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    required this.child,
    this.scrollBody = true,
  });

  final String? title;
  final Widget? titleWidget;
  final String? subtitle;
  final Widget child;

  /// When false, [child] must size itself (e.g. it contains an Expanded).
  final bool scrollBody;

  @override
  Widget build(BuildContext context) {
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      child: Column(children: [
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: titleWidget ??
                Text(title ?? '', style: AppTheme.heading(18)),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
          ),
        ]),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(subtitle!,
                style: AppTheme.body(12,
                    weight: FontWeight.w700, color: AppColors.textMuted)),
          ),
        ],
      ]),
    );

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          header,
          if (scrollBody)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: child,
              ),
            )
          else
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: child,
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Choose month
// ---------------------------------------------------------------------------

Future<DateTime?> showMonthSheet(
    BuildContext context, List<DateTime> months, DateTime selected) {
  return showDashSheet<DateTime>(
    context,
    (ctx) => SheetShell(
      title: 'Choose month',
      child: Column(children: [
        for (final m in months)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => Navigator.pop(ctx, m),
              child: Container(
                height: 46,
                width: double.infinity,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: sameMonth(m, selected)
                      ? AppColors.terracotta
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: sameMonth(m, selected)
                          ? AppColors.terracotta
                          : AppColors.border),
                ),
                child: Text(monthShortYear(m),
                    style: AppTheme.body(13,
                        weight: FontWeight.w800,
                        color: sameMonth(m, selected)
                            ? Colors.white
                            : AppColors.text)),
              ),
            ),
          ),
      ]),
    ),
  );
}

// ---------------------------------------------------------------------------
// Income vs Expenses (Weekly / Monthly)
// ---------------------------------------------------------------------------

Future<void> showIncomeExpenseSheet(
  BuildContext context, {
  required List<TransactionItem> all,
  required List<DateTime> months,
  required DateTime selected,
}) {
  return showDashSheet<void>(
    context,
    (_) => _IncomeExpenseSheet(all: all, months: months, selected: selected),
  );
}

class _IncomeExpenseSheet extends StatefulWidget {
  const _IncomeExpenseSheet(
      {required this.all, required this.months, required this.selected});
  final List<TransactionItem> all;
  final List<DateTime> months;
  final DateTime selected;

  @override
  State<_IncomeExpenseSheet> createState() => _IncomeExpenseSheetState();
}

class _IncomeExpenseSheetState extends State<_IncomeExpenseSheet> {
  bool _weekly = true;

  @override
  Widget build(BuildContext context) {
    final labels = _weekly
        ? ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4']
        : [for (final m in widget.months) monthShortYear(m)];
    final data = _weekly
        ? weeklyTotals(widget.all, widget.selected)
        : monthlyTotals(widget.all, widget.months);

    return SheetShell(
      title: 'Income vs Expenses',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: _toggle('Weekly', _weekly, () => setState(() => _weekly = true))),
            const SizedBox(width: 10),
            Expanded(child: _toggle('Monthly', !_weekly, () => setState(() => _weekly = false))),
          ]),
          const SizedBox(height: 18),
          const ChartLegend(),
          const SizedBox(height: 10),
          IncomeExpenseChart(
            labels: labels,
            data: data,
            height: 220,
            barWidth: 18,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _toggle(String label, bool on, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? AppColors.terracotta : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: on ? AppColors.terracotta : AppColors.border),
        ),
        child: Text(label,
            style: AppTheme.body(12,
                weight: FontWeight.w800,
                color: on ? Colors.white : AppColors.text)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Spending by category (pie)
// ---------------------------------------------------------------------------

Future<void> showCategoryPieSheet(
  BuildContext context, {
  required List<TransactionItem> all,
  required DateTime month,
  required PeriodStats stats,
}) {
  final groups = pieGroups(stats);
  return showDashSheet<void>(
    context,
    (_) => SheetShell(
      title: 'Spending by category',
      child: Column(children: [
        const SizedBox(height: 8),
        Center(child: PieChartView(groups: groups, size: 190)),
        const SizedBox(height: 18),
        Text(
          "Pie shows this month's share. Each row compares monthly % vs. this week's %.",
          textAlign: TextAlign.center,
          style: AppTheme.body(10, color: AppColors.textFaint),
        ),
        const SizedBox(height: 14),
        for (final g in groups)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: g.color, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Text(catEmoji(g.label), style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(g.label,
                    style: AppTheme.body(13, weight: FontWeight.w700)),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(
                    '${(g.amount / stats.totalExpenseForPct * 100).round()}% mo.',
                    style: AppTheme.body(12, weight: FontWeight.w800)),
                Text(
                    '${(lastWeekShare(all, month, g.names) * 100).round()}% this wk',
                    style: AppTheme.body(10, color: AppColors.textMuted)),
              ]),
            ]),
          ),
        const SizedBox(height: 12),
      ]),
    ),
  );
}

// ---------------------------------------------------------------------------
// Category detail: weekly records
// ---------------------------------------------------------------------------

Future<void> showCategoryDetailSheet(
  BuildContext context, {
  required List<TransactionItem> all,
  required DateTime month,
  required String category,
  required double total,
}) {
  final byWeek = recordsByWeek(all, month, {category});
  final count = byWeek.values.fold<int>(0, (s, l) => s + l.length);
  final weeks = byWeek.keys.toList()..sort();

  return showDashSheet<void>(
    context,
    tall: true,
    (_) => SheetShell(
      titleWidget: Row(children: [
        Text(catEmoji(category), style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(category, style: AppTheme.heading(18)),
      ]),
      subtitle:
          '${fmtMoney(total)} spent this month · $count transaction${count == 1 ? '' : 's'}',
      child: Column(children: [
        for (final w in weeks) ...[
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Row(children: [
              Text('WEEK ${w + 1}',
                  style: AppTheme.body(11,
                      weight: FontWeight.w800,
                      color: AppColors.terracottaDark)),
              const Spacer(),
              Text(
                  fmtMoney(byWeek[w]!.fold<double>(0, (s, t) => s + t.amount)),
                  style: AppTheme.body(11,
                      weight: FontWeight.w800,
                      color: AppColors.terracottaDark)),
            ]),
          ),
          const Divider(height: 1, color: AppColors.border),
          for (final t in byWeek[w]!)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(children: [
                SizedBox(
                  width: 52,
                  child: Text('${t.date.day} ${monthShort(t.date)}',
                      style: AppTheme.body(11,
                          weight: FontWeight.w600,
                          color: AppColors.textMuted)),
                ),
                Expanded(
                  child: Text(t.title,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.body(12, weight: FontWeight.w600)),
                ),
                Text(fmtMoney(t.amount),
                    style: AppTheme.body(12, weight: FontWeight.w800)),
              ]),
            ),
        ],
        if (weeks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Text('No transactions this month',
                style: AppTheme.body(12, color: AppColors.textMuted)),
          ),
      ]),
    ),
  );
}
