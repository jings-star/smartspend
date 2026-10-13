import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Soft green box with a check mark and a short message.
class InfoBanner extends StatelessWidget {
  final String text;
  final IconData icon;

  const InfoBanner({
    super.key,
    required this.text,
    this.icon = Icons.check,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.sageTint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: AppColors.text),
          const SizedBox(width: 8),
          Text(text, style: AppTheme.body(12.5, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}
