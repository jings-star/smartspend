import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Small uppercase label above a field ("CATEGORY", "AMOUNT (RM)").
class FormLabel extends StatelessWidget {
  final String text;
  const FormLabel(this.text, {super.key});

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

/// Rounded text field with a leading icon.
class FormInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextCapitalization capitalization;

  const FormInput({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.formatters,
    this.validator,
    this.maxLines = 1,
    this.capitalization = TextCapitalization.none,
  });

  /// Numeric keyboard that only accepts digits, "." and ",".
  FormInput.money({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.validator,
  })  : keyboardType = const TextInputType.numberWithOptions(decimal: true),
        formatters = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
        maxLines = 1,
        capitalization = TextCapitalization.none;

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
        prefixIcon: Icon(icon, size: 18, color: AppColors.terracottaDark),
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

/// Rounded box that wraps non-text content (dropdowns, date pickers).
class FormBox extends StatelessWidget {
  final Widget child;
  const FormBox({super.key, required this.child});

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

class FormDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final IconData? icon;

  const FormDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return FormBox(
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

/// Title + subtitle on the left, terracotta switch on the right.
class FormSwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const FormSwitchRow({
    super.key,
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
