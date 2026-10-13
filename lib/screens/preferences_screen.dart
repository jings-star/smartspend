import 'package:flutter/material.dart';

import '../services/preferences_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/budgeting_style_sheet.dart';
import '../widgets/currency_sheet.dart';
import '../widgets/round_back_button.dart';
import '../widgets/user_role_dialog.dart';

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            SizedBox(
              height: 36,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: RoundBackButton()),
                  Text('Preferences', style: AppTheme.heading(17)),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _PrefRow(
                    title: 'Preferred currency',
                    icon: Icons.payments_outlined,
                    tint: AppColors.terracottaTint,
                    value: PreferencesStore.currency,
                    onTap: () async {
                      final picked = await showCurrencySheet(context,
                          selected: PreferencesStore.currency.value);
                      if (picked != null) {
                        PreferencesStore.currency.value = picked;
                      }
                    },
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  _PrefRow(
                    title: 'Budgeting style',
                    icon: Icons.pie_chart_outline,
                    tint: AppColors.sageTint,
                    value: PreferencesStore.budgetStyle,
                    onTap: () async {
                      final picked = await showBudgetingStyleSheet(context,
                          selected: PreferencesStore.budgetStyle.value);
                      if (picked != null) {
                        PreferencesStore.budgetStyle.value = picked;
                      }
                    },
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  _PrefRow(
                    title: 'User role',
                    icon: Icons.badge_outlined,
                    tint: AppColors.goldTint,
                    value: PreferencesStore.role,
                    onTap: () async {
                      final picked = await showUserRoleDialog(context,
                          selected: PreferencesStore.role.value);
                      if (picked != null) {
                        PreferencesStore.role.value = picked;
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrefRow extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color tint;
  final ValueNotifier<String> value;
  final VoidCallback onTap;

  const _PrefRow({
    required this.title,
    required this.icon,
    required this.tint,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: AppColors.text),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTheme.body(13.5, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  ValueListenableBuilder<String>(
                    valueListenable: value,
                    builder: (_, v, __) => Text(v,
                        style:
                            AppTheme.body(11.5, color: AppColors.textMuted)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 20, color: AppColors.textFaint),
          ],
        ),
      ),
    );
  }
}
