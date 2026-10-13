import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

enum AddMode { quick, full, scan }

/// Bottom sheet with the three ways to add a transaction.
/// Returns the chosen [AddMode], or null if dismissed.
Future<AddMode?> showAddTransactionSheet(BuildContext context) {
  return showModalBottomSheet<AddMode>(
    context: context,
    backgroundColor: AppColors.paper,
    barrierColor: Colors.black45,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _AddTransactionSheet(),
  );
}

class _AddTransactionSheet extends StatelessWidget {
  const _AddTransactionSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text('Add Transaction', style: AppTheme.heading(18)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                        color: AppColors.backgroundDeep, shape: BoxShape.circle),
                    child: const Icon(Icons.close,
                        size: 15, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _OptionCard(
              icon: Icons.bolt,
              iconBg: AppColors.terracotta,
              iconColor: Colors.white,
              title: 'Quick add',
              subtitle: 'Add with enter name & price',
              highlighted: true,
              onTap: () => Navigator.pop(context, AddMode.quick),
            ),
            const SizedBox(height: 12),
            _OptionCard(
              icon: Icons.edit_note,
              iconBg: AppColors.sageTint,
              iconColor: AppColors.sage,
              title: 'Full entry',
              subtitle: 'Enter all fields',
              onTap: () => Navigator.pop(context, AddMode.full),
            ),
            const SizedBox(height: 12),
            _OptionCard(
              icon: Icons.photo_camera_outlined,
              iconBg: AppColors.goldTint,
              iconColor: AppColors.gold,
              title: 'Scan receipt',
              subtitle: 'Snap & fill',
              onTap: () => Navigator.pop(context, AddMode.scan),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool highlighted;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted ? AppColors.terracottaTint : AppColors.paper,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color:
                    highlighted ? AppColors.terracotta : AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                    color: iconBg, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTheme.body(14, weight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: AppTheme.body(11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 20, color: AppColors.textFaint),
            ],
          ),
        ),
      ),
    );
  }
}
