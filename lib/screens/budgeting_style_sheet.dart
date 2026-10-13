import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

class _Style {
  final String title, description;
  const _Style(this.title, this.description);
}

const _styles = <_Style>[
  _Style('50 / 30 / 20 Rule', '50% needs · 30% wants · 20% savings'),
  _Style('Zero-Based Budget', 'Income minus expenses equals zero'),
  _Style('Envelope Method', 'Fixed cash "envelopes" per category'),
  _Style('Custom Category Budget', 'Set your own limits per category'),
];

/// Shows the "Budgeting style" sheet.
/// Returns the chosen style's title, or null if dismissed.
///
///   final style = await showBudgetingStyleSheet(context, selected: current);
Future<String?> showBudgetingStyleSheet(BuildContext context,
    {required String selected}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _BudgetingStyleSheet(selected: selected),
  );
}

class _BudgetingStyleSheet extends StatefulWidget {
  final String selected;
  const _BudgetingStyleSheet({required this.selected});

  @override
  State<_BudgetingStyleSheet> createState() => _BudgetingStyleSheetState();
}

class _BudgetingStyleSheetState extends State<_BudgetingStyleSheet> {
  late String _picked = widget.selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                    child:
                        Text('Budgeting style', style: AppTheme.heading(20))),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.backgroundDeep,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        size: 16, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how your monthly budget is structured.',
              style: AppTheme.body(12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            for (final s in _styles) ...[
              _StyleCard(
                style: s,
                selected: s.title == _picked,
                onTap: () => setState(() => _picked = s.title),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 4),
            PrimaryButton(
              label: 'Apply this style',
              color: AppColors.sage,
              onPressed: () => Navigator.pop(context, _picked),
            ),
          ],
        ),
      ),
    );
  }
}

class _StyleCard extends StatelessWidget {
  final _Style style;
  final bool selected;
  final VoidCallback onTap;
  const _StyleCard(
      {required this.style, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.sageTint : AppColors.paper,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.sage : AppColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(style.title,
                      style: AppTheme.body(12.5, weight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(style.description, style: AppTheme.body(13.5)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _Radio(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  final bool selected;
  const _Radio({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.sage : AppColors.textFaint,
          width: 1.5,
        ),
      ),
      child: selected
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.sage,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}
