import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// White pill button with a colored border ("Back to login", "Cancel").
class OutlineActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color borderColor;
  final Color textColor;

  const OutlineActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.borderColor = AppColors.terracotta,
    this.textColor = AppColors.terracottaDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.paper,
          side: BorderSide(color: borderColor),
          shape: const StadiumBorder(),
        ),
        child: Text(
          label,
          style: AppTheme.body(14, weight: FontWeight.w700, color: textColor),
        ),
      ),
    );
  }
}
