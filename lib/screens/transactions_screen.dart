import 'package:flutter/material.dart';
import '../models/transaction_item.dart';
import '../models/tx_filter.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'add_transaction_sheet.dart';
import 'filter_sheet.dart';
import 'add_transaction_screen.dart';
import 'edit_transaction_screen.dart';
import 'transaction_details_screen.dart';
import 'summary_card.dart';
import 'transaction_group_card.dart';
import 'quick_add_screen.dart';

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  // TODO: replace with data from your service / database.
  final List<TransactionItem> _all = [...sampleTransactions];

  DateTime _month = DateTime(2026, 8);
  TxFilter _filter = const TxFilter();

  String get _monthLabel => '${_monthNames[_month.month - 1]} ${_month.year}';

  void _shiftMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  List<TransactionItem> get _visible {
    final inMonth = _filter.hasDateRange
        ? _all
        : _all
            .where((t) =>
                t.date.year == _month.year && t.date.month == _month.month)
            .toList();
    return _filter.apply(inMonth);
  }

  Future<void> _onAdd() async {
    final mode = await showAddTransactionSheet(context);
    if (mode == null || !mounted) return;
    if (mode == AddMode.full) {
      final added = await Navigator.push<List<TransactionItem>>(
        context,
        MaterialPageRoute(
            builder: (_) => AddTransactionScreen(existing: _all)),
      );
      _addItems(added);
    } else {
      // TODO: build Scan receipt flow.
      final added = await Navigator.push<List<TransactionItem>>(
        context,
        MaterialPageRoute(builder: (_) => const QuickAddScreen()),
      );
      _addItems(added);
    }
  }

  void _addItems(List<TransactionItem>? added) {
    if (added == null || added.isEmpty) return;
    setState(() {
      _all.addAll(added);
      _month = DateTime(added.first.date.year, added.first.date.month);
    });
  }

  Future<void> _openDetails(TransactionItem t) async {
    final action = await Navigator.push<TransactionDetailAction>(
      context,
      MaterialPageRoute(builder: (_) => TransactionDetailsScreen(item: t)),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case TransactionDetailAction.edit:
        await _openEdit(t);
        break;
      case TransactionDetailAction.delete:
        setState(() => _all.removeWhere((x) => x.id == t.id));
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Transaction deleted')));
        break;
    }
  }

  Future<void> _openEdit(TransactionItem t) async {
    final r = await Navigator.push<EditTransactionResult>(
      context,
      MaterialPageRoute(
        builder: (_) => EditTransactionScreen(
          type: t.type,
          amount: t.amount,
          date: t.date,
          category: t.category,
          paymentMethod: t.paymentMethod,
          notes: t.title, // Notes field maps to title
        ),
      ),
    );
    if (r == null || !mounted) return;

    final title = r.notes.isEmpty ? r.category : r.notes;
    final replacements = r.splits.isEmpty
        ? [
            TransactionItem(
              id: t.id,
              title: title,
              category: r.category,
              amount: r.amount,
              type: r.type,
              date: r.date,
              paymentMethod: r.paymentMethod,
              receiptPath: t.receiptPath,
            )
          ]
        : [
            for (var i = 0; i < r.splits.length; i++)
              TransactionItem(
                id: '${t.id}_$i',
                title: title,
                category: r.splits[i].category,
                amount: r.splits[i].amount,
                type: r.type,
                date: r.date,
                paymentMethod: r.paymentMethod,
                receiptPath: t.receiptPath,
              )
          ];

    setState(() {
      final i = _all.indexWhere((x) => x.id == t.id);
      if (i == -1) return;
      _all
        ..removeAt(i)
        ..insertAll(i, replacements);
      _month = DateTime(r.date.year, r.date.month);
    });
  }

  Future<void> _openFilter() async {
    final result = await showFilterSheet(context, initial: _filter, all: _all);
    if (result != null) setState(() => _filter = result);
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible;
    final income = items
        .where((t) => t.type == TxType.income)
        .fold<double>(0, (s, t) => s + t.amount);
    final expense = items
        .where((t) => t.type == TxType.expense)
        .fold<double>(0, (s, t) => s + t.amount);

    // group by week (Monday start), keep sort order of first appearance
    final weeks = <DateTime, List<TransactionItem>>{};
    for (final t in items) {
      final d = DateTime(t.date.year, t.date.month, t.date.day);
      final monday = d.subtract(Duration(days: d.weekday - 1));
      weeks.putIfAbsent(monday, () => []).add(t);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(_monthLabel,
                      style: AppTheme.heading(17, color: AppColors.text)),
                  const Spacer(),
                  _roundIcon(Icons.search, _openFilter, active: _filter.isActive),
                  const SizedBox(width: 8),
                  _roundIcon(Icons.calendar_month_outlined, () {}),
                  const SizedBox(width: 8),
                  _roundIcon(Icons.calculate_outlined, () {}, filled: true),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                      onPressed: () => _shiftMonth(-1),
                      icon: const Icon(Icons.chevron_left,
                          color: AppColors.textMuted)),
                  Text(_monthLabel,
                      style: AppTheme.heading(20, color: AppColors.text)),
                  IconButton(
                      onPressed: () => _shiftMonth(1),
                      icon: const Icon(Icons.chevron_right,
                          color: AppColors.textMuted)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Expanded(
                    child: SummaryCard(
                        label: 'Income',
                        amount: income,
                        dotColor: AppColors.sage,
                        amountColor: AppColors.text)),
                const SizedBox(width: 10),
                Expanded(
                    child: SummaryCard(
                        label: 'Expense',
                        amount: expense,
                        dotColor: AppColors.terracottaDark,
                        amountColor: AppColors.terracottaDark)),
                const SizedBox(width: 10),
                Expanded(
                    child: SummaryCard(
                        label: 'Balance',
                        amount: income - expense,
                        dotColor: AppColors.gold,
                        amountColor: AppColors.gold)),
              ]),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text('No transactions found',
                          style: TextStyle(color: AppColors.textMuted)))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      children: [
                        for (final e in weeks.entries)
                          TransactionWeekCard(
                            weekStart: e.key,
                            items: e.value,
                            onTap: (t) => _openDetails(t),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.terracotta,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: _onAdd,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _roundIcon(IconData icon, VoidCallback onTap,
      {bool filled = false, bool active = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: filled ? AppColors.terracotta : AppColors.paper,
          shape: BoxShape.circle,
          border: Border.all(
              color: active ? AppColors.terracotta : AppColors.border),
        ),
        child: Icon(icon,
            size: 16,
            color: filled
                ? Colors.white
                : (active ? AppColors.terracotta : AppColors.textMuted)),
      ),
    );
  }
}