import 'package:flutter/material.dart';
import '../models/transaction_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

/// One line of a split transaction.
class SplitLine {
  SplitLine({required this.category, required this.amount});
  String category;
  double amount;
}

/// What the screen returns via Navigator.pop when "Save changes" is tapped.
class EditTransactionResult {
  const EditTransactionResult({
    required this.type,
    required this.amount,
    required this.date,
    required this.category,
    required this.paymentMethod,
    required this.notes,
    required this.splits,
  });

  final TxType type;
  final double amount;
  final DateTime date;
  final String category;
  final String paymentMethod;
  final String notes;

  /// Empty when split is turned off.
  final List<SplitLine> splits;
}

class EditTransactionScreen extends StatefulWidget {
  const EditTransactionScreen({
    super.key,
    required this.type,
    required this.amount,
    required this.date,
    required this.category,
    this.paymentMethod = 'Cash',
    this.notes = '',
    this.splits = const [],
  });

  final TxType type;
  final double amount;
  final DateTime date;
  final String category;
  final String paymentMethod;
  final String notes;
  final List<SplitLine> splits;

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  late TxType _type = widget.type;
  late DateTime _date = widget.date;
  late String _category = widget.category;
  late String _payment = widget.paymentMethod;
  late bool _split = widget.splits.isNotEmpty;
  late final List<SplitLine> _splits = widget.splits
      .map((s) => SplitLine(category: s.category, amount: s.amount))
      .toList();

  late final _amountCtrl = TextEditingController(
      text: widget.amount.toStringAsFixed(2));
  late final _notesCtrl = TextEditingController(text: widget.notes);

  // Controllers for split amount fields, kept in sync with _splits.
  final List<TextEditingController> _splitCtrls = [];

  @override
  void initState() {
    super.initState();
    for (final s in _splits) {
      _splitCtrls.add(TextEditingController(text: _fmt(s.amount)));
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    for (final c in _splitCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------- helpers ----------

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  double get _amount => double.tryParse(_amountCtrl.text.trim()) ?? 0;

  double get _splitTotal => _splits.fold(0, (s, e) => s + e.amount);

  List<String> get _categoryOptions =>
      _type == TxType.income ? const ['Income'] : kExpenseCategories;

  void _setType(TxType t) {
    setState(() {
      _type = t;
      if (!_categoryOptions.contains(_category)) {
        _category = _categoryOptions.first;
      }
    });
  }

  String get _dateLabel {
    final now = DateTime.now();
    final isToday = _date.year == now.year &&
        _date.month == now.month &&
        _date.day == now.day;
    final base = '${_date.day} ${_months[_date.month - 1]}';
    return isToday ? 'Today, $base' : '$base ${_date.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<String?> _pickFromList(String title, List<String> options,
      {Map<String, String>? emojis}) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          children: [
            Text(title, style: AppTheme.heading(17, color: AppColors.text)),
            const SizedBox(height: 8),
            for (final o in options)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: emojis != null
                    ? Text(emojis[o] ?? '', style: const TextStyle(fontSize: 20))
                    : null,
                title: Text(o,
                    style: const TextStyle(
                        color: AppColors.text, fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(context, o),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCategory() async {
    final c = await _pickFromList('Category', _categoryOptions,
        emojis: kCategoryEmoji);
    if (c != null) setState(() => _category = c);
  }

  Future<void> _pickPayment() async {
    final p = await _pickFromList('Payment method', kPaymentMethods);
    if (p != null) setState(() => _payment = p);
  }

  Future<void> _pickSplitCategory(int i) async {
    final c = await _pickFromList('Category', _categoryOptions,
        emojis: kCategoryEmoji);
    if (c != null) setState(() => _splits[i].category = c);
  }

  void _addSplit() {
    final remaining = (_amount - _splitTotal).clamp(0, double.infinity).toDouble();
    setState(() {
      _splits.add(SplitLine(category: kExpenseCategories.first, amount: remaining));
      _splitCtrls.add(TextEditingController(text: _fmt(remaining)));
    });
  }

  void _removeSplit(int i) {
    setState(() {
      _splits.removeAt(i);
      _splitCtrls.removeAt(i).dispose();
    });
  }

  void _toggleSplit(bool on) {
    setState(() {
      _split = on;
      if (on && _splits.isEmpty) {
        // Start with two lines so the card looks like the design.
        for (final c in ['Food', 'Personal Care']) {
          _splits.add(SplitLine(category: c, amount: 0));
          _splitCtrls.add(TextEditingController(text: '0'));
        }
      }
    });
  }

  void _save() {
    final amount = _amount;
    if (amount <= 0) {
      _snack('Enter an amount greater than 0');
      return;
    }
    if (_split) {
      if (_splits.length < 2) {
        _snack('Add at least two splits');
        return;
      }
      if ((_splitTotal - amount).abs() > 0.005) {
        _snack(
            'Splits total RM ${_splitTotal.toStringAsFixed(2)} but amount is RM ${amount.toStringAsFixed(2)}');
        return;
      }
    }
    Navigator.pop(
      context,
      EditTransactionResult(
        type: _type,
        amount: amount,
        date: _date,
        category: _category,
        paymentMethod: _payment,
        notes: _notesCtrl.text.trim(),
        splits: _split ? _splits : const [],
      ),
    );
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.chevron_left,
                            size: 20, color: AppColors.text),
                      ),
                    ),
                  ),
                  Text('Edit Transaction',
                      style: AppTheme.heading(17, color: AppColors.text)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusScope.of(context).unfocus(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    Row(children: [
                      Expanded(child: _typeChip('Expense', TxType.expense)),
                      const SizedBox(width: 10),
                      Expanded(child: _typeChip('Income', TxType.income)),
                    ]),
                    const SizedBox(height: 12),
                    _fieldCard(
                      child: Row(children: [
                        _label('Amount'),
                        const Spacer(),
                        const Text('RM ',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text)),
                        IntrinsicWidth(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 40),
                            child: TextField(
                              controller: _amountCtrl,
                              textAlign: TextAlign.right,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text),
                              decoration: _bare,
                            ),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    _fieldCard(
                      onTap: _pickDate,
                      child: Row(children: [
                        _label('Date'),
                        const Spacer(),
                        _value(_dateLabel),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    _fieldCard(
                      onTap: _pickCategory,
                      child: Row(children: [
                        _label('Category'),
                        const Spacer(),
                        _categoryChip(_category),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    _fieldCard(
                      onTap: _pickPayment,
                      child: Row(children: [
                        _label('Payment method'),
                        const Spacer(),
                        _value(_payment),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    _fieldCard(
                      height: null,
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Notes',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textFaint)),
                          TextField(
                            controller: _notesCtrl,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text),
                            decoration: _bare.copyWith(hintText: 'Add a note'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(children: [
                      const Text('Split transaction',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text)),
                      const Spacer(),
                      Switch(
                        value: _split,
                        onChanged: _toggleSplit,
                        activeColor: Colors.white,
                        activeTrackColor: AppColors.terracotta,
                        inactiveTrackColor: AppColors.border,
                        inactiveThumbColor: Colors.white,
                        trackOutlineColor:
                            const WidgetStatePropertyAll(Colors.transparent),
                      ),
                    ]),
                    if (_split) ...[
                      const SizedBox(height: 4),
                      _splitCard(),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.sage,
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shadowColor: AppColors.sage.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26)),
                        ),
                        child: const Text('Save changes',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- pieces ----------

  static const _bare = InputDecoration(
    isDense: true,
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    contentPadding: EdgeInsets.zero,
  );

  Widget _typeChip(String label, TxType t) {
    final selected = _type == t;
    return GestureDetector(
      onTap: () => _setType(t),
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.sage.withOpacity(0.15) : AppColors.paper,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.sage : AppColors.border,
              width: selected ? 1.5 : 1),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.text : AppColors.textMuted)),
      ),
    );
  }

  Widget _fieldCard({
    required Widget child,
    VoidCallback? onTap,
    double? height = 48,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 16),
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: height,
        padding: padding,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      ),
    );
  }

  Widget _label(String s) => Text(s,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted));

  Widget _value(String s) => Text(s,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text));

  Widget _categoryChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.terracotta.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(kCategoryEmoji[name] ?? '📦', style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 5),
        Text(name,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.terracottaDark)),
      ]),
    );
  }

  Widget _splitCard() {
    final diff = _amount - _splitTotal;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        for (var i = 0; i < _splits.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: AppColors.border),
          SizedBox(
            height: 44,
            child: Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickSplitCategory(i),
                  behavior: HitTestBehavior.opaque,
                  child: Row(children: [
                    Text(kCategoryEmoji[_splits[i].category] ?? '📦',
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(_splits[i].category,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text)),
                    ),
                  ]),
                ),
              ),
              const Text('RM ',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.terracottaDark)),
              SizedBox(
                width: 52,
                child: TextField(
                  controller: _splitCtrls[i],
                  textAlign: TextAlign.right,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) =>
                      setState(() => _splits[i].amount = double.tryParse(v) ?? 0),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.terracottaDark),
                  decoration: _bare,
                ),
              ),
              if (_splits.length > 2)
                GestureDetector(
                  onTap: () => _removeSplit(i),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.close,
                        size: 16, color: AppColors.textFaint),
                  ),
                ),
            ]),
          ),
        ],
        const Divider(height: 1, color: AppColors.border),
        TextButton(
          onPressed: _addSplit,
          child: const Text('+ Add split',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.terracottaDark)),
        ),
        if (diff.abs() > 0.005)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              diff > 0
                  ? 'RM ${diff.toStringAsFixed(2)} left to allocate'
                  : 'Over by RM ${(-diff).toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textMuted),
            ),
          ),
      ]),
    );
  }
}
