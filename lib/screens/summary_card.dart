import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color dotColor;
  final Color amountColor;

  const SummaryCard({
    super.key,
    required this.label,
    required this.amount,
    required this.dotColor,
    required this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ]),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'RM ${amount.toStringAsFixed(2)}',
              style: AppTheme.heading(16, color: amountColor),
            ),
          ),
        ],
      ),
    );
  }
}
