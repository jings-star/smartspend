import 'package:flutter/material.dart';

import '../models/recurring_transaction.dart';
import '../services/recurring_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/recurring_form_sheet.dart';
import '../widgets/round_back_button.dart';

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  final _store = RecurringStore.instance;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.terracotta,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        onPressed: () => showRecurringFormSheet(context),
        child: const Icon(Icons.add, size: 28),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([_store, _search]),
          builder: (context, _) {
            final all = _store.items;
            final q = _search.text.trim().toLowerCase();
            final shown = all
                .where((t) =>
                    q.isEmpty ||
                    t.name.toLowerCase().contains(q) ||
                    t.category.toLowerCase().contains(q))
                .toList();

            final active = shown.where((t) => t.active).toList()
              ..sort((a, b) => a.nextDue.compareTo(b.nextDue));
            final paused = shown.where((t) => !t.active).toList();
            final thisWeek = active.where((t) => t.daysUntilDue <= 7).toList();
            final later = active.where((t) => t.daysUntilDue > 7).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
              children: [
                _TopBar(onSearch: _toggleSearch, searching: _searching),
                if (_searching) ...[
                  const SizedBox(height: 12),
                  _SearchField(controller: _search),
                ],
                const SizedBox(height: 16),
                _SummaryCard(items: all),
                const SizedBox(height: 22),
                if (all.isEmpty)
                  const _EmptyState(
                    title: 'No recurring transactions yet',
                    message: 'Tap + to add rent, subscriptions or bills.',
                  )
                else if (shown.isEmpty)
                  const _EmptyState(
                    title: 'No matches',
                    message: 'Try a different name or category.',
                  )
                else ...[
                  if (thisWeek.isNotEmpty)
                    _Section(title: 'UPCOMING THIS WEEK', items: thisWeek),
                  if (later.isNotEmpty)
                    _Section(title: 'COMING LATER', items: later),
                  if (paused.isNotEmpty)
                    _Section(title: 'PAUSED', items: paused),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onSearch;
  final bool searching;
  const _TopBar({required this.onSearch, required this.searching});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Align(
              alignment: Alignment.centerLeft, child: RoundBackButton()),
          Text('Recurring', style: AppTheme.heading(20)),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onSearch,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: searching
                      ? AppColors.terracottaTint
                      : AppColors.paper,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(
                  searching ? Icons.close : Icons.search,
                  size: 19,
                  color: AppColors.text,
                ),
              ),
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
        hintText: 'Search by name or category...',
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
  final List<RecurringTransaction> items;
  const _SummaryCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final active = items.where((t) => t.active).toList();
    final pausedCount = items.length - active.length;
    final total = active
        .where((t) => t.type == RecurringType.expense)
        .fold<double>(0, (sum, t) => sum + t.monthlyAmount);

    String nextDue = '—';
    if (active.isNotEmpty) {
      final days =
          active.map((t) => t.daysUntilDue).reduce((a, b) => a < b ? a : b);
      nextDue = days == 0 ? 'Today' : (days == 1 ? '1 day' : '$days days');
    }

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
                  'MONTHLY RECURRING TOTAL',
                  style: AppTheme.body(10.5,
                      weight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.85)),
                ),
                const SizedBox(height: 6),
                Text(
                  '${currencySymbol()} ${formatMoney(total)}',
                  style: AppTheme.heading(30, color: Colors.white),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _Stat(value: '${active.length}', label: 'ACTIVE'),
                    const SizedBox(width: 22),
                    _Stat(value: '$pausedCount', label: 'PAUSED'),
                    const SizedBox(width: 22),
                    _Stat(value: nextDue, label: 'NEXT DUE'),
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

class _Section extends StatelessWidget {
  final String title;
  final List<RecurringTransaction> items;
  const _Section({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              title,
              style: AppTheme.body(10.5,
                  weight: FontWeight.w700, color: AppColors.textMuted),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  _TxRow(item: items[i]),
                  if (i != items.length - 1)
                    const Divider(height: 1, color: AppColors.border),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  final RecurringTransaction item;
  const _TxRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final style = categoryStyleFor(item.category);
    final isIncome = item.type == RecurringType.income;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => showRecurringFormSheet(context, existing: item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
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
                  Text(item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.body(13.5, weight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(
                    '${item.category} • ${item.frequency.label}\nNext ${shortDate(item.nextDue)}',
                    style: AppTheme.body(10.5,
                        color: AppColors.textMuted, weight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'} ${currencySymbol()} ${formatMoney(item.amount)}',
                  style: AppTheme.body(
                    13,
                    weight: FontWeight.w800,
                    color: isIncome ? AppColors.sage : AppColors.text,
                  ),
                ),
                const SizedBox(height: 6),
                _StatusChip(active: item.active),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool active;
  const _StatusChip({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? AppColors.sageTint : AppColors.goldTint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        active ? 'ACTIVE' : 'PAUSED',
        style: AppTheme.body(
          9,
          weight: FontWeight.w800,
          color: active ? AppColors.sage : AppColors.gold,
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
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.terracottaTint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.event_repeat_outlined,
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
    );
  }
}
