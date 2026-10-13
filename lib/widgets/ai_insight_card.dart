import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// The gold card with smart tips. Gold is only used for smart/AI features.
class AiInsightCard extends StatelessWidget {
  final List<String> insights;

  const AiInsightCard({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.goldTint,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 18,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SMART INSIGHT',
                  style: AppTheme.body(
                    11,
                    weight: FontWeight.w800,
                    color: AppColors.textMuted,
                  ).copyWith(letterSpacing: 0.6),
                ),
                const SizedBox(height: 6),
                for (final insight in insights)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      insight,
                      style: AppTheme.body(13).copyWith(height: 1.4),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
