import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

class _Currency {
  final String code, name, symbol;
  final Color tint, ink;
  const _Currency(this.code, this.name, this.symbol, this.tint, this.ink);
}

const _currencies = <_Currency>[
  _Currency('MYR', 'Malaysian Ringgit', 'RM', AppColors.terracottaTint,
      AppColors.terracottaDark),
  _Currency('USD', 'US Dollar', r'$', AppColors.sageTint, AppColors.sage),
  _Currency('SGD', 'Singapore Dollar', r'S$', AppColors.goldTint,
      AppColors.gold),
  _Currency('JPY', 'Japanese Yen', '¥', AppColors.coralTint, AppColors.coral),
  _Currency('EUR', 'Euro', '€', AppColors.sageTint, AppColors.sage),
  _Currency('GBP', 'British Pound', '£', AppColors.terracottaTint,
      AppColors.terracottaDark),
  _Currency('THB', 'Thai Baht', '฿', AppColors.goldTint, AppColors.gold),
  _Currency('IDR', 'Indonesian Rupiah', 'Rp', AppColors.coralTint,
      AppColors.coral),
  _Currency('AUD', 'Australian Dollar', r'A$', AppColors.sageTint,
      AppColors.sage),
];

/// Shows the "Preferred currency" sheet.
/// Returns the chosen currency code (e.g. 'MYR'), or null if dismissed.
///
///   final code = await showCurrencySheet(context, selected: 'MYR');
Future<String?> showCurrencySheet(BuildContext context,
    {required String selected}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _CurrencySheet(selected: selected),
  );
}

class _CurrencySheet extends StatefulWidget {
  final String selected;
  const _CurrencySheet({required this.selected});

  @override
  State<_CurrencySheet> createState() => _CurrencySheetState();
}

class _CurrencySheetState extends State<_CurrencySheet> {
  final _search = TextEditingController();
  late String _picked = widget.selected;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final list = _currencies
        .where((c) =>
            q.isEmpty ||
            c.name.toLowerCase().contains(q) ||
            c.code.toLowerCase().contains(q))
        .toList();
    final maxListHeight = MediaQuery.of(context).size.height * 0.38;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
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
                      child: Text('Preferred currency',
                          style: AppTheme.heading(20))),
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
                'Amounts across SmartSpend display in this currency.',
                style: AppTheme.body(12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                cursorColor: AppColors.terracotta,
                style: AppTheme.body(13),
                decoration: InputDecoration(
                  hintText: 'Search currency...',
                  hintStyle: AppTheme.body(13, color: AppColors.textFaint),
                  filled: true,
                  fillColor: AppColors.paper,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: _border(AppColors.border),
                  focusedBorder: _border(AppColors.terracotta),
                  border: _border(AppColors.border),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                constraints: BoxConstraints(maxHeight: maxListHeight),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: list.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text('No currency found',
                              style: AppTheme.body(12.5,
                                  color: AppColors.textMuted)),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: list.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: AppColors.border),
                        itemBuilder: (_, i) => _row(list[i]),
                      ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Confirm',
                color: AppColors.sage,
                onPressed: () => Navigator.pop(context, _picked),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(_Currency c) {
    final isSelected = c.code == _picked;
    return InkWell(
      onTap: () => setState(() => _picked = c.code),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.tint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(c.symbol,
                  style: AppTheme.body(14,
                      weight: FontWeight.w800, color: c.ink)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name,
                      style: AppTheme.body(13, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(c.code,
                      style: AppTheme.body(10.5, color: AppColors.textMuted)),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.terracotta,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color),
      );
}
