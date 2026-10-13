import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// White pill button with a "G". Replace the G with the real Google logo
/// image later if you like.
class GoogleButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const GoogleButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.paper,
          side: const BorderSide(color: AppColors.border),
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'G',
              style: AppTheme.body(
                18,
                weight: FontWeight.w800,
                color: const Color(0xFFDB4437),
              ),
            ),
            const SizedBox(width: 8),
            Text('Google', style: AppTheme.body(14, weight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
