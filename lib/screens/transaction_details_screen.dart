import 'package:flutter/material.dart';
import '../models/transaction_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

/// What the user chose on the details screen.
enum TransactionDetailAction { edit, delete }

/// Shown after tapping a transaction. Pops with a [TransactionDetailAction]
/// (or null if the user just goes back). The caller does the actual
/// editing / deleting.
class TransactionDetailsScreen extends StatelessWidget {
  const TransactionDetailsScreen({super.key, required this.item});

  final TransactionItem item;

  bool get _isExpense => item.type == TxType.expense;

  String get _amountLabel =>
      '${_isExpense ? '-' : '+'} RM ${item.amount.toStringAsFixed(2)}';

  String get _dateLabel {
    final d = item.date;
    final now = DateTime.now();
    final isToday =
        d.year == now.year && d.month == now.month && d.day == now.day;
    final base = isToday ? 'Today' : '${d.day} ${_months[d.month - 1]} ${d.year}';
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final ap = d.hour >= 12 ? 'PM' : 'AM';
    return '$base, $h:$m $ap';
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete transaction?',
            style: AppTheme.heading(17, color: AppColors.text)),
        content: const Text('This action cannot be undone.',
            style: TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(
                    color: AppColors.terracottaDark,
                    fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      Navigator.pop(context, TransactionDetailAction.delete);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasReceipt =
        item.receiptPath != null && item.receiptPath!.isNotEmpty;
    final receiptName =
        hasReceipt ? item.receiptPath!.split('/').last : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.chevron_left,
                            size: 20, color: AppColors.text),
                      ),
                    ),
                  ),
                  Text('Transaction Details',
                      style: AppTheme.heading(17, color: AppColors.text)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.terracotta.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(item.emoji,
                          style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(_amountLabel,
                        style: AppTheme.heading(26, color: AppColors.text)),
                  ),
                  const SizedBox(height: 20),
                  _card(
                    child: Column(children: [
                      _row('Date', _chip(_dateLabel, icon: '📅')),
                      const Divider(height: 1, color: AppColors.border),
                      _row('Category',
                          _chip(item.category, icon: item.emoji)),
                      _row('Payment method',
                          _chip(item.paymentMethod, icon: '👛')),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  _card(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('NOTE',
                            style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 0.6,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textFaint)),
                        const SizedBox(height: 4),
                        Text(item.title,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text)),
                      ],
                    ),
                  ),
                  if (hasReceipt) ...[
                    const SizedBox(height: 18),
                    const Text('Receipt',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {/* TODO: open receipt viewer */},
                      child: _card(
                        padding: const EdgeInsets.all(12),
                        child: Row(children: [
                          Container(
                            width: 56,
                            height: 68,
                            decoration: BoxDecoration(
                              color: AppColors.border.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.receipt_long_outlined,
                                color: AppColors.textMuted),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(receiptName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.text)),
                          ),
                          const Icon(Icons.chevron_right,
                              size: 18, color: AppColors.textMuted),
                        ]),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  _button('Edit transaction', AppColors.sage,
                      () => Navigator.pop(
                          context, TransactionDetailAction.edit)),
                  const SizedBox(height: 14),
                  _button('Delete', AppColors.terracotta,
                      () => _confirmDelete(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 16),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Widget _row(String label, Widget value) {
    return SizedBox(
      height: 54,
      child: Row(children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.text)),
        const Spacer(),
        value,
      ]),
    );
  }

  Widget _chip(String text, {required String icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.terracotta.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(icon, style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 5),
        Text(text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.terracottaDark)),
      ]),
    );
  }

  Widget _button(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: color.withOpacity(0.4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
      ),
    );
  }
}
