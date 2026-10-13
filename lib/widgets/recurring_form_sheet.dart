import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/recurring_transaction.dart';
import '../services/recurring_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'delete_recurring_dialog.dart';
import 'outline_action_button.dart';
import 'primary_button.dart';

/// Opens the add / edit sheet.
/// Pass [existing] to edit (also shows the Delete link), or nothing to add.
/// The sheet saves to RecurringStore itself.
Future<void> showRecurringFormSheet(
  BuildContext context, {
  RecurringTransaction? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _RecurringForm(existing: existing),
  );
}

class _RecurringForm extends StatefulWidget {
  final RecurringTransaction? existing;
  const _RecurringForm({this.existing});

  @override
  State<_RecurringForm> createState() => _RecurringFormState();
}

class _RecurringFormState extends State<_RecurringForm> {
  final _formKey = GlobalKey<FormState>();
  final _store = RecurringStore.instance;

  late final TextEditingController _name;
  late final TextEditingController _amount;
  late final TextEditingController _notes;

  late RecurringType _type;
  late Frequency _frequency;
  late String _category;
  late DateTime _start;
  late String _method;
  late bool _active;
  late bool _remind;

  bool get _isEdit => widget.existing != null;
  List<String> get _categories =>
      _type == RecurringType.expense ? expenseCategories : incomeCategories;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _amount = TextEditingController(
        text: e == null ? '' : e.amount.toStringAsFixed(2));
    _notes = TextEditingController(text: e?.notes ?? '');
    _type = e?.type ?? RecurringType.expense;
    _frequency = e?.frequency ?? Frequency.monthly;
    _category = e?.category ?? expenseCategories.first;
    _start = e?.startDate ?? DateTime.now();
    _method = e?.paymentMethod ?? paymentMethods.first;
    _active = e?.active ?? true;
    _remind = e?.remind ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _setType(RecurringType t) {
    setState(() {
      _type = t;
      if (!_categories.contains(_category)) _category = _categories.first;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _start = picked);
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final t = RecurringTransaction(
      id: widget.existing?.id ?? _store.newId(),
      name: _name.text.trim(),
      amount: double.parse(_amount.text.trim().replaceAll(',', '')),
      type: _type,
      frequency: _frequency,
      category: _category,
      startDate: _start,
      paymentMethod: _method,
      notes: _notes.text.trim(),
      active: _active,
      remind: _remind,
    );

    final messenger = ScaffoldMessenger.of(context);
    _isEdit ? _store.update(t) : _store.add(t);
    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(
      content: Text(_isEdit ? 'Changes saved' : 'Recurring transaction added',
          style: AppTheme.body(13, color: Colors.white)),
    ));
  }

  Future<void> _delete() async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final confirmed = await showDeleteRecurringDialog(context);
    if (!confirmed) return;
    _store.delete(widget.existing!.id);
    nav.pop();
    messenger.showSnackBar(SnackBar(
      content: Text('Recurring transaction deleted',
          style: AppTheme.body(13, color: Colors.white)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle + title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
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
                        _isEdit
                            ? 'Edit recurring transaction'
                            : 'Add recurring transaction',
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
                const SizedBox(height: 12),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Scrollable form
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _TypePill(
                            label: 'Expense',
                            selected: _type == RecurringType.expense,
                            fill: AppColors.coralTint,
                            line: AppColors.coral,
                            onTap: () => _setType(RecurringType.expense),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TypePill(
                            label: 'Income',
                            selected: _type == RecurringType.income,
                            fill: AppColors.sageTint,
                            line: AppColors.sage,
                            onTap: () => _setType(RecurringType.income),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const _Label('NAME'),
                    _Input(
                      controller: _name,
                      hint: 'e.g. Spotify Premium',
                      icon: Icons.event_repeat_outlined,
                      capitalization: TextCapitalization.words,
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? 'Give it a name'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Label('AMOUNT (${currencySymbol()})'),
                              _Input(
                                controller: _amount,
                                hint: '0.00',
                                icon: Icons.attach_money,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                formatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9.,]')),
                                ],
                                validator: (v) {
                                  final n = double.tryParse(
                                      (v ?? '').trim().replaceAll(',', ''));
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _Label('FREQUENCY'),
                              _Dropdown<Frequency>(
                                value: _frequency,
                                items: Frequency.values,
                                labelOf: (f) => f.label,
                                onChanged: (f) =>
                                    setState(() => _frequency = f),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const _Label('CATEGORY'),
                    _Dropdown<String>(
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _Label('START DATE'),
                              GestureDetector(
                                onTap: _pickDate,
                                child: _Box(
                                  child: Row(
                                    children: [
                                      const Icon(
                                          Icons.calendar_today_outlined,
                                          size: 18,
                                          color: AppColors.terracottaDark),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(formField(_start),
                                            style: AppTheme.body(12.5)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _Label('PAYMENT METHOD'),
                              _Dropdown<String>(
                                value: _method,
                                items: paymentMethods,
                                labelOf: (m) => m,
                                onChanged: (m) =>
                                    setState(() => _method = m),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const _Label('NOTES (OPTIONAL)'),
                    _Input(
                      controller: _notes,
                      hint: 'Add a note...',
                      icon: Icons.edit_outlined,
                      maxLines: 3,
                      topAlignIcon: true,
                      keyboardType: TextInputType.multiline,
                      capitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 14),
                    _SwitchRow(
                      title: 'Active',
                      subtitle: 'Turn off to pause without deleting',
                      value: _active,
                      onChanged: (v) => setState(() => _active = v),
                    ),
                    const SizedBox(height: 8),
                    _SwitchRow(
                      title: 'Remind me',
                      subtitle: "Notify 1 day before it's due",
                      value: _remind,
                      onChanged: (v) => setState(() => _remind = v),
                    ),
                    if (_isEdit) ...[
                      const SizedBox(height: 6),
                      Center(
                        child: TextButton.icon(
                          onPressed: _delete,
                          icon: const Icon(Icons.delete_outline,
                              size: 16, color: AppColors.coral),
                          label: Text(
                            'Delete recurring transaction',
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

          // Pinned buttons
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              children: [
                PrimaryButton(
                  label: _isEdit ? 'Save changes' : 'Add transaction',
                  onPressed: _save,
                ),
                const SizedBox(height: 10),
                OutlineActionButton(
                  label: 'Cancel',
                  borderColor: AppColors.border,
                  textColor: AppColors.text,
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

// ---------- small building blocks ----------

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: AppTheme.body(10.5,
            weight: FontWeight.w700, color: AppColors.textMuted),
      ),
    );
  }
}

OutlineInputBorder _border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c),
    );

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool topAlignIcon;
  final TextCapitalization capitalization;

  const _Input({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.formatters,
    this.validator,
    this.maxLines = 1,
    this.topAlignIcon = false,
    this.capitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      validator: validator,
      maxLines: maxLines,
      textCapitalization: capitalization,
      cursorColor: AppColors.terracotta,
      style: AppTheme.body(13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTheme.body(13, color: AppColors.textFaint),
        filled: true,
        fillColor: AppColors.paper,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        prefixIcon: topAlignIcon
            ? Align(
                alignment: Alignment.topCenter,
                widthFactor: 1,
                heightFactor: 1,
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Icon(icon, size: 16, color: AppColors.textMuted),
                ),
              )
            : Icon(icon, size: 18, color: AppColors.terracottaDark),
        border: _border(AppColors.border),
        enabledBorder: _border(AppColors.border),
        focusedBorder: _border(AppColors.terracotta),
        errorBorder: _border(AppColors.coral),
        focusedErrorBorder: _border(AppColors.coral),
        errorStyle: AppTheme.body(11, color: AppColors.coral),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  final Widget child;
  const _Box({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final IconData? icon;

  const _Dropdown({
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _Box(
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.terracottaDark),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                dropdownColor: AppColors.paper,
                borderRadius: BorderRadius.circular(14),
                icon: const Icon(Icons.keyboard_arrow_down,
                    size: 20, color: AppColors.textMuted),
                style: AppTheme.body(12.5),
                items: [
                  for (final it in items)
                    DropdownMenuItem<T>(
                      value: it,
                      child: Text(labelOf(it), overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color fill;
  final Color line;
  final VoidCallback onTap;

  const _TypePill({
    required this.label,
    required this.selected,
    required this.fill,
    required this.line,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? fill : AppColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? line : AppColors.border),
        ),
        child: Text(
          label,
          style: AppTheme.body(12.5,
              weight: FontWeight.w700,
              color: selected ? AppColors.text : AppColors.textMuted),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTheme.body(13, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: AppTheme.body(11, color: AppColors.textMuted)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          thumbColor: const WidgetStatePropertyAll(Colors.white),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.terracotta
                : AppColors.border,
          ),
          trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ],
    );
  }
}
