import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/budget.dart';
import '../models/recurring_transaction.dart'
    show categoryStyleFor, currencySymbol, formatMoney;
import '../services/budget_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/budget_assistant_sheet.dart';
import '../widgets/budget_form_sheet.dart';
import '../widgets/round_back_button.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _store = BudgetStore.instance;
  final _search = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) _search.clear();
    });
  }

  void _add() {
    if (_store.availableCategories().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Every category already has a budget',
            style: AppTheme.body(13, color: Colors.white)),
      ));
      return;
    }
    showBudgetFormSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.terracotta,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        onPressed: _add,
        child: const Icon(Icons.add, size: 28),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([_store, _search]),
          builder: (context, _) {
            final all = _store.items;
            final q = _search.text.trim().toLowerCase();
            final shown = all
                .where((b) => q.isEmpty || b.category.toLowerCase().contains(q))
                .toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
              children: [
                _TopBar(
                  onSearch: _toggleSearch,
                  searching: _searching,
                  onAssistant: () => showBudgetAssistantSheet(
                    context,
                    budgets: _store.items,
                  ),
                ),
                if (_searching) ...[
                  const SizedBox(height: 12),
                  _SearchField(controller: _search),
                ],
                const SizedBox(height: 16),
                _SummaryCard(budgets: all),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    'YOUR BUDGETS',
                    style: AppTheme.body(10.5,
                        weight: FontWeight.w700, color: AppColors.textMuted),
                  ),
                ),
                if (all.isEmpty)
                  const _EmptyState(
                    title: 'No budgets yet',
                    message: 'Tap + to set a spending limit for a category.',
                  )
                else if (shown.isEmpty)
                  const _EmptyState(
                    title: 'No matches',
                    message: 'Try a different category name.',
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < shown.length; i++) ...[
                          _BudgetRow(budget: shown[i]),
                          if (i != shown.length - 1)
                            const Divider(height: 1, color: AppColors.border),
                        ],
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

Color _statusColor(BudgetStatus s) => switch (s) {
      BudgetStatus.safe => AppColors.sage,
      BudgetStatus.warning => AppColors.gold,
      BudgetStatus.over => AppColors.coral,
    };

class _TopBar extends StatelessWidget {
  final VoidCallback onSearch;
  final VoidCallback onAssistant;
  final bool searching;
  const _TopBar({
    required this.onSearch,
    required this.onAssistant,
    required this.searching,
  });

  @override
  Widget build(BuildContext context) {
    Widget square({
      required IconData icon,
      required VoidCallback onTap,
      Color fill = AppColors.paper,
      Color iconColor = AppColors.text,
      Color? line,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: line ?? AppColors.border),
          ),
          child: Icon(icon, size: 19, color: iconColor),
        ),
      );
    }

    return SizedBox(
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Align(
              alignment: Alignment.centerLeft, child: RoundBackButton()),
          Text('Budgets', style: AppTheme.heading(20)),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                square(
                  icon: searching ? Icons.close : Icons.search,
                  onTap: onSearch,
                  fill: searching ? AppColors.terracottaTint : AppColors.paper,
                ),
                const SizedBox(width: 8),
                square(
                  icon: Icons.auto_awesome,
                  onTap: onAssistant,
                  fill: AppColors.terracotta,
                  iconColor: Colors.white,
                  line: AppColors.terracotta,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  const _SearchField({required this.controller});

  OutlineInputBorder _b(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c),
      );

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      cursorColor: AppColors.terracotta,
      style: AppTheme.body(13),
      decoration: InputDecoration(
        hintText: 'Search budgets...',
        hintStyle: AppTheme.body(13, color: AppColors.textFaint),
        filled: true,
        fillColor: AppColors.paper,
        prefixIcon: const Icon(Icons.search,
            size: 18, color: AppColors.terracottaDark),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: _b(AppColors.border),
        enabledBorder: _b(AppColors.border),
        focusedBorder: _b(AppColors.terracotta),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final List<Budget> budgets;
  const _SummaryCard({required this.budgets});

  @override
  Widget build(BuildContext context) {
    // Everything is converted to a per-month figure.
    double total = 0, spent = 0;
    for (final b in budgets) {
      total += b.amount * b.period.monthlyFactor;
      spent += b.spent * b.period.monthlyFactor;
    }
    final left = total - spent;
    final overCount =
        budgets.where((b) => b.status == BudgetStatus.over).length;
    final usedFraction = total <= 0 ? 0.0 : spent / total;
    final symbol = currencySymbol();

    final leftText = left >= 0
        ? '$symbol ${formatMoney(left)} left'
        : '$symbol ${formatMoney(-left)} over';

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.terracotta, AppColors.terracottaDark],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -50,
              top: -56,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL BUDGETED THIS MONTH',
                  style: AppTheme.body(10.5,
                      weight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.85)),
                ),
                const SizedBox(height: 6),
                Text(
                  '$symbol ${formatMoney(total)}',
                  style: AppTheme.heading(30, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  '$symbol ${formatMoney(spent)} spent · $leftText',
                  style: AppTheme.body(11,
                      color: Colors.white.withValues(alpha: 0.9)),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: usedFraction.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _Stat(value: '${budgets.length}', label: 'BUDGETS'),
                    const SizedBox(width: 22),
                    _Stat(value: '$overCount', label: 'OVER LIMIT'),
                    const SizedBox(width: 22),
                    _Stat(
                        value: '${(usedFraction * 100).round()}%',
                        label: 'USED'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: AppTheme.body(14,
                weight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label,
            style: AppTheme.body(9.5,
                weight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.85))),
      ],
    );
  }
}

class _BudgetRow extends StatelessWidget {
  final Budget budget;
  const _BudgetRow({required this.budget});

  @override
  Widget build(BuildContext context) {
    final style = categoryStyleFor(budget.category);
    final color = _statusColor(budget.status);
    final symbol = currencySymbol();

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => showBudgetFormSheet(context, existing: budget),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: style.tint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(style.icon, size: 20, color: style.ink),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(budget.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.body(13.5, weight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text('${budget.period.label} budget',
                          style: AppTheme.body(10.5,
                              color: AppColors.textMuted,
                              weight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$symbol ${formatMoney(budget.spent)}',
                            style: AppTheme.body(12.5,
                                weight: FontWeight.w800),
                          ),
                          TextSpan(
                            text: ' / ${formatMoney(budget.amount)}',
                            style: AppTheme.body(10.5,
                                color: AppColors.textMuted,
                                weight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text('${budget.percent}%',
                        style: AppTheme.body(11,
                            weight: FontWeight.w800, color: color)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: math.min(budget.progress, 1.0),
                minHeight: 5,
                backgroundColor: AppColors.backgroundDeep,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String message;
  const _EmptyState({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.terracottaTint,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.pie_chart_outline,
                  color: AppColors.terracottaDark),
            ),
            const SizedBox(height: 14),
            Text(title, style: AppTheme.heading(16)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTheme.body(12, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}