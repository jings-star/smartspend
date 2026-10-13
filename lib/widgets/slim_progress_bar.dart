import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A thin bar that fills from the LEFT. value: 0.0 (empty) to 1.0 (full).
class SlimProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;

  const SlimProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.terracotta,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(height / 2);

    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.backgroundDeep,
          borderRadius: radius,
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: value.clamp(0.0, 1.0),
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, borderRadius: radius),
          ),
        ),
      ),
    );
  }
}
