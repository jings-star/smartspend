import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'outline_action_button.dart';
import 'primary_button.dart';

/// Shows "Delete this recurring transaction?".
/// Returns true only if the user taps Delete.
///
///   final ok = await showDeleteRecurringDialog(context);
Future<bool> showDeleteRecurringDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.paper,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: AppColors.coralTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline,
                  size: 20, color: AppColors.coral),
            ),
            const SizedBox(height: 14),
            Text(
              'Delete this recurring\ntransaction?',
              textAlign: TextAlign.center,
              style: AppTheme.heading(17),
            ),
            const SizedBox(height: 8),
            Text(
              "This can't be undone. Past transactions\nalready logged won't be affected.",
              textAlign: TextAlign.center,
              style: AppTheme.body(11.5, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlineActionButton(
                    label: 'Cancel',
                    borderColor: AppColors.border,
                    textColor: AppColors.text,
                    onPressed: () => Navigator.pop(ctx, false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Delete',
                    color: AppColors.coral,
                    onPressed: () => Navigator.pop(ctx, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}
