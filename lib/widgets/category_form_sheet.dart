import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'outline_action_button.dart';
import 'primary_button.dart';

typedef CategoryFormResult = ({String name, IconData icon});

const _icons = <IconData>[
  Icons.restaurant,
  Icons.local_cafe,
  Icons.shopping_bag,
  Icons.directions_bus,
  Icons.movie,
  Icons.home,
  Icons.work,
  Icons.store,
  Icons.pets,
  Icons.favorite,
  Icons.school,
  Icons.flight,
  Icons.savings,
  Icons.fitness_center,
  Icons.medical_services,
  Icons.phone_android,
  Icons.electric_bolt,
  Icons.card_giftcard,
  Icons.trending_up,
  Icons.account_balance_wallet,
  Icons.sports_esports,
  Icons.directions_car,
  Icons.child_care,
  Icons.more_horiz,
];

/// Opens the add / edit category sheet.
/// Returns the chosen name and icon, or null if the user cancels.
///
/// [isDuplicate] is asked whether a name is already taken (so the form can
/// show the error under the field instead of in a snackbar).
Future<CategoryFormResult?> showCategoryFormSheet(
  BuildContext context, {
  String? initialName,
  IconData? initialIcon,
  required bool Function(String name) isDuplicate,
}) {
  return showModalBottomSheet<CategoryFormResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _CategoryForm(
      initialName: initialName,
      initialIcon: initialIcon,
      isDuplicate: isDuplicate,
    ),
  );
}

class _CategoryForm extends StatefulWidget {
  final String? initialName;
  final IconData? initialIcon;
  final bool Function(String name) isDuplicate;

  const _CategoryForm({
    this.initialName,
    this.initialIcon,
    required this.isDuplicate,
  });

  @override
  State<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<_CategoryForm> {
  static const _maxLength = 30;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late IconData _icon;
  late final List<IconData> _choices;

  bool get _isEdit => widget.initialName != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName ?? '');
    _icon = widget.initialIcon ?? _icons.first;
    // Make sure an existing icon that isn't in the list is still selectable.
    _choices = [
      if (!_icons.contains(_icon)) _icon,
      ..._icons,
    ];
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(context, (name: _name.text.trim(), icon: _icon));
  }

  OutlineInputBorder _border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle + title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
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
                        _isEdit ? 'Edit category' : 'Add category',
                        style: AppTheme.heading(18),
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
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Live preview
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: Container(
                              key: ValueKey(_icon),
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.terracottaTint,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Icon(_icon,
                                  size: 24, color: AppColors.terracottaDark),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _name,
                              builder: (_, v, __) {
                                final empty = v.text.trim().isEmpty;
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      empty ? 'Category name' : v.text.trim(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTheme.body(
                                        14.5,
                                        weight: FontWeight.w800,
                                        color: empty
                                            ? AppColors.textFaint
                                            : AppColors.text,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text('Preview',
                                        style: AppTheme.body(11,
                                            color: AppColors.textMuted)),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Name
                    Row(
                      children: [
                        Expanded(
                          child: Text('NAME', style: _labelStyle),
                        ),
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _name,
                          builder: (_, v, __) => Text(
                            '${v.text.length}/$_maxLength',
                            style: AppTheme.body(10.5,
                                color: AppColors.textFaint),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _name,
                      autofocus: !_isEdit,
                      maxLength: _maxLength,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _save(),
                      cursorColor: AppColors.terracotta,
                      style: AppTheme.body(14),
                      validator: (v) {
                        final value = (v ?? '').trim();
                        if (value.isEmpty) {
                          return 'Give your category a name';
                        }
                        if (widget.isDuplicate(value)) {
                          return 'This category already exists';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'e.g. Groceries',
                        hintStyle:
                            AppTheme.body(14, color: AppColors.textFaint),
                        counterText: '',
                        filled: true,
                        fillColor: AppColors.paper,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
                        prefixIcon: const Icon(Icons.sell_outlined,
                            size: 18, color: AppColors.terracottaDark),
                        border: _border(AppColors.border),
                        enabledBorder: _border(AppColors.border),
                        focusedBorder: _border(AppColors.terracotta),
                        errorBorder: _border(AppColors.coral),
                        focusedErrorBorder: _border(AppColors.coral),
                        errorStyle:
                            AppTheme.body(11.5, color: AppColors.coral),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Icon grid
                    Text('ICON', style: _labelStyle),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 6,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      children: [
                        for (final icon in _choices)
                          _IconTile(
                            icon: icon,
                            selected: icon == _icon,
                            onTap: () => setState(() => _icon = icon),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),

          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              children: [
                PrimaryButton(
                  label: _isEdit ? 'Save changes' : 'Add category',
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

  TextStyle get _labelStyle => AppTheme.body(10.5,
      weight: FontWeight.w700, color: AppColors.textMuted);
}

class _IconTile extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _IconTile({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected ? AppColors.terracottaTint : AppColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.terracotta : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Icon(
          icon,
          size: 22,
          color: selected ? AppColors.terracottaDark : AppColors.textMuted,
        ),
      ),
    );
  }
}
