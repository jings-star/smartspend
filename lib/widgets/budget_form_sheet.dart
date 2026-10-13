import 'package:flutter/material.dart';

import '../models/budget.dart';
import '../models/recurring_transaction.dart'
    show categoryStyleFor, currencySymbol;
import '../services/budget_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../screens/weekly_split_screen.dart';
import 'confirm_delete_dialog.dart';
import 'form_parts.dart';
import 'primary_button.dart';

/// Opens the add / edit budget sheet.
/// Pass [existing] to edit (also shows the Delete link), or nothing to add.
/// The sheet saves to BudgetStore itself.
Future<void> showBudgetFormSheet(
  BuildContext context, {
  Budget? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _BudgetForm(existing: existing),
  );
}

class _BudgetForm extends StatefulWidget {
  final Budget? existing;
  const _BudgetForm({this.existing});

  @override
  State<_BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends State<_BudgetForm> {
  final _formKey = GlobalKey<FormState>();
  final _store = BudgetStore.instance;

  late final TextEditingController _amount;
  late final TextEditingController _spent;
  late final List<String> _categories;

  late String _category;
  late BudgetPeriod _period;
  late bool _alert;
  late int _alertThreshold;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _categories = _store.availableCategories(keep: e?.category);
    _category = e?.category ?? _categories.first;
    _period = e?.period ?? BudgetPeriod.monthly;
    _alert = e?.alertEnabled ?? true;
    _alertThreshold = e?.alertThreshold ?? defaultBudgetAlertThreshold;
    _amount = TextEditingController(
        text: e == null ? '' : e.amount.toStringAsFixed(2));
    _spent = TextEditingController(
        text: e == null ? '' : e.spent.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _amount.dispose();
    _spent.dispose();
    super.dispose();
  }

  double? _parse(String? v) =>
      double.tryParse((v ?? '').trim().replaceAll(',', ''));

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final b = Budget(
      id: widget.existing?.id ?? _store.newId(),
      category: _category,
      amount: _parse(_amount.text)!,
      period: _period,
      spent: _spent.text.trim().isEmpty ? 0 : _parse(_spent.text)!,
      alertEnabled: _alert,
      alertThreshold: _alertThreshold,
      weeklySplit: widget.existing?.weeklySplit,
    );

    final messenger = ScaffoldMessenger.of(context);
    _isEdit ? _store.update(b) : _store.add(b);
    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(
      content: Text(_isEdit ? 'Budget updated' : 'Budget added',
          style: AppTheme.body(13, color: Colors.white)),
    ));
  }

  void _openSplit() {
    final nav = Navigator.of(context);
    final b = widget.existing!;
    nav.pop();
    nav.push(MaterialPageRoute(builder: (_) => WeeklySplitScreen(budget: b)));
  }

  Future<void> _delete() async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Delete this budget?',
      message: "This can't be undone. Transactions already\n"
          "logged under this category won't be affected.",
    );
    if (!confirmed) return;
    _store.delete(widget.existing!.id);
    nav.pop();
    messenger.showSnackBar(SnackBar(
      content: Text('Budget deleted',
          style: AppTheme.body(13, color: Colors.white)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final symbol = currencySymbol();

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle + title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEdit ? 'Edit budget' : 'Add budget',
                        style: AppTheme.heading(17),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.close,
                            size: 16, color: AppColors.text),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FormLabel('CATEGORY'),
                    FormDropdown<String>(
                      value: _category,
                      items: _categories,
                      labelOf: (c) => c,
                      icon: categoryStyleFor(_category).icon,
                      onChanged: (c) => setState(() => _category = c),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FormLabel('BUDGET AMOUNT ($symbol)'),
                              FormInput.money(
                                controller: _amount,
                                hint: '0.00',
                                icon: Icons.attach_money,
                                validator: (v) {
                                  final n = _parse(v);
                                  if (n == null || n <= 0) {
                                    return 'Enter an amount';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FormLabel('PERIOD'),
                              FormDropdown<BudgetPeriod>(
                                value: _period,
                                items: BudgetPeriod.values,
                                labelOf: (p) => p.label,
                                onChanged: (p) =>
                                    setState(() => _period = p),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    FormLabel('ALREADY SPENT ($symbol)'),
                    FormInput.money(
                      controller: _spent,
                      hint: '0.00',
                      icon: Icons.receipt_long_outlined,
                      validator: (v) {
                        if ((v ?? '').trim().isEmpty) return null; // optional
                        final n = _parse(v);
                        if (n == null || n < 0) return 'Enter a valid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    FormSwitchRow(
                      title: 'Alert at $_alertThreshold%',
                      subtitle: "Get notified when you're close to the limit",
                      value: _alert,
                      onChanged: (v) => setState(() => _alert = v),
                    ),
                    if (_alert) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          for (int i = 0;
                              i < budgetAlertThresholds.length;
                              i++) ...[
                            Expanded(
                              child: _ThresholdChip(
                                percent: budgetAlertThresholds[i],
                                selected: _alertThreshold ==
                                    budgetAlertThresholds[i],
                                onTap: () => setState(() =>
                                    _alertThreshold =
                                        budgetAlertThresholds[i]),
                              ),
                            ),
                            if (i != budgetAlertThresholds.length - 1)
                              const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ],
                    if (_isEdit &&
                        widget.existing!.period == BudgetPeriod.monthly) ...[
                      const SizedBox(height: 4),
                      Center(
                        child: TextButton.icon(
                          onPressed: _openSplit,
                          icon: const Icon(Icons.calendar_view_week_outlined,
                              size: 16, color: AppColors.terracottaDark),
                          label: Text(
                            'Split by week',
                            style: AppTheme.body(12.5,
                                weight: FontWeight.w700,
                                color: AppColors.terracottaDark),
                          ),
                        ),
                      ),
                    ],
                    if (_isEdit) ...[
                      const SizedBox(height: 6),
                      Center(
                        child: TextButton.icon(
                          onPressed: _delete,
                          icon: const Icon(Icons.delete_outline,
                              size: 16, color: AppColors.coral),
                          label: Text(
                            'Delete budget',
                            style: AppTheme.body(12.5,
                                weight: FontWeight.w700,
                                color: AppColors.coral),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),

          // Pinned buttons (Cancel is the coral button, as in the design)
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              children: [
                PrimaryButton(
                  label: 'Save budget',
                  color: AppColors.sage,
                  onPressed: _save,
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: 'Cancel',
                  color: AppColors.coral,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThresholdChip extends StatelessWidget {
  final int percent;
  final bool selected;
  final VoidCallback onTap;
  const _ThresholdChip({
    required this.percent,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.terracotta : AppColors.paper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.terracotta : AppColors.border,
          ),
        ),
        child: Text(
          '$percent%',
          style: AppTheme.body(
            12.5,
            weight: FontWeight.w800,
            color: selected ? Colors.white : AppColors.text,
          ),
        ),
      ),
    );
  }
}