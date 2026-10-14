import 'package:flutter/material.dart';

import '../services/preferences_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/currency_sheet.dart';
import '../widgets/round_back_button.dart';

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  static const _roles = ['Student', 'Working Adult'];
  static const _styles = [
    '50 / 30 / 20 Rule',
    'Zero-Based Budgeting',
    'Pay Yourself First',
    'Envelope Method',
  ];
  static const _languages = ['English', 'Bahasa Melayu', '中文'];
  static const _themes = ['Light', 'Dark', 'System'];

  Future<void> _pickCurrency(BuildContext context) async {
    final picked = await showCurrencySheet(
      context,
      selected: PreferencesStore.currency.value,
    );
    if (picked != null) {
      PreferencesStore.currency.value = picked;
      PreferencesStore.save();
    }
  }

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
                    child: RoundBackButton(),
                  ),
                  Text('Preferences', style: AppTheme.heading(17)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Preferred currency
            _Card(
              title: 'Preferred currency',
              icon: Icons.payments_outlined,
              tint: AppColors.sageTint,
              child: ValueListenableBuilder<String>(
                valueListenable: PreferencesStore.currency,
                builder: (_, code, __) => InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _pickCurrency(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(code,
                              style:
                                  AppTheme.body(14, weight: FontWeight.w700)),
                        ),
                        const Icon(Icons.chevron_right,
                            size: 20, color: AppColors.textFaint),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            _ChoiceCard(
              title: 'User type',
              icon: Icons.school_outlined,
              tint: AppColors.terracottaTint,
              options: _roles,
              notifier: PreferencesStore.role,
            ),
            const SizedBox(height: 14),
            _ChoiceCard(
              title: 'Budgeting style',
              icon: Icons.pie_chart_outline,
              tint: AppColors.goldTint,
              options: _styles,
              notifier: PreferencesStore.budgetStyle,
            ),
            const SizedBox(height: 14),
            _ChoiceCard(
              title: 'Language',
              icon: Icons.language,
              tint: AppColors.coralTint,
              options: _languages,
              notifier: PreferencesStore.language,
            ),
            const SizedBox(height: 14),
            _ChoiceCard(
              title: 'Theme',
              icon: Icons.brightness_6_outlined,
              tint: AppColors.sageTint,
              options: _themes,
              notifier: PreferencesStore.theme,
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color tint;
  final Widget child;
  const _Card({
    required this.title,
    required this.icon,
    required this.tint,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              Text(title, style: AppTheme.body(13.5, weight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color tint;
  final List<String> options;
  final ValueNotifier<String> notifier;
  const _ChoiceCard({
    required this.title,
    required this.icon,
    required this.tint,
    required this.options,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: title,
      icon: icon,
      tint: tint,
      child: ValueListenableBuilder<String>(
        valueListenable: notifier,
        builder: (_, selected, __) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in options)
              GestureDetector(
                onTap: () {
                  notifier.value = o;
                  PreferencesStore.save();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: o == selected
                        ? AppColors.terracotta
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: o == selected
                          ? AppColors.terracotta
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    o,
                    style: AppTheme.body(
                      12,
                      weight: FontWeight.w700,
                      color: o == selected ? Colors.white : AppColors.text,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}