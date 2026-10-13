import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// "Don't have an account? Sign up" at the bottom of the screen.
class AuthSwitchLink extends StatelessWidget {
  final String question;
  final String action;
  final VoidCallback onTap;

  const AuthSwitchLink({
    super.key,
    required this.question,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(question, style: AppTheme.body(13, color: AppColors.textMuted)),
          GestureDetector(
            onTap: onTap,
            child: Text(
              ' $action',
              style: AppTheme.body(
                13,
                weight: FontWeight.w800,
                color: AppColors.terracottaDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
