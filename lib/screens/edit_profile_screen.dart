import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  final _nickname = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _idController = TextEditingController();

  final _currentPw = TextEditingController();
  final _newPw = TextEditingController();
  final _confirmPw = TextEditingController();

  bool _showPassword = false;
  bool _saving = false;
  bool _loading = true;

  User? get _user => FirebaseAuth.instance.currentUser;

  /// Only email+password accounts can change email/password here.
  /// (Google sign-in accounts manage these in their Google account.)
  bool get _hasPassword =>
      _user?.providerData.any((p) => p.providerId == 'password') ?? false;

  DocumentReference<Map<String, dynamic>> get _doc =>
      FirebaseFirestore.instance.collection('users').doc(_user!.uid);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = _user;
    if (user == null) {
      // Guests should never reach this screen, but be safe.
      if (mounted) Navigator.pop(context);
      return;
    }
    _email.text = user.email ?? '';
    _nickname.text = user.displayName ?? '';
    _idController.text = user.uid.substring(0, 7).toUpperCase();
    try {
      final data = (await _doc.get()).data();
      if (data != null) {
        _nickname.text = (data['nickname'] as String?) ?? _nickname.text;
        _phone.text = (data['phone'] as String?) ?? '';
        final studentId = data['studentId'] as String?;
        if (studentId != null && studentId.isNotEmpty) {
          _idController.text = studentId;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

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

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg, style: AppTheme.body(13, color: Colors.white))),
      );

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = _user;
    if (user == null) return;
    setState(() => _saving = true);

    try {
      // 1) Nickname + phone
      final nickname = _nickname.text.trim();
      await user.updateDisplayName(nickname);
      await _doc.set({
        'nickname': nickname,
        'phone': _phone.text.trim(),
      }, SetOptions(merge: true));

      // 2) Password (needs the current password to re-verify)
      if (_hasPassword && _showPassword && _newPw.text.isNotEmpty) {
        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPw.text,
        );
        await user.reauthenticateWithCredential(cred);
        await user.updatePassword(_newPw.text);
      }

      // 3) Email: Firebase sends a verification link to the NEW address;
      //    the email only changes after they tap it.
      final newEmail = _email.text.trim();
      var emailNote = '';
      if (_hasPassword && newEmail.isNotEmpty && newEmail != user.email) {
        await user.verifyBeforeUpdateEmail(newEmail);
        emailNote = ' Check $newEmail to confirm your new email.';
      }

      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Profile updated.$emailNote');
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          _snack('Current password is incorrect.');
          break;
        case 'requires-recent-login':
          _snack('Please log out and log in again, then retry.');
          break;
        case 'weak-password':
          _snack('New password is too weak.');
          break;
        case 'email-already-in-use':
          _snack('That email is already in use.');
          break;
        default:
          _snack(e.message ?? 'Something went wrong.');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Could not save. Check your connection and try again.');
    }
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
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.terracotta),
        ),
      );
    }
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
                readOnly: !_hasPassword,
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
              if (_hasPassword) ...[
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
                              style: AppTheme.body(13.5,
                                  weight: FontWeight.w700)),
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
              ],
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