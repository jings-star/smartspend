import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Icons offered in the split sheet (same order as the design).
const List<String> kSplitIcons = ['🛍️', '🍔', '🚗', '🎁', '💊'];

/// One line of a split transaction.
class SplitLine {
  SplitLine({
    required this.label,
    required this.amount,
    this.icon = '🛍️',
  });

  String label;
  String icon;
  double amount;
}

/// Opens the "Add split" sheet. Pass [initial] to edit an existing split.
/// Returns the new / updated [SplitLine], or null if cancelled.
Future<SplitLine?> showSplitSheet(BuildContext context, {SplitLine? initial}) {
  return showModalBottomSheet<SplitLine>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => _SplitSheet(initial: initial),
  );
}

class _SplitSheet extends StatefulWidget {
  const _SplitSheet({this.initial});
  final SplitLine? initial;

  @override
  State<_SplitSheet> createState() => _SplitSheetState();
}

class _SplitSheetState extends State<_SplitSheet> {
  late String _icon = widget.initial?.icon ?? kSplitIcons.first;
  late final _labelCtrl = TextEditingController(text: widget.initial?.label ?? '');
  late final _amountCtrl = TextEditingController(
      text: widget.initial == null
          ? ''
          : widget.initial!.amount.toStringAsFixed(2));
  String? _error;

  bool get _isEdit => widget.initial != null;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final label = _labelCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (label.isEmpty) {
      setState(() => _error = 'Enter a label');
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter an amount greater than 0');
      return;
    }
    Navigator.pop(context, SplitLine(label: label, icon: _icon, amount: amount));
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
                    color: AppColors.gold.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(_isEdit ? 'Edit split' : 'Add split',
                  style: AppTheme.heading(18)),
              const SizedBox(height: 14),
              Text('Icon', style: AppTheme.body(12, weight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(children: [
                for (final e in kSplitIcons) ...[
                  _iconChip(e),
                  const SizedBox(width: 10),
                ],
              ]),
              const SizedBox(height: 16),
              _box(
                label: 'LABEL',
                child: TextField(
                  controller: _labelCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppTheme.body(14, weight: FontWeight.w600),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.only(top: 6),
                    hintText: 'e.g. Snacks',
                    hintStyle: AppTheme.body(14,
                        weight: FontWeight.w500, color: AppColors.textFaint),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _box(
                label: 'AMOUNT',
                child: Row(children: [
                  Text('RM',
                      style: AppTheme.body(14,
                          weight: FontWeight.w600, color: AppColors.textMuted)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _amountCtrl,
                      textAlign: TextAlign.right,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: AppTheme.body(14, weight: FontWeight.w700),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 6),
                        hintText: '0.00',
                        hintStyle: AppTheme.body(14,
                            weight: FontWeight.w600,
                            color: AppColors.textFaint),
                      ),
                    ),
                  ),
                ]),
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
                        backgroundColor: AppColors.sage,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                      ),
                      child: Text(_isEdit ? 'Save split' : 'Add split',
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

  Widget _iconChip(String emoji) {
    final selected = _icon == emoji;
    return GestureDetector(
      onTap: () => setState(() => _icon = emoji),
      child: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.terracotta : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 22)),
      ),
    );
  }

  Widget _box({required String label, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTheme.body(10,
                  weight: FontWeight.w700, color: AppColors.textFaint)),
          child,
        ],
      ),
    );
  }
}
