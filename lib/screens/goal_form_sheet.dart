import 'package:flutter/material.dart';
import '../models/savings_goal.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// "Create new goal" sheet (Image 4.1.3). Pass [initial] to edit.
/// Returns the new / updated goal, or null when cancelled.
Future<SavingsGoal?> showGoalFormSheet(BuildContext context,
    {SavingsGoal? initial}) {
  return showModalBottomSheet<SavingsGoal>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => _GoalForm(initial: initial),
  );
}

class _GoalForm extends StatefulWidget {
  const _GoalForm({this.initial});
  final SavingsGoal? initial;

  @override
  State<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends State<_GoalForm> {
  late final _nameCtrl = TextEditingController(text: widget.initial?.name ?? '');
  late final _amountCtrl = TextEditingController(
      text: widget.initial == null
          ? ''
          : widget.initial!.target.toStringAsFixed(0));
  late GoalCategory _category =
      widget.initial?.category ?? GoalCategory.emergency;
  late DateTime _date = widget.initial?.targetDate ??
      DateTime(DateTime.now().year, DateTime.now().month + 6);
  String? _error;

  bool get _isEdit => widget.initial != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(now) ? now : _date,
      firstDate: now,
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null) setState(() => _date = DateTime(picked.year, picked.month));
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim().replaceAll(',', ''));
    if (name.isEmpty) return setState(() => _error = 'Enter a goal name');
    if (amount == null || amount <= 0) {
      return setState(() => _error = 'Enter a target amount greater than 0');
    }
    final base = widget.initial;
    Navigator.pop(
      context,
      SavingsGoal(
        id: base?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        category: _category,
        target: amount,
        saved: base?.saved ?? 0,
        targetDate: _date,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: Text(_isEdit ? 'Edit goal' : 'Create new goal',
                      style: AppTheme.heading(18)),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close,
                      size: 20, color: AppColors.textMuted),
                ),
              ]),
              const SizedBox(height: 16),
              _label('Goal name'),
              const SizedBox(height: 6),
              TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.sentences,
                style: AppTheme.body(14, weight: FontWeight.w600),
                decoration: _inputDeco('e.g. Laptop for internship'),
              ),
              const SizedBox(height: 16),
              _label('Category'),
              const SizedBox(height: 8),
              Row(children: [
                for (final c in GoalCategory.values) ...[
                  _categoryChip(c),
                  const SizedBox(width: 10),
                ],
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Target amount'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: AppTheme.body(14, weight: FontWeight.w600),
                        decoration:
                            _inputDeco('4,000').copyWith(prefixText: 'RM '),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Target date'),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          height: 48,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(fmtMonthYear(_date),
                              style: AppTheme.body(14,
                                  weight: FontWeight.w600,
                                  color: AppColors.textMuted)),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              Text(
                'Tip: shorter timelines need bigger monthly contributions — '
                'the AI assistant can help you check what\'s realistic.',
                style: AppTheme.body(11, color: AppColors.textMuted),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style: AppTheme.body(12,
                        weight: FontWeight.w600,
                        color: AppColors.terracottaDark)),
              ],
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                      ),
                      child: Text('Cancel',
                          style: AppTheme.body(13,
                              weight: FontWeight.w700, color: AppColors.text)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.terracotta,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                      ),
                      child: Text(_isEdit ? 'Save goal' : 'Create goal',
                          style: AppTheme.body(13,
                              weight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String s) => Text(s,
      style: AppTheme.body(12,
          weight: FontWeight.w700, color: AppColors.textMuted));

  InputDecoration _inputDeco(String hint) => InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.background,
        hintText: hint,
        hintStyle: AppTheme.body(14,
            weight: FontWeight.w500, color: AppColors.textFaint),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.terracotta),
        ),
      );

  Widget _categoryChip(GoalCategory c) {
    final selected = _category == c;
    return GestureDetector(
      onTap: () => setState(() => _category = c),
      child: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.tint,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.terracottaDark : Colors.transparent,
            width: 1.8,
          ),
        ),
        child: Text(c.emoji, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}
