import 'package:flutter/material.dart';
import '../models/savings_goal.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// "Remove this goal?" confirmation (Image 4.1.4). Returns true if confirmed.
Future<bool> showGoalRemoveSheet(BuildContext context, SavingsGoal goal) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.coral.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline,
                  color: Color(0xFFB4533F), size: 24),
            ),
            const SizedBox(height: 14),
            Text('Remove this goal?', style: AppTheme.heading(22)),
            const SizedBox(height: 10),
            Text(
              'This will permanently delete "${goal.name}" and its saved '
              'progress of ${fmtRm(goal.saved)}. This cannot be undone.',
              textAlign: TextAlign.center,
              style: AppTheme.body(12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Cancel',
                        style: AppTheme.body(13,
                            weight: FontWeight.w700, color: AppColors.text)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB4533F),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Remove goal',
                        style: AppTheme.body(13,
                            weight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    ),
  );
  return ok ?? false;
}
