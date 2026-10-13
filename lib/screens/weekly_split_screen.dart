import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/budget.dart';
import '../models/recurring_transaction.dart'
    show currencySymbol, formatMoney;
import '../services/budget_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import '../widgets/round_back_button.dart';

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _shortMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

enum _SplitMode { even, custom }

/// Divide a budget across the 4 weeks of the current month.
///
/// [spentByWeek] is the spending already logged in each week (4 values).
/// TODO: compute it from your transactions, e.g. sum the expenses of the
/// budget's category whose date falls in each week. Defaults to zeros.
class WeeklySplitScreen extends StatefulWidget {
  final Budget budget;
  final List<double>? spentByWeek;

  const WeeklySplitScreen({
    super.key,
    required this.budget,
    this.spentByWeek,
  });

  @override
  State<WeeklySplitScreen> createState() => _WeeklySplitScreenState();
}

class _WeeklySplitScreenState extends State<WeeklySplitScreen> {
  static const _weekCount = 4;

  late final DateTime _month;
  late final List<({int start, int end})> _weeks;
  late final int _totalCents;
  late final List<TextEditingController> _controllers;

  _SplitMode _mode = _SplitMode.even;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    final lastDay = DateTime(_month.year, _month.month + 1, 0).day;
    _weeks = [
      (start: 1, end: 7),
      (start: 8, end: 14),
      (start: 15, end: 21),
      (start: 22, end: lastDay),
    ];

    final b = widget.budget;
    _totalCents = (b.amount * b.period.monthlyFactor * 100).round();

    final saved = b.weeklySplit;
    final even = _evenValues();
    final hasSaved = saved != null && saved.length == _weekCount;
    _controllers = [
      for (int i = 0; i < _weekCount; i++)
        TextEditingController(
            text: (hasSaved ? saved[i] : even[i]).toStringAsFixed(2)),
    ];
    if (hasSaved && !_sameAsEven(saved)) _mode = _SplitMode.custom;
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------- maths (in cents to avoid rounding errors) ----------

  List<double> _evenValues() {
    final base = _totalCents ~/ _weekCount;
    final rest = _totalCents - base * _weekCount;
    return [
      for (int i = 0; i < _weekCount; i++)
        (base + (i == _weekCount - 1 ? rest : 0)) / 100,
    ];
  }

  bool _sameAsEven(List<double> values) {
    final even = _evenValues();
    for (int i = 0; i < _weekCount; i++) {
      if ((values[i] * 100).round() != (even[i] * 100).round()) return false;
    }
    return true;
  }

  double _parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', '')) ?? 0;

  List<double> get _values => [for (final c in _controllers) _parse(c.text)];

  int get _allocatedCents =>
      _values.fold<int>(0, (sum, v) => sum + (v * 100).round());

  bool get _isBalanced => _allocatedCents == _totalCents;

  void _setMode(_SplitMode m) {
    setState(() {
      _mode = m;
      if (m == _SplitMode.even) {
        final even = _evenValues();
        for (int i = 0; i < _weekCount; i++) {
          _controllers[i].text = even[i].toStringAsFixed(2);
        }
      }
    });
  }

  void _confirm() {
    final messenger = ScaffoldMessenger.of(context);
    BudgetStore.instance
        .update(widget.budget.copyWith(weeklySplit: _values));
    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(
      content: Text('Weekly allocation saved',
          style: AppTheme.body(13, color: Colors.white)),
    ));
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final symbol = currencySymbol();
    final monthName = _monthNames[_month.month - 1];
    final values = _values;
    final canConfirm = _mode == _SplitMode.even || _isBalanced;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: SizedBox(
                height: 36,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Align(
                        alignment: Alignment.centerLeft,
                        child: RoundBackButton()),
                    Text('Weekly split', style: AppTheme.heading(17)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Divide $symbol ${formatMoney(_totalCents / 100)} across '
              "$monthName's $_weekCount weeks.",
              textAlign: TextAlign.center,
              style: AppTheme.body(11.5, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    for (int i = 0; i < _weekCount; i++) ...[
                      _weekCard(i, values[i], symbol),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: _ModePill(
                            label: 'Split evenly',
                            selected: _mode == _SplitMode.even,
                            onTap: () => _setMode(_SplitMode.even),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ModePill(
                            label: 'Custom',
                            selected: _mode == _SplitMode.custom,
                            onTap: () => _setMode(_SplitMode.custom),
                          ),
                        ),
                      ],
                    ),
                    if (_mode == _SplitMode.custom) ...[
                      const SizedBox(height: 12),
                      _balanceNote(symbol),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: PrimaryButton(
                label: 'Confirm allocation',
                color: AppColors.sage,
                onPressed: canConfirm ? _confirm : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceNote(String symbol) {
    final diff = (_totalCents - _allocatedCents) / 100;
    final ok = _isBalanced;
    final text = ok
        ? 'Fully allocated'
        : diff > 0
            ? '$symbol ${formatMoney(diff)} left to assign'
            : '$symbol ${formatMoney(-diff)} over the budget';

    return Text(
      text,
      textAlign: TextAlign.center,
      style: AppTheme.body(
        11.5,
        weight: FontWeight.w700,
        color: ok ? AppColors.sage : AppColors.coral,
      ),
    );
  }

  Widget _weekCard(int i, double allocated, String symbol) {
    final w = _weeks[i];
    final spent = (widget.spentByWeek != null && i < widget.spentByWeek!.length)
        ? widget.spentByWeek![i]
        : 0.0;
    final progress = allocated <= 0 ? 0.0 : spent / allocated;
    final hot = progress >= budgetAlertThreshold;
    final barColor = hot ? AppColors.coral : AppColors.terracotta;
    final trackColor = hot ? AppColors.coralTint : AppColors.backgroundDeep;
    final balance = allocated - spent;
    final month = _shortMonths[_month.month - 1];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: 'Week ${i + 1}  ',
                      style: AppTheme.body(12.5, weight: FontWeight.w700),
                    ),
                    TextSpan(
                      text: '$month ${w.start}–${w.end}',
                      style: AppTheme.body(11, color: AppColors.textMuted),
                    ),
                  ]),
                ),
              ),
              if (_mode == _SplitMode.even)
                Text('$symbol ${formatMoney(allocated)}',
                    style: AppTheme.body(12.5, weight: FontWeight.w800))
              else
                SizedBox(
                  width: 108,
                  height: 36,
                  child: TextField(
                    controller: _controllers[i],
                    textAlign: TextAlign.right,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    onChanged: (_) => setState(() {}),
                    cursorColor: AppColors.terracotta,
                    style: AppTheme.body(12.5, weight: FontWeight.w800),
                    decoration: InputDecoration(
                      isDense: true,
                      prefixText: '$symbol ',
                      prefixStyle:
                          AppTheme.body(11, color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.terracotta),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: trackColor,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
          if (spent > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text.rich(TextSpan(children: [
                  TextSpan(
                    text: 'Spend: ',
                    style: AppTheme.body(11,
                        weight: FontWeight.w700, color: AppColors.coral),
                  ),
                  TextSpan(
                    text: '$symbol ${formatMoney(spent)}',
                    style: AppTheme.body(11,
                        weight: FontWeight.w700, color: AppColors.coral),
                  ),
                ])),
                Text.rich(TextSpan(children: [
                  TextSpan(
                    text: balance >= 0 ? 'Balance: ' : 'Over: ',
                    style: AppTheme.body(11,
                        weight: FontWeight.w700, color: AppColors.text),
                  ),
                  TextSpan(
                    text: '$symbol ${formatMoney(balance.abs())}',
                    style: AppTheme.body(11,
                        weight: FontWeight.w700, color: AppColors.text),
                  ),
                ])),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.sageTint : AppColors.paper,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.sage : AppColors.border),
        ),
        child: Text(
          label,
          style: AppTheme.body(
            12,
            weight: FontWeight.w700,
            color: selected ? AppColors.text : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
