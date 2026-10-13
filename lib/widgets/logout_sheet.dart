import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'icon_badge.dart';
import 'outline_action_button.dart';
import 'primary_button.dart';

/// Shows the "Log out of SmartSpend?" sheet from the bottom.
/// Returns true if the user tapped "Log out", false otherwise.
///
/// Use it like this:
///   final confirmed = await showLogoutSheet(context);
///   if (confirmed) { ...log the user out... }
Future<bool> showLogoutSheet(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _LogoutSheet(),
  );
  return result ?? false;
}

class _LogoutSheet extends StatelessWidget {
  const _LogoutSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const IconBadge(
              icon: Icons.logout,
              background: AppColors.coralTint,
              iconColor: AppColors.coral,
            ),
            const SizedBox(height: 14),
            Text(
              'Log out of SmartSpend?',
              textAlign: TextAlign.center,
              style: AppTheme.heading(22),
            ),
            const SizedBox(height: 8),
            Text(
              'Your data stays backed up.\nYou can log back in anytime.',
              textAlign: TextAlign.center,
              style: AppTheme.body(12.5, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Log out',
              color: AppColors.coral,
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
    );
  }
}
