import 'package:flutter/material.dart';

import '../models/payment_method.dart';
import '../models/payment_transaction.dart';
import '../services/payment_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/payment_type_style.dart';
import '../utils/format_utils.dart';
import '../widgets/round_back_button.dart';
import '../widgets/slim_progress_bar.dart';
import 'payment_method_form_screen.dart';

class PaymentMethodDetailScreen extends StatelessWidget {
  final String methodId;

  const PaymentMethodDetailScreen({super.key, required this.methodId});

  Future<void> _edit(BuildContext context, PaymentMethod method) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentMethodFormScreen(existing: method),
      ),
    );
    // If it was deleted inside the form, leave this page too.
    if (!context.mounted) return;
    if (PaymentRepository.instance.byId(methodId) == null) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = PaymentRepository.instance;

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: repo,
          builder: (context, _) {
            final method = repo.byId(methodId);
            if (method == null) return const SizedBox.shrink();

            final transactions = repo.transactionsFor(methodId);

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                _Header(
                  title: method.title,
                  onEdit: () => _edit(context, method),
                ),
                const SizedBox(height: 20),
                _SummaryCard(method: method),
                if (method.limitUsage != null) ...[
                  const SizedBox(height: 16),
                  _LimitCard(method: method),
                ],
                const SizedBox(height: 22),
                Text(
                  'Last 7 days',
                  style: AppTheme.body(13, weight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                _WeekChart(
                  transactions: transactions,
                  barColor:
                      method.isIncome ? AppColors.sage : AppColors.terracotta,
                ),
                const SizedBox(height: 22),
                Text(
                  'Recent transactions',
                  style: AppTheme.body(13, weight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                _TransactionList(transactions: transactions),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onEdit;

  const _Header({required this.title, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: RoundBackButton(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.heading(18),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onEdit,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.terracottaDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: AppColors.paper,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: AppColors.border),
  );
}

class _SummaryCard extends StatelessWidget {
  final PaymentMethod method;

  const _SummaryCard({required this.method});

  @override
  Widget build(BuildContext context) {
    final amount = FormatUtils.rm(method.totalAmount);
    final n = method.transactionCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: method.type.tint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(method.type.icon, color: method.type.iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method.isIncome ? '+ $amount' : amount,
                  style: AppTheme.heading(24),
                ),
                const SizedBox(height: 2),
                Text(
                  '$n transaction${n == 1 ? '' : 's'} this month',
                  style: AppTheme.body(12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          if (method.isDefault)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.terracottaTint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Default',
                style: AppTheme.body(
                  10.5,
                  weight: FontWeight.w700,
                  color: AppColors.terracottaDark,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _LimitCard extends StatelessWidget {
  final PaymentMethod method;

  const _LimitCard({required this.method});

  @override
  Widget build(BuildContext context) {
    final usage = method.limitUsage ?? 0;
    final limit = method.monthlyLimit ?? 0;
    final warn = usage >= 0.8; // near or over the limit
    final color = warn ? AppColors.coral : AppColors.sage;

    final status = method.isOverLimit
        ? 'Over limit by ${FormatUtils.rm(method.totalAmount - limit)}'
        : '${FormatUtils.rm(limit - method.totalAmount)} left of '
            '${FormatUtils.rm(limit)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Monthly limit',
                  style: AppTheme.body(13, weight: FontWeight.w700),
                ),
              ),
              Text(
                '${(usage * 100).round()}% used',
                style: AppTheme.body(12, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SlimProgressBar(value: usage, color: color),
          const SizedBox(height: 10),
          Text(
            status,
            style: AppTheme.body(
              12.5,
              weight: FontWeight.w600,
              color: warn ? AppColors.coral : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

/// 7 little bars, one for each of the last 7 days (today is on the right).
class _WeekChart extends StatelessWidget {
  final List<PaymentTransaction> transactions;
  final Color barColor;

  const _WeekChart({required this.transactions, required this.barColor});

  static const _maxBarHeight = 80.0;
  static const _weekdayLetters = 'MTWTFSS';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = [
      for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i)),
    ];

    final totals = [
      for (final day in days)
        transactions
            .where((t) =>
                t.date.year == day.year &&
                t.date.month == day.month &&
                t.date.day == day.day)
            .fold<double>(0, (sum, t) => sum + t.amount),
    ];
    final biggest = totals.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      decoration: _cardDecoration(),
      child: SizedBox(
        height: _maxBarHeight + 28,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < days.length; i++)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 18,
                      height: totals[i] > 0 && biggest > 0
                          ? (totals[i] / biggest * _maxBarHeight)
                              .clamp(6.0, _maxBarHeight)
                          : 4,
                      decoration: BoxDecoration(
                        color: totals[i] > 0 ? barColor : AppColors.border,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _weekdayLetters[days[i].weekday - 1],
                      style: AppTheme.body(
                        11,
                        weight: i == days.length - 1
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: i == days.length - 1
                            ? AppColors.terracottaDark
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _TransactionList extends StatelessWidget {
  final List<PaymentTransaction> transactions;

  const _TransactionList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Text(
          'No transactions yet.',
          style: AppTheme.body(13, color: AppColors.textMuted),
        ),
      );
    }

    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < transactions.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: AppColors.border,
              ),
            _TransactionRow(transaction: transactions[i]),
          ],
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final PaymentTransaction transaction;

  const _TransactionRow({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final amount = FormatUtils.rm(transaction.amount);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: AppTheme.body(13.5, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  FormatUtils.dayLabel(transaction.date),
                  style: AppTheme.body(11.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Text(
            transaction.isIncome ? '+ $amount' : '- $amount',
            style: AppTheme.body(
              13,
              weight: FontWeight.w700,
              color: transaction.isIncome ? AppColors.sage : AppColors.coral,
            ),
          ),
        ],
      ),
    );
  }
}
