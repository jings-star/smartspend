import 'package:flutter/material.dart';
import '../models/transaction_item.dart';
import '../theme/app_colors.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];
const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String _rm(double v) => 'RM ${v.toStringAsFixed(2)}';

/// One week block: header (week range + expense total) and day sections.
class TransactionWeekCard extends StatelessWidget {
  final DateTime weekStart; // Monday
  final List<TransactionItem> items;
  final ValueChanged<TransactionItem>? onTap;

  const TransactionWeekCard({
    super.key,
    required this.weekStart,
    required this.items,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekExpense = items
        .where((t) => t.type == TxType.expense)
        .fold<double>(0, (s, t) => s + t.amount);

    // group by day (items are already sorted)
    final byDay = <DateTime, List<TransactionItem>>{};
    for (final t in items) {
      final k = DateTime(t.date.year, t.date.month, t.date.day);
      byDay.putIfAbsent(k, () => []).add(t);
    }
    final dayKeys = byDay.keys.toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: AppColors.backgroundDeep,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.date_range_outlined,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'WEEK OF ${weekStart.day} ${_months[weekStart.month - 1].toUpperCase()}'
                    ' – ${weekEnd.day} ${_months[weekEnd.month - 1].toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .4,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Text(_rm(weekExpense),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.terracottaDark)),
              ],
            ),
          ),
          for (int i = 0; i < dayKeys.length; i++) ...[
            _DaySection(
              date: dayKeys[i],
              items: byDay[dayKeys[i]]!,
              onTap: onTap,
            ),
            if (i != dayKeys.length - 1) const _DashedDivider(),
          ],
        ],
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  final DateTime date;
  final List<TransactionItem> items;
  final ValueChanged<TransactionItem>? onTap;

  const _DaySection({required this.date, required this.items, this.onTap});

  @override
  Widget build(BuildContext context) {
    final dayExpense = items
        .where((t) => t.type == TxType.expense)
        .fold<double>(0, (s, t) => s + t.amount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          Row(
            children: [
              Text('${date.day} ${_months[date.month - 1]}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text)),
              const SizedBox(width: 6),
              Text(_days[date.weekday - 1],
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const Spacer(),
              if (dayExpense > 0)
                Text(_rm(dayExpense),
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.terracottaDark)),
            ],
          ),
          const SizedBox(height: 4),
          for (int i = 0; i < items.length; i++) ...[
            _TxTile(item: items[i], onTap: onTap),
            if (i != items.length - 1)
              const Divider(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  final TransactionItem item;
  final ValueChanged<TransactionItem>? onTap;
  const _TxTile({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isIncome = item.type == TxType.income;
    final tint = isIncome ? const Color(0xFFE3E8DC) : const Color(0xFFF3E4D6);

    return InkWell(
      onTap: onTap == null ? null : () => onTap!(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration:
                  BoxDecoration(color: tint, borderRadius: BorderRadius.circular(12)),
              child: Text(item.emoji, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text)),
                  Text(item.category,
                      style:
                          const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            Text(_rm(item.amount),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isIncome ? AppColors.sage : AppColors.terracottaDark)),
          ],
        ),
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(builder: (context, c) {
        final n = (c.maxWidth / 6).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            n,
            (_) => const SizedBox(
                width: 3, height: 1, child: ColoredBox(color: AppColors.border)),
          ),
        );
      }),
    );
  }
}
