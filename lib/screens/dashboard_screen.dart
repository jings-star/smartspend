import 'package:flutter/material.dart';
import '../models/savings_goal.dart';
import '../models/transaction_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'dashboard_ai_sheet.dart';
import '../widgets/dashboard_charts.dart';
import '../widgets/dashboard_data.dart';
import 'dashboard_sheets.dart';
import 'export_report_sheet.dart';

const _purple = Color(0xFF7B5EA7);
const _lavender = Color(0xFFEAE4F5);

class DashboardScreen extends StatefulWidget {
  /// Pass your real transactions / goals. When omitted, sample data
  /// (Apr - Jul 2026) is used so the screen matches the design.
  const DashboardScreen({super.key, this.transactions, this.goals});

  final List<TransactionItem>? transactions;
  final List<SavingsGoal>? goals;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final List<TransactionItem> _all =
      widget.transactions ?? buildDashboardSample();
  late final List<SavingsGoal> _goals = widget.goals ?? sampleGoals;
  late final List<DateTime> _months = monthsIn(_all);
  late DateTime _month = _months.isEmpty ? monthOf(DateTime.now()) : _months.last;

  int get _index => _months.indexWhere((m) => sameMonth(m, _month));

  /// The 4 most recent months shown in the trend chart.
  List<DateTime> get _chartMonths => _months.length <= 4
      ? _months
      : _months.sublist(_months.length - 4);

  void _shift(int delta) {
    final i = _index + delta;
    if (i < 0 || i >= _months.length) return;
    setState(() => _month = _months[i]);
  }

  Future<void> _chooseMonth() async {
    final m = await showMonthSheet(context, _months, _month);
    if (m != null) setState(() => _month = m);
  }

  @override
  Widget build(BuildContext context) {
    final stats = PeriodStats.month(_all, _month);
    final groups = pieGroups(stats);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            _header(stats),
            const SizedBox(height: 14),
            _monthSelector(),
            const SizedBox(height: 14),
            if (_all.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Center(
                  child: Text('No data yet. Add transactions to see your dashboard.',
                      textAlign: TextAlign.center,
                      style: AppTheme.body(13, color: AppColors.textMuted)),
                ),
              )
            else ...[
              _healthCard(stats),
              const SizedBox(height: 12),
              _insightCard(stats),
              const SizedBox(height: 12),
              _amountCard('INCOME', fmtMoney(stats.income), AppColors.sage),
              const SizedBox(height: 10),
              _amountCard(
                  'EXPENSES', fmtMoney(stats.expense), AppColors.terracottaDark),
              const SizedBox(height: 10),
              _balanceCard(stats),
              const SizedBox(height: 10),
              _projectedCard(stats),
              const SizedBox(height: 22),
              _sectionTitle('INCOME VS EXPENSES'),
              _hint('Tap the chart for a bigger weekly/monthly view'),
              const SizedBox(height: 8),
              const ChartLegend(),
              const SizedBox(height: 10),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => showIncomeExpenseSheet(context,
                    all: _all, months: _chartMonths, selected: _month),
                child: IncomeExpenseChart(
                  labels: [for (final m in _chartMonths) monthShort(m)],
                  data: monthlyTotals(_all, _chartMonths),
                ),
              ),
              const SizedBox(height: 22),
              _sectionTitle('SPENDING SHARE BY CATEGORY'),
              _hint('Tap the chart for a bigger weekly/monthly view'),
              const SizedBox(height: 12),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => showCategoryPieSheet(context,
                    all: _all, month: _month, stats: stats),
                child: Row(children: [
                  PieChartView(groups: groups, size: 96),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(children: [
                      for (final g in groups) _legendRow(g, stats),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 22),
              _sectionTitle('SPENDING BY CATEGORY'),
              const SizedBox(height: 10),
              for (final e in stats.categories)
                _categoryRow(e, stats.categories.first.value),
            ],
          ],
        ),
      ),
      // If your app shell already owns the bottom nav, remove this and
      // show this screen as a tab instead.
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.terracotta,
        unselectedItemColor: AppColors.textFaint,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.savings_outlined), label: 'Goals'),
          BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none), label: 'Alerts'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Account'),
        ],
      ),
    );
  }

  // ---------- header / month ----------

  Widget _header(PeriodStats stats) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dashboard', style: AppTheme.heading(28)),
              const SizedBox(height: 4),
              Text('Your financial overview at a glance.',
                  style: AppTheme.body(12, color: AppColors.textMuted)),
            ],
          ),
        ),
        _roundBtn(
          Icons.smart_toy_outlined,
          _purple,
          _lavender,
          () => showDashboardAssistantSheet(context,
              stats: stats, month: _month, goals: _goals),
        ),
        const SizedBox(width: 10),
        _roundBtn(
          Icons.description,
          AppColors.text,
          Colors.white,
          () => showExportReportSheet(context,
              all: _all, months: _months, month: _month, goals: _goals),
        ),
      ],
    );
  }

  Widget _roundBtn(IconData icon, Color fg, Color bg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 19, color: fg),
      ),
    );
  }

  Widget _monthSelector() {
    final canPrev = _index > 0;
    final canNext = _index >= 0 && _index < _months.length - 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _arrow(Icons.chevron_left, canPrev ? () => _shift(-1) : null),
        const SizedBox(width: 22),
        GestureDetector(
          onTap: _months.isEmpty ? null : _chooseMonth,
          child: Row(children: [
            Text(monthYear(_month),
                style: AppTheme.body(15, weight: FontWeight.w800)),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, size: 18, color: AppColors.textMuted),
          ]),
        ),
        const SizedBox(width: 22),
        _arrow(Icons.chevron_right, canNext ? () => _shift(1) : null),
      ],
    );
  }

  Widget _arrow(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon,
            size: 18,
            color: onTap == null ? AppColors.textFaint : AppColors.text),
      ),
    );
  }

  // ---------- cards ----------

  Widget _healthCard(PeriodStats s) {
    final prev = s.prevScore;
    final diff = prev == null ? null : s.healthScore - prev;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEADFD0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0D2BD)),
      ),
      child: Row(children: [
        HealthRing(score: s.healthScore, size: 54),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FINANCIAL HEALTH',
                  style: AppTheme.body(10,
                      weight: FontWeight.w800, color: AppColors.textMuted)),
              const SizedBox(height: 2),
              Text(s.healthLabel,
                  style: AppTheme.body(16, weight: FontWeight.w800)),
              if (diff != null) ...[
                const SizedBox(height: 2),
                Text(
                  diff >= 0
                      ? '↑ $diff points from last month'
                      : '↓ ${diff.abs()} points from last month',
                  style: AppTheme.body(11,
                      weight: FontWeight.w700,
                      color: diff >= 0
                          ? AppColors.sage
                          : AppColors.terracottaDark),
                ),
              ],
            ],
          ),
        ),
      ]),
    );
  }

  Widget _insightCard(PeriodStats s) {
    final top = s.categories.isEmpty ? null : s.categories.first;
    final change = s.expenseChangePct;
    final base = AppTheme.body(11, color: AppColors.text);

    final spans = <InlineSpan>[];
    if (top == null) {
      spans.add(TextSpan(text: 'No spending recorded this month.', style: base));
    } else {
      spans.addAll([
        TextSpan(
            text: top.key,
            style: AppTheme.body(11, weight: FontWeight.w800, color: _purple)),
        TextSpan(
            text:
                ' was your biggest expense this month at ${fmtMoney(top.value)} '
                '(${(top.value / s.totalExpenseForPct * 100).round()}% of spending).',
            style: base),
      ]);
      if (change != null) {
        spans.add(TextSpan(
            text:
                ' Overall spending is ${change >= 0 ? 'up' : 'down'} ${change.abs().round()}% vs last month.',
            style: base));
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _lavender,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9CFEE)),
      ),
      child: Text.rich(TextSpan(children: spans)),
    );
  }

  Widget _amountCard(String label, String amount, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTheme.body(10,
                  weight: FontWeight.w800, color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(amount, style: AppTheme.heading(22, color: color)),
        ],
      ),
    );
  }

  Widget _balanceCard(PeriodStats s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.terracotta,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('REMAINING BALANCE',
              style: AppTheme.body(10,
                  weight: FontWeight.w800,
                  color: Colors.white.withOpacity(0.85))),
          const SizedBox(height: 2),
          Text(fmtMoney(s.balance),
              style: AppTheme.heading(26, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _projectedCard(PeriodStats s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PROJECTED END-OF-MONTH BALANCE',
                  style: AppTheme.body(10,
                      weight: FontWeight.w800, color: AppColors.textMuted)),
              const SizedBox(height: 2),
              Text(fmtMoney(s.projectedBalance.roundToDouble()),
                  style: AppTheme.heading(20)),
            ],
          ),
        ),
        const Icon(Icons.show_chart, color: AppColors.textFaint),
      ]),
    );
  }

  // ---------- sections ----------

  Widget _sectionTitle(String s) => Text(s,
      style: AppTheme.body(11,
          weight: FontWeight.w800, color: AppColors.textMuted));

  Widget _hint(String s) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Center(
          child: Text(s, style: AppTheme.body(10, color: AppColors.textFaint)),
        ),
      );

  Widget _legendRow(PieGroup g, PeriodStats s) {
    final pct = (g.amount / s.totalExpenseForPct * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: g.color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(catEmoji(g.label), style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(g.label, style: AppTheme.body(11, weight: FontWeight.w600)),
        ),
        Text('$pct%', style: AppTheme.body(11, weight: FontWeight.w700)),
      ]),
    );
  }

  Widget _categoryRow(MapEntry<String, double> e, double max) {
    final color = catColor(e.key);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => showCategoryDetailSheet(context,
          all: _all, month: _month, category: e.key, total: e.value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(catEmoji(e.key), style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: Text(e.key,
                      style: AppTheme.body(12, weight: FontWeight.w800)),
                ),
                Text(fmtMoney(e.value),
                    style: AppTheme.body(11,
                        weight: FontWeight.w700, color: AppColors.textMuted)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: max <= 0 ? 0 : e.value / max,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.textFaint),
        ]),
      ),
    );
  }
}
