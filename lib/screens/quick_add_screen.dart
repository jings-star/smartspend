import 'package:flutter/material.dart';
import '../models/transaction_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];
const _incomeCategories = ['Salary', 'Allowance', 'Gift', 'Other'];

/// Keyword -> category guesses. Extend freely.
const _keywordCategory = <String, String>{
  'grocer': 'Groceries', 'mart': 'Groceries', 'market': 'Groceries',
  'tesco': 'Groceries', 'aeon': 'Groceries', 'mydin': 'Groceries',
  'cafe': 'Food', 'coffee': 'Food', 'kopi': 'Food', 'mamak': 'Food',
  'nasi': 'Food', 'restaurant': 'Food', 'lunch': 'Food', 'dinner': 'Food',
  'petrol': 'Transport', 'grab': 'Transport', 'toll': 'Transport',
  'lrt': 'Transport', 'mrt': 'Transport', 'parking': 'Transport',
  'watsons': 'Personal Care', 'guardian': 'Personal Care',
  'shopee': 'Shopping', 'lazada': 'Shopping', 'uniqlo': 'Shopping',
  'tnb': 'Bills', 'unifi': 'Bills', 'bill': 'Bills', 'rent': 'Bills',
  'movie': 'Entertainment', 'netflix': 'Entertainment',
  'clinic': 'Health', 'pharmacy': 'Health',
  'salary': 'Salary', 'allowance': 'Allowance',
};

class _Parsed {
  final String merchant;
  final double? amount;
  final String? category;
  const _Parsed(this.merchant, this.amount, this.category);
}

/// "village grocer 17.35" -> Village Grocer / 17.35 / Groceries
_Parsed _parse(String input) {
  final text = input.trim();
  if (text.isEmpty) return const _Parsed('', null, null);

  final matches = RegExp(r'(\d+(?:\.\d{1,2})?)').allMatches(text).toList();
  double? amount;
  var rest = text;
  if (matches.isNotEmpty) {
    final m = matches.last;
    amount = double.tryParse(m.group(1)!);
    rest = (text.substring(0, m.start) + text.substring(m.end))
        .replaceAll(RegExp(r'\brm\b', caseSensitive: false), '')
        .trim();
  }
  final merchant = rest
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');

  final lower = merchant.toLowerCase();
  String? category;
  for (final e in _keywordCategory.entries) {
    if (lower.contains(e.key)) {
      category = e.value;
      break;
    }
  }
  return _Parsed(merchant, amount, category);
}

/// Quick add: type "village grocer 17.35" and it fills in the rest.
/// Pops with a `List<TransactionItem>` (one item) when saved.
class QuickAddScreen extends StatefulWidget {
  const QuickAddScreen({super.key});

  @override
  State<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends State<QuickAddScreen> {
  final _ctrl = TextEditingController();
  TxType _type = TxType.expense;
  DateTime _when = DateTime.now();
  String _payment = 'E-wallet';

  _Parsed _parsed = const _Parsed('', null, null);
  // Manual overrides from tapping the rows; cleared when the text changes.
  String? _merchantOv;
  double? _amountOv;
  String? _categoryOv;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _merchant => _merchantOv ?? _parsed.merchant;
  double? get _amount => _amountOv ?? _parsed.amount;
  String? get _category =>
      _categoryOv ?? _parsed.category ?? (_merchant.isEmpty ? null : _fallback);
  String get _fallback => _type == TxType.expense ? 'Food' : 'Other';

  bool get _canSave =>
      _merchant.isNotEmpty && _amount != null && _amount! > 0;

  bool get _isToday {
    final n = DateTime.now();
    return _when.year == n.year && _when.month == n.month && _when.day == n.day;
  }

  String get _whenLabel {
    final h = _when.hour % 12 == 0 ? 12 : _when.hour % 12;
    final m = _when.minute.toString().padLeft(2, '0');
    final ap = _when.hour >= 12 ? 'PM' : 'AM';
    final day =
        _isToday ? 'Today' : '${_when.day} ${_months[_when.month - 1]}';
    return '$day, $h:$m $ap';
  }

  void _onChanged(String v) => setState(() {
        _parsed = _parse(v);
        _merchantOv = null;
        _amountOv = null;
        _categoryOv = null;
      });

  Future<void> _pickWhen() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_when));
    if (!mounted) return;
    setState(() => _when = DateTime(
        d.year, d.month, d.day, t?.hour ?? _when.hour, t?.minute ?? _when.minute));
  }

  Future<String?> _pickFromList(String title, List<String> options) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
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
                child: ListView(shrinkWrap: true, children: [
                  for (final o in options)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text(kCategoryEmoji[o] ?? '',
                          style: const TextStyle(fontSize: 20)),
                      title: Text(o,
                          style: AppTheme.body(14, weight: FontWeight.w600)),
                      onTap: () => Navigator.pop(context, o),
                    ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _editText(String title, String initial, {bool number = false}) async {
    final c = TextEditingController(text: initial);
    final r = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: Text(title, style: AppTheme.heading(18)),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: number
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(prefixText: number ? 'RM ' : null),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim()),
              child: const Text('OK')),
        ],
      ),
    );
    c.dispose();
    return r;
  }

  void _save() {
    final item = TransactionItem(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      title: _merchant,
      category: _category ?? _fallback,
      amount: _amount!,
      type: _type,
      date: _when,
      paymentMethod: _payment,
    );
    Navigator.pop(context, [item]);
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = _type == TxType.expense;
    final cats = isExpense ? kExpenseCategories : _incomeCategories;
    final amt = _amount;

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
                        child: const Icon(Icons.chevron_left,
                            size: 20, color: AppColors.text),
                      ),
                    ),
                  ),
                  Text('Quick add', style: AppTheme.heading(18)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Row(children: [
                    Expanded(
                        child: _typePill('Expense', AppColors.coral, isExpense,
                            () => _setType(TxType.expense))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _typePill('Income', AppColors.sage, !isExpense,
                            () => _setType(TxType.income))),
                  ]),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(18),
                      border:
                          Border.all(color: AppColors.terracotta, width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TYPE HERE',
                            style: AppTheme.body(10,
                                weight: FontWeight.w700,
                                color: AppColors.textFaint)),
                        TextField(
                          controller: _ctrl,
                          autofocus: true,
                          onChanged: _onChanged,
                          textInputAction: TextInputAction.done,
                          style: AppTheme.heading(15)
                              .copyWith(fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.only(top: 6),
                            hintText: 'e.g. village grocer 17.35',
                            hintStyle: AppTheme.heading(15).copyWith(
                                fontWeight: FontWeight.w500,
                                color: AppColors.textFaint),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(children: [
                      _row('Merchant', _merchant.isEmpty ? '—' : _merchant,
                          onTap: () async {
                        final v = await _editText('Merchant', _merchant);
                        if (v != null && v.isNotEmpty) {
                          setState(() => _merchantOv = v);
                        }
                      }),
                      const Divider(height: 1, color: AppColors.border),
                      _row('Amount',
                          amt == null ? '—' : 'RM ${amt.toStringAsFixed(2)}',
                          onTap: () async {
                        final v = await _editText(
                            'Amount', amt?.toStringAsFixed(2) ?? '',
                            number: true);
                        final n = double.tryParse(v ?? '');
                        if (n != null) setState(() => _amountOv = n);
                      }),
                      const Divider(height: 1, color: AppColors.border),
                      _row('Category', _category ?? '—', onTap: () async {
                        final v = await _pickFromList('Category', cats);
                        if (v != null) setState(() => _categoryOv = v);
                      }),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _chip(_whenLabel, _pickWhen)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _chip(_payment, () async {
                      final v =
                          await _pickFromList('Payment method', kPaymentMethods);
                      if (v != null) setState(() => _payment = v);
                    })),
                  ]),
                  const SizedBox(height: 28),
                  Center(
                    child: Text('Not right?',
                        style: AppTheme.body(12.5, color: AppColors.textMuted)),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text('Tap to adjust before saving.',
                        style: AppTheme.body(12.5, color: AppColors.textFaint)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: PrimaryButton(
                label: 'Save transaction',
                color: AppColors.sage,
                onPressed: _canSave ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setType(TxType t) => setState(() {
        _type = t;
        _categoryOv = null;
      });

  Widget _typePill(String label, Color color, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(21),
        ),
        child: Text(label,
            style: AppTheme.body(13,
                weight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }

  Widget _row(String label, String value, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(children: [
          Text(label, style: AppTheme.body(13, color: AppColors.textMuted)),
          const Spacer(),
          Text(value, style: AppTheme.body(13, weight: FontWeight.w800)),
        ]),
      ),
    );
  }

  Widget _chip(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.body(12, color: AppColors.textMuted)),
      ),
    );
  }
}
