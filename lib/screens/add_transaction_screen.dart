import 'package:flutter/material.dart';
import '../models/transaction_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import '../widgets/split_sheet.dart';
import '../services/category_helper.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const _incomeCategories = ['Salary', 'Allowance', 'Gift', 'Other'];

/// Full-entry form. Pops with a `List<TransactionItem>` (1 item, or one per
/// split line) when saved.
class AddTransactionScreen extends StatefulWidget {
  /// Transactions already saved. Used to warn about possible duplicates.
  final List<TransactionItem> existing;

  const AddTransactionScreen({super.key, this.existing = const []});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  TxType _type = TxType.expense;
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  String? _category;
  String? _payment;
  bool _split = false;
  final List<SplitLine> _splits = [];

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _isToday {
    final n = DateTime.now();
    return _date.year == n.year && _date.month == n.month && _date.day == n.day;
  }

  String get _dateLabel =>
      '${_isToday ? 'Today, ' : ''}${_date.day} ${_months[_date.month - 1]}'
      '${_isToday ? '' : ' ${_date.year}'}';

  double get _splitTotal => _splits.fold(0, (s, e) => s + e.amount);
  bool get _amountLocked => _split && _splits.isNotEmpty;

  String _fmtAmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  /// Keeps the main amount equal to the sum of the splits.
  void _syncAmount() {
    _amountCtrl.text = _splits.isEmpty ? '' : _fmtAmt(_splitTotal);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (picked != null) {
      final now = DateTime.now();
      setState(
        () => _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          now.hour,
          now.minute,
        ),
      );
    }
  }

  Future<String?> _pickFromList(
    String title,
    List<String> options, {
    bool emoji = false,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTheme.heading(18)),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final o in options)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: emoji
                            ? Text(
                                kCategoryEmoji[o] ?? '📦',
                                style: const TextStyle(fontSize: 20),
                              )
                            : null,
                        title: Text(
                          o,
                          style: AppTheme.body(14, weight: FontWeight.w600),
                        ),
                        onTap: () => Navigator.pop(context, o),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Add (index == null) or edit (index given) a split via the bottom sheet.
  Future<void> _openSplitSheet({int? index}) async {
    final result = await showSplitSheet(
      context,
      initial: index == null ? null : _splits[index],
    );
    if (result == null) return;
    setState(() {
      if (index == null) {
        _splits.add(result);
      } else {
        _splits[index] = result;
      }
      _syncAmount();
    });
  }

  void _removeSplit(int i) {
    setState(() {
      _splits.removeAt(i);
      _syncAmount();
    });
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// A saved transaction counts as a duplicate when it has the same day,
  /// type and amount as the new one.
  bool _isDuplicate(TransactionItem a, TransactionItem b) =>
      _sameDay(a.date, b.date) &&
      a.type == b.type &&
      (a.amount - b.amount).abs() < 0.005;

  /// Runs when the user finishes typing in Notes (e.g. "Starbucks RM18.50").
Future<void> _suggestFromNote() async {
  final text = _notesCtrl.text.trim();
  if (text.isEmpty || _category != null) return; // don't override the user's choice

  final r = await suggestFromText(text);
  if (r == null || !mounted) return;

  final newType = r['type'] == 'income' ? TxType.income : TxType.expense;
  final cats = newType == TxType.expense ? kExpenseCategories : _incomeCategories;
  final cat = r['category'] as String?;
  final amt = r['amount'];
  final title = (r['title'] as String?)?.trim() ?? '';

  setState(() {
    _type = newType;
    if (cat != null && cats.contains(cat)) _category = cat;
    if (amt != null && _amountCtrl.text.trim().isEmpty && !_amountLocked) {
      _amountCtrl.text = _fmtAmt((amt as num).toDouble());
      if (title.isNotEmpty) _notesCtrl.text = title; // "Starbucks RM18.50" becomes "Starbucks"
    }
  });
}

  Future<void> _save() async {
    final total = double.tryParse(_amountCtrl.text.trim());
    if (total == null || total <= 0) {
      _snack('Enter an amount');
      return;
    }
    if (_category == null) {
      _snack('Select a category');
      return;
    }
    if (_payment == null) {
      _snack('Select a payment method');
      return;
    }

    final note = _notesCtrl.text.trim();
    final base = DateTime.now().microsecondsSinceEpoch;
    final items = <TransactionItem>[];

    if (_split && _splits.isNotEmpty) {
      for (int i = 0; i < _splits.length; i++) {
        items.add(
          TransactionItem(
            id: '${base}_$i',
            title: _splits[i].label,
            category: _category!,
            amount: _splits[i].amount,
            type: _type,
            date: _date,
            paymentMethod: _payment!,
          ),
        );
      }
    } else {
      items.add(
        TransactionItem(
          id: '$base',
          title: note.isEmpty ? _category! : note,
          category: _category!,
          amount: total,
          type: _type,
          date: _date,
          paymentMethod: _payment!,
        ),
      );
    }

    // Duplicate check: collect the new items that clash with saved ones.
    final clashingNew = <TransactionItem>[];
    final clashingOld = <TransactionItem>[];
    for (final n in items) {
      final matches = widget.existing.where((e) => _isDuplicate(e, n)).toList();
      if (matches.isEmpty) continue;
      clashingNew.add(n);
      for (final m in matches) {
        if (!clashingOld.any((o) => o.id == m.id)) clashingOld.add(m);
      }
    }

    if (clashingNew.isNotEmpty) {
      final proceed = await showDuplicateDialog(
        context,
        existing: clashingOld,
        incoming: clashingNew,
      );
      if (!mounted) return;
      if (proceed != true) {
        Navigator.pop(context); // discard this entry
        return;
      }
    }

    Navigator.pop(context, items);
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = _type == TxType.expense;
    final categories = isExpense ? kExpenseCategories : _incomeCategories;

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
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          Icons.chevron_left,
                          size: 20,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ),
                  Text('Add transaction', style: AppTheme.heading(18)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _typePill(
                          'Expense',
                          AppColors.coral,
                          isExpense,
                          () => _setType(TxType.expense),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _typePill(
                          'Income',
                          AppColors.sage,
                          !isExpense,
                          () => _setType(TxType.income),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _FieldBox(
                    label: 'AMOUNT',
                    child: TextField(
                      controller: _amountCtrl,
                      readOnly: _amountLocked,
                      textAlign: TextAlign.right,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: AppTheme.body(
                        14,
                        weight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        prefixText: 'RM ',
                        prefixStyle: AppTheme.body(
                          14,
                          weight: FontWeight.w700,
                          color: AppColors.textMuted,
                        ),
                        hintText: '0',
                        hintStyle: AppTheme.body(
                          14,
                          weight: FontWeight.w700,
                          color: AppColors.textFaint,
                        ),
                      ),
                    ),
                  ),
                  _FieldBox(
                    label: 'DATE',
                    onTap: _pickDate,
                    child: _value(_dateLabel, filled: true),
                  ),
                  _FieldBox(
                    label: 'CATEGORY',
                    onTap: () async {
                      final c = await _pickFromList(
                        'Category',
                        categories,
                        emoji: true,
                      );
                      if (c != null) setState(() => _category = c);
                    },
                    child: _value(
                      _category ?? 'Select category',
                      filled: _category != null,
                    ),
                  ),
                  _FieldBox(
                    label: 'PAYMENT METHOD',
                    onTap: () async {
                      final p = await _pickFromList(
                        'Payment method',
                        kPaymentMethods,
                      );
                      if (p != null) setState(() => _payment = p);
                    },
                    child: _value(
                      _payment ?? 'Select method',
                      filled: _payment != null,
                    ),
                  ),
                  _FieldBox(
                    label: 'NOTES',
                    stacked: true,
                    child: TextField(
                      controller: _notesCtrl,
                      minLines: 1,
                      maxLines: 3,
                      style: AppTheme.body(14, weight: FontWeight.w600),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.only(top: 6),
                        hintText: 'Add a note',
                        hintStyle: AppTheme.body(
                          14,
                          weight: FontWeight.w600,
                          color: AppColors.textFaint,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Split transaction',
                        style: AppTheme.body(13, weight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Switch(
                        value: _split,
                        activeTrackColor: AppColors.terracotta,
                        activeThumbColor: Colors.white,
                        onChanged: (v) => setState(() => _split = v),
                      ),
                    ],
                  ),
                  if (_split) _splitCard(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: PrimaryButton(
                label: 'Save transaction',
                color: AppColors.sage,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setType(TxType t) => setState(() {
    _type = t;
    _category = null; // category lists differ per type
  });

  Widget _typePill(
    String label,
    Color color,
    bool selected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(21),
        ),
        child: Text(
          label,
          style: AppTheme.body(
            13,
            weight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _value(String text, {required bool filled}) => Text(
    text,
    style: AppTheme.body(
      14,
      weight: FontWeight.w600,
      color: filled ? AppColors.text : AppColors.textFaint,
    ),
  );

  Widget _splitCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < _splits.length; i++) ...[
            Dismissible(
              key: ObjectKey(_splits[i]),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => _removeSplit(i),
              background: Container(
                alignment: Alignment.centerRight,
                child: const Icon(Icons.delete_outline, color: AppColors.coral),
              ),
              child: InkWell(
                onTap: () => _openSplitSheet(index: i), // edit
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i.isEven
                              ? AppColors.sageTint
                              : AppColors.coralTint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _splits[i].icon,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _splits[i].label,
                          style: AppTheme.body(13, weight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        'RM ${_fmtAmt(_splits[i].amount)}',
                        style: AppTheme.body(
                          13,
                          weight: FontWeight.w800,
                          color: AppColors.terracottaDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _removeSplit(i), // delete
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.textFaint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
          ],
          TextButton(
            onPressed: () => _openSplitSheet(), // create
            child: Text(
              '+ Add split',
              style: AppTheme.body(
                11,
                weight: FontWeight.w700,
                color: AppColors.terracottaDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldBox extends StatelessWidget {
  final String label;
  final Widget child;
  final VoidCallback? onTap;
  final bool stacked;

  const _FieldBox({
    required this.label,
    required this.child,
    this.onTap,
    this.stacked = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelText = Text(
      label,
      style: AppTheme.body(
        10,
        weight: FontWeight.w700,
        color: AppColors.textFaint,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [labelText, child],
                )
              : Row(
                  children: [
                    labelText,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: child,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Returns `true` for "Continue Save", `false` for "Discard this entry".
Future<bool?> showDuplicateDialog(
  BuildContext context, {
  required List<TransactionItem> existing,
  required List<TransactionItem> incoming,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => _DuplicateDialog(existing: existing, incoming: incoming),
  );
}

class _DuplicateDialog extends StatelessWidget {
  final List<TransactionItem> existing;
  final List<TransactionItem> incoming;

  const _DuplicateDialog({required this.existing, required this.incoming});

  String _time(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  String _when(DateTime d) {
    final n = DateTime.now();
    final today = d.year == n.year && d.month == n.month && d.day == n.day;
    final day = today ? 'Today' : '${d.day} ${_months[d.month - 1]}';
    return '$day, ${_time(d)}';
  }

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    final all = [
      for (final e in existing) (e, false),
      for (final n in incoming) (n, true),
    ];
    for (int i = 0; i < all.length; i++) {
      if (i > 0) {
        rows.add(const Divider(height: 1, color: AppColors.border));
      }
      rows.add(_row(all[i].$1, isNew: all[i].$2));
    }

    return Dialog(
      backgroundColor: AppColors.paper,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.coralTint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 24,
                color: AppColors.terracottaDark,
              ),
            ),
            const SizedBox(height: 14),
            Text('Duplicate Detected', style: AppTheme.heading(20)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Similar transaction with the same date has been detected!',
                textAlign: TextAlign.center,
                style: AppTheme.body(12, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 18),
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(children: rows),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, true),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.paper,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  'Continue Save',
                  style: AppTheme.body(
                    13,
                    weight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Discard this entry',
              color: AppColors.terracotta,
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(TransactionItem t, {required bool isNew}) {
    final isExpense = t.type == TxType.expense;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isNew ? AppColors.coralTint : AppColors.sageTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              kCategoryEmoji[t.category] ?? '📦',
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: t.title,
                        style: AppTheme.body(
                          13,
                          weight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      if (isNew)
                        TextSpan(
                          text: '  (new)',
                          style: AppTheme.body(
                            11,
                            weight: FontWeight.w700,
                            color: AppColors.terracottaDark,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _when(t.date),
                  style: AppTheme.body(11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isExpense ? '-' : '+'} RM ${t.amount.toStringAsFixed(2)}',
            style: AppTheme.body(
              13,
              weight: FontWeight.w800,
              color: isExpense ? AppColors.terracottaDark : AppColors.sage,
            ),
          ),
        ],
      ),
    );
  }
}
