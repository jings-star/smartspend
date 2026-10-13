import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Small rounded square with an icon inside (used on top of dialogs/screens).
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color iconColor;

  const IconBadge({
    super.key,
    required this.icon,
    this.background = AppColors.terracottaTint,
    this.iconColor = AppColors.terracottaDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, size: 22, color: iconColor),
    );
  }
}
