import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'icon_badge.dart';
import 'outline_action_button.dart';
import 'primary_button.dart';

/// A bottom sheet that asks "Are you sure?".
/// Returns true if the user confirms, false if they cancel.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  required String confirmLabel,
  Color iconBackground = AppColors.coralTint,
  Color iconColor = AppColors.coral,
  Color confirmColor = AppColors.coral,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconBadge(
              icon: icon,
              background: iconBackground,
              iconColor: iconColor,
            ),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center, style: AppTheme.heading(22)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.body(12.5, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: confirmLabel,
              color: confirmColor,
              onPressed: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: 10),
            OutlineActionButton(
              label: 'Cancel',
              borderColor: AppColors.border,
              textColor: AppColors.text,
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}
