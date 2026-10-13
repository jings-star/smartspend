import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/payment_method.dart';
import '../services/payment_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/payment_type_style.dart';
import '../utils/format_utils.dart';
import '../utils/payment_validators.dart';
import '../widgets/confirm_sheet.dart';
import '../widgets/primary_button.dart';
import '../widgets/round_back_button.dart';

/// Used for both ADD (existing == null) and EDIT (existing != null).
class PaymentMethodFormScreen extends StatefulWidget {
  final PaymentMethod? existing;

  const PaymentMethodFormScreen({super.key, this.existing});

  @override
  State<PaymentMethodFormScreen> createState() =>
      _PaymentMethodFormScreenState();
}

class _PaymentMethodFormScreenState extends State<PaymentMethodFormScreen> {
  static const _banks = [
    'Maybank',
    'CIMB Bank',
    'Public Bank',
    'RHB Bank',
    'Hong Leong Bank',
    'AmBank',
    'Bank Islam',
    'Bank Rakyat',
  ];

  final _formKey = GlobalKey<FormState>();
  final _repo = PaymentRepository.instance;

  late PaymentType _type;
  late final TextEditingController _walletController;
  late final TextEditingController _cardNumberController;
  late final TextEditingController _holderController;
  late final TextEditingController _limitController;
  late String _bankName;
  late bool _isDefault;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;

    _type = e?.type ?? PaymentType.card;
    _walletController = TextEditingController(
      text: (e != null && e.type == PaymentType.ewallet) ? e.title : '',
    );
    _cardNumberController = TextEditingController();
    _holderController = TextEditingController(text: e?.holderName ?? '');
    _limitController = TextEditingController(text: _limitText(e?.monthlyLimit));
    _bankName = (e?.bankName != null && _banks.contains(e!.bankName))
        ? e.bankName!
        : _banks.first;
    _isDefault = e?.isDefault ?? false;
  }

  @override
  void dispose() {
    _walletController.dispose();
    _cardNumberController.dispose();
    _holderController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  // ---------- actions ----------

  PaymentMethod _buildMethod() {
    final e = widget.existing;
    final holder = _holderController.text.trim();

    String title = 'Payment method';
    String? last4;
    String? bank;
    String? holderName;

    switch (_type) {
      case PaymentType.ewallet:
        title = _walletController.text.trim();
        break;
      case PaymentType.card:
        final digits = _cardNumberController.text.replaceAll(RegExp(r'\D'), '');
        last4 = digits.isNotEmpty
            ? digits.substring(digits.length - 4)
            : e?.cardLast4;
        title = last4 == null ? 'Card' : 'Card •••• $last4';
        bank = _bankName;
        holderName = holder;
        break;
      case PaymentType.bank:
        title = 'Bank · $_bankName';
        bank = _bankName;
        holderName = holder;
        break;
      case PaymentType.cash:
        title = 'Cash';
        break;
    }

    final limitText = _limitController.text.trim();
    final limit = limitText.isEmpty ? null : double.tryParse(limitText);

    return PaymentMethod(
      id: e?.id ?? _repo.newId(),
      type: _type,
      title: title,
      holderName: holderName,
      bankName: bank,
      cardLast4: last4,
      isDefault: _isDefault,
      transactionCount: e?.transactionCount ?? 0,
      totalAmount: e?.totalAmount ?? 0,
      monthlyLimit: _type == PaymentType.bank ? null : limit,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final method = _buildMethod();
      if (_isEditing) {
        await _repo.update(method);
      } else {
        await _repo.add(method);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Changes saved' : 'Payment method added',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmSheet(
      context,
      icon: Icons.delete_outline,
      title: 'Delete this payment method?',
      message: 'It will be removed from your payment methods.\n'
          'This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !mounted) return;

    await _repo.delete(widget.existing!.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment method deleted')),
    );
    Navigator.pop(context);
  }

  // ---------- small style helpers ----------

  TextStyle get _capsStyle => AppTheme.body(
        11,
        weight: FontWeight.w700,
        color: AppColors.textMuted,
      ).copyWith(letterSpacing: 0.6);

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color),
    );
  }

  InputDecoration _decoration({
    required String hint,
    required IconData icon,
    String? helper,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTheme.body(14, color: AppColors.textFaint),
      helperText: helper,
      helperStyle: AppTheme.body(11.5, color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.paper,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      prefixIcon: Icon(icon, size: 20, color: AppColors.terracottaDark),
      border: _border(AppColors.border),
      enabledBorder: _border(AppColors.border),
      focusedBorder: _border(AppColors.terracotta),
      errorBorder: _border(AppColors.coral),
      focusedErrorBorder: _border(AppColors.coral),
      errorStyle: AppTheme.body(12, color: AppColors.coral),
    );
  }

  /// A small CAPS label with a field under it.
  Widget _section(String label, Widget field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _capsStyle),
          const SizedBox(height: 8),
          field,
        ],
      ),
    );
  }

  Widget _holderField(String label) {
    return _section(
      label,
      TextFormField(
        controller: _holderController,
        textCapitalization: TextCapitalization.words,
        style: AppTheme.body(14),
        cursorColor: AppColors.terracotta,
        decoration: _decoration(hint: 'Full name', icon: Icons.person_outline),
        validator: (v) => PaymentValidators.notEmpty(v, 'Please enter the name'),
      ),
    );
  }

  Widget _bankField() {
    return _section(
      'BANK NAME',
      DropdownButtonFormField<String>(
        // ignore: deprecated_member_use
        value: _bankName,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted),
        dropdownColor: AppColors.paper,
        style: AppTheme.body(14),
        decoration: _decoration(
          hint: 'Select bank',
          icon: Icons.account_balance_outlined,
        ),
        items: [
          for (final bank in _banks)
            DropdownMenuItem(value: bank, child: Text(bank)),
        ],
        onChanged: (value) => setState(() => _bankName = value ?? _bankName),
      ),
    );
  }

  static String _limitText(double? value) {
    if (value == null) return '';
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  }

  Widget _limitSection() {
    return _section(
      'MONTHLY LIMIT (RM, OPTIONAL)',
      TextFormField(
        controller: _limitController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        style: AppTheme.body(14),
        cursorColor: AppColors.terracotta,
        decoration: _decoration(
          hint: 'e.g. 500',
          icon: Icons.flag_outlined,
          helper: "We'll warn you when you get close.",
        ),
        validator: PaymentValidators.limit,
      ),
    );
  }

  /// The fields change depending on the selected type.
  List<Widget> _typeFields() {
    switch (_type) {
      case PaymentType.ewallet:
        return [
          _section(
            'WALLET NAME',
            TextFormField(
              controller: _walletController,
              textCapitalization: TextCapitalization.words,
              style: AppTheme.body(14),
              cursorColor: AppColors.terracotta,
              decoration: _decoration(
                hint: "e.g. Touch 'n Go",
                icon: Icons.account_balance_wallet_outlined,
              ),
              validator: (v) => PaymentValidators.notEmpty(
                v,
                'Please enter the wallet name',
              ),
            ),
          ),
        ];

      case PaymentType.card:
        final oldLast4 = widget.existing?.cardLast4;
        return [
          _section(
            'CARD NUMBER',
            TextFormField(
              controller: _cardNumberController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                CardNumberFormatter(),
              ],
              style: AppTheme.body(14),
              cursorColor: AppColors.terracotta,
              decoration: _decoration(
                hint: oldLast4 != null
                    ? '•••• •••• •••• $oldLast4'
                    : '1234 5678 9012 4821',
                icon: Icons.credit_card,
                helper: oldLast4 != null
                    ? 'Leave empty to keep the current card'
                    : null,
              ),
              validator: (v) => PaymentValidators.cardNumber(
                v,
                optional: oldLast4 != null,
              ),
            ),
          ),
          _holderField('CARDHOLDER NAME'),
          _bankField(),
        ];

      case PaymentType.bank:
        return [
          _holderField('ACCOUNT HOLDER NAME'),
          _bankField(),
        ];

      case PaymentType.cash:
        return [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Cash needs no extra details.',
              style: AppTheme.body(13, color: AppColors.textMuted),
            ),
          ),
        ];
    }
  }

  // ---------- screen ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 22),

                Text('METHOD TYPE', style: _capsStyle),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final type in PaymentType.values)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: type == PaymentType.values.last ? 0 : 8,
                          ),
                          child: _TypeChip(
                            type: type,
                            selected: type == _type,
                            onTap: () => setState(() => _type = type),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                ..._typeFields(),
                if (_type != PaymentType.bank) _limitSection(),

                const SizedBox(height: 4),
                _buildDefaultSwitch(),
                const SizedBox(height: 22),

                PrimaryButton(
                  label: _isEditing ? 'Save changes' : 'Add payment method',
                  color: AppColors.sage,
                  loading: _saving,
                  onPressed: _save,
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: 'Cancel',
                  color: AppColors.coral,
                  onPressed: _saving ? null : () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: RoundBackButton(),
          ),
          Text(
            _isEditing ? 'Edit payment method' : 'Add payment method',
            style: AppTheme.heading(18),
          ),
          if (_isEditing)
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _delete,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.coralTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppColors.coral,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultSwitch() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set as default',
                style: AppTheme.body(14, weight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                'Use this for future payments',
                style: AppTheme.body(11.5, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        Switch(
          value: _isDefault,
          onChanged: (value) => setState(() => _isDefault = value),
          thumbColor: WidgetStateProperty.all(Colors.white),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.terracotta
                : AppColors.border,
          ),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

/// One of the 4 boxes at the top (E-wallet / Card / Bank / Cash).
class _TypeChip extends StatelessWidget {
  final PaymentType type;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.terracottaTint : AppColors.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.terracotta : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: type.tint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(type.icon, size: 18, color: type.iconColor),
            ),
            const SizedBox(height: 6),
            Text(
              type.label,
              style: AppTheme.body(
                11,
                weight: FontWeight.w700,
                color: selected ? AppColors.terracottaDark : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
