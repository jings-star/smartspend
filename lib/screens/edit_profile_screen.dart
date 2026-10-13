import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/round_back_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // TODO: load these from the real user.
  final _nickname = TextEditingController(text: 'Janice');
  final _email = TextEditingController(text: 'janice@gmail.com');
  final _phone = TextEditingController();
  final _idController = TextEditingController(text: '2507775');

  final _currentPw = TextEditingController();
  final _newPw = TextEditingController();
  final _confirmPw = TextEditingController();

  bool _showPassword = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _nickname,
      _email,
      _phone,
      _idController,
      _currentPw,
      _newPw,
      _confirmPw,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    // TODO: call your service to update nickname / email / phone, and if
    // _showPassword && _newPw.text.isNotEmpty, change the password with
    // _currentPw.text and _newPw.text.
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile updated',
            style: AppTheme.body(13, color: Colors.white)),
      ),
    );
    Navigator.pop(context);
  }

  String? _validateCurrent(String? v) {
    if (!_showPassword || (_newPw.text.isEmpty && (v ?? '').isEmpty)) {
      return null; // not changing password
    }
    if ((v ?? '').isEmpty) return 'Enter your current password';
    return null;
  }

  String? _validateNew(String? v) {
    if (!_showPassword) return null;
    final value = v ?? '';
    if (value.isEmpty) {
      return _currentPw.text.isEmpty ? null : 'Enter a new password';
    }
    if (value.length < 8) return 'Use at least 8 characters';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (!_showPassword || _newPw.text.isEmpty) return null;
    if (v != _newPw.text) return 'Passwords do not match';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              SizedBox(
                height: 36,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Align(
                        alignment: Alignment.centerLeft,
                        child: RoundBackButton()),
                    Text('Edit profile', style: AppTheme.heading(17)),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 66,
                      height: 66,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.backgroundDeep,
                        shape: BoxShape.circle,
                      ),
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _nickname,
                        builder: (_, v, __) => Text(
                          v.text.isEmpty ? '?' : v.text[0].toUpperCase(),
                          style: AppTheme.heading(24,
                              color: AppColors.terracottaDark),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: AppColors.terracotta,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.photo_camera_outlined,
                            size: 13, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _InlineField(
                  label: 'ID', controller: _idController, readOnly: true),
              const SizedBox(height: 12),
              _InlineField(label: 'NICKNAME', controller: _nickname),
              const SizedBox(height: 12),
              _InlineField(
                label: 'EMAIL',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _InlineField(
                label: 'PHONE NUMBER',
                controller: _phone,
                hint: 'Add phone number',
                keyboardType: TextInputType.phone,
                action: TextInputAction.done,
              ),
              const SizedBox(height: 22),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() => _showPassword = !_showPassword),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.coralTint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.lock_outline,
                            size: 20, color: AppColors.coral),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text('Change password',
                            style:
                                AppTheme.body(13.5, weight: FontWeight.w700)),
                      ),
                      AnimatedRotation(
                        turns: _showPassword ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.keyboard_arrow_down,
                            size: 22, color: AppColors.textFaint),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _showPassword
                    ? Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Column(
                          children: [
                            AppTextField(
                              label: 'Current password',
                              hint: 'Enter current password',
                              icon: Icons.lock_outline,
                              controller: _currentPw,
                              isPassword: true,
                              validator: _validateCurrent,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'New password',
                              hint: 'At least 8 characters',
                              icon: Icons.lock_outline,
                              controller: _newPw,
                              isPassword: true,
                              validator: _validateNew,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Confirm new password',
                              hint: 'Repeat new password',
                              icon: Icons.lock_outline,
                              controller: _confirmPw,
                              isPassword: true,
                              textInputAction: TextInputAction.done,
                              validator: _validateConfirm,
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                label: 'Save Changes',
                color: AppColors.sage,
                loading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Label on the left, value on the right, all in one rounded box.
class _InlineField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool readOnly;
  final String? hint;
  final TextInputType keyboardType;
  final TextInputAction action;

  const _InlineField({
    required this.label,
    required this.controller,
    this.readOnly = false,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.action = TextInputAction.next,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: AppTheme.body(11,
                weight: FontWeight.w700, color: AppColors.textFaint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              keyboardType: keyboardType,
              textInputAction: action,
              textAlign: TextAlign.right,
              cursorColor: AppColors.terracotta,
              style: AppTheme.body(13, weight: FontWeight.w700),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: AppTheme.body(13, color: AppColors.textFaint),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
