import 'package:flutter/material.dart';
import '../models/transaction_item.dart';
import '../models/tx_filter.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

String _fmt(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// Opens the filter sheet. Returns the new filter, or null if dismissed.
Future<TxFilter?> showFilterSheet(
  BuildContext context, {
  required TxFilter initial,
  required List<TransactionItem> all,
}) {
  return showModalBottomSheet<TxFilter>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black38,
    builder: (_) => _FilterSheet(initial: initial, all: all),
  );
}

class _FilterSheet extends StatefulWidget {
  final TxFilter initial;
  final List<TransactionItem> all;
  const _FilterSheet({required this.initial, required this.all});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late TxFilter _f = widget.initial;
  bool _showAllCategories = false;
  late final _minCtrl = TextEditingController(
      text: _f.minAmount == null ? '' : _f.minAmount!.toStringAsFixed(0));
  late final _maxCtrl = TextEditingController(
      text: _f.maxAmount == null ? '' : _f.maxAmount!.toStringAsFixed(0));

  int get _count => widget.all.where(_f.matches).length;

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _f = const TxFilter();
      _minCtrl.clear();
      _maxCtrl.clear();
    });
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final initial = (isFrom ? _f.from : _f.to) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(() => _f = isFrom ? _f.copyWith(from: picked) : _f.copyWith(to: picked));
  }

  void _toggle(Set<String> current, String v, void Function(Set<String>) set) {
    final s = {...current};
    s.contains(v) ? s.remove(v) : s.add(v);
    set(s);
  }

  @override
  Widget build(BuildContext context) {
    final cats = _showAllCategories ? kExpenseCategories : kExpenseCategories.take(4).toList();

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border, borderRadius: BorderRadius.circular(4))),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('Filter',
                          style: AppTheme.heading(20, color: AppColors.text)),
                      const Spacer(),
                      GestureDetector(
                        onTap: _reset,
                        child: const Text('Reset',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.terracotta)),
                      ),
                    ]),
                    const _Label('Type'),
                    Row(children: [
                      _chip('All', _f.type == null, AppColors.sage,
                          () => setState(() => _f = _f.copyWith(clearType: true)),
                          expand: true),
                      const SizedBox(width: 8),
                      _chip('Income', _f.type == TxType.income, AppColors.sage,
                          () => setState(() => _f = _f.copyWith(type: TxType.income)),
                          expand: true),
                      const SizedBox(width: 8),
                      _chip('Expense', _f.type == TxType.expense, AppColors.sage,
                          () => setState(() => _f = _f.copyWith(type: TxType.expense)),
                          expand: true),
                    ]),
                    const _Label('Category'),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final c in cats)
                        _chip('${kCategoryEmoji[c] ?? ''} $c',
                            _f.categories.contains(c), AppColors.terracotta,
                            () => _toggle(_f.categories, c,
                                (s) => setState(() => _f = _f.copyWith(categories: s)))),
                      if (!_showAllCategories)
                        _chip('+ ${kExpenseCategories.length - 4} more', false,
                            AppColors.terracotta,
                            () => setState(() => _showAllCategories = true)),
                    ]),
                    const _Label('Date range'),
                    Row(children: [
                      Expanded(
                          child: _field('FROM', _f.from == null ? 'Any' : _fmt(_f.from!),
                              () => _pickDate(isFrom: true))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _field('TO', _f.to == null ? 'Any' : _fmt(_f.to!),
                              () => _pickDate(isFrom: false))),
                    ]),
                    const _Label('Amount range'),
                    Row(children: [
                      Expanded(child: _amountField('MIN', 'RM 0', _minCtrl, true)),
                      const SizedBox(width: 12),
                      Expanded(child: _amountField('MAX', 'RM 500', _maxCtrl, false)),
                    ]),
                    const _Label('Payment method'),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final m in kPaymentMethods)
                        _chip(m, _f.paymentMethods.contains(m), AppColors.sage,
                            () => _toggle(_f.paymentMethods, m,
                                (s) => setState(() => _f = _f.copyWith(paymentMethods: s)))),
                    ]),
                    const _Label('Sort by'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<SortOption>(
                          value: _f.sort,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down,
                              color: AppColors.textMuted),
                          style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                          dropdownColor: AppColors.paper,
                          items: [
                            for (final s in SortOption.values)
                              DropdownMenuItem(value: s, child: Text(s.label)),
                          ],
                          onChanged: (v) =>
                              setState(() => _f = _f.copyWith(sort: v)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: PrimaryButton(
                label: 'Show $_count results',
                color: AppColors.sage,
                onPressed: () => Navigator.pop(context, _f),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, Color color, VoidCallback onTap,
      {bool expand = false}) {
    final child = GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? color : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textMuted)),
      ),
    );
    return expand ? Expanded(child: child) : child;
  }

  Widget _field(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10, letterSpacing: .6, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text)),
        ]),
      ),
    );
  }

  Widget _amountField(
      String label, String hint, TextEditingController c, bool isMin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10, letterSpacing: .6, color: AppColors.textMuted)),
        TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.only(top: 4),
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textFaint, fontSize: 14),
          ),
          onChanged: (v) {
            final n = double.tryParse(v);
            setState(() {
              _f = isMin
                  ? (n == null ? _f.copyWith(clearMin: true) : _f.copyWith(minAmount: n))
                  : (n == null ? _f.copyWith(clearMax: true) : _f.copyWith(maxAmount: n));
            });
          },
        ),
      ]),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 10),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text)),
      );
}
