import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/icon_badge.dart';
import '../widgets/info_banner.dart';
import '../widgets/outline_action_button.dart';
import '../widgets/primary_button.dart';
import '../widgets/round_back_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  /// If the user already typed an email on the login screen, we reuse it.
  final String initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _auth = AuthService();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _sendLink() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    setState(() => _loading = true);
    try {
      await _auth.sendPasswordReset(email: email);
      if (!mounted) return;
      _showMessage('Reset link sent to $email');
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTheme.body(
      11,
      weight: FontWeight.w700,
      color: AppColors.textMuted,
    ).copyWith(letterSpacing: 0.6);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: RoundBackButton(),
                      ),
                      const SizedBox(height: 24),
                      const Center(child: IconBadge(icon: Icons.lock_outline)),
                      const SizedBox(height: 16),
                      Text(
                        'Reset your password',
                        textAlign: TextAlign.center,
                        style: AppTheme.heading(24),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "Enter the email on your account and we'll send a link to reset it.",
                          textAlign: TextAlign.center,
                          style: AppTheme.body(
                            13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        validator: Validators.email,
                        style: AppTheme.body(15),
                        cursorColor: AppColors.terracotta,
                        decoration: InputDecoration(
                          labelText: 'EMAIL ADDRESS',
                          labelStyle: labelStyle,
                          floatingLabelStyle: labelStyle,
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          hintText: 'name@example.com',
                          hintStyle: AppTheme.body(
                            15,
                            color: AppColors.textFaint,
                          ),
                          filled: true,
                          fillColor: AppColors.paper,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          border: _border(AppColors.border),
                          enabledBorder: _border(AppColors.border),
                          focusedBorder: _border(AppColors.terracotta),
                          errorBorder: _border(AppColors.coral),
                          focusedErrorBorder: _border(AppColors.coral),
                          errorStyle: AppTheme.body(12, color: AppColors.coral),
                        ),
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: 'Send reset link',
                        loading: _loading,
                        onPressed: _sendLink,
                      ),
                      const SizedBox(height: 12),
                      OutlineActionButton(
                        label: 'Back to login',
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: InfoBanner(text: 'Link expires in 15 minutes!'),
            ),
          ],
        ),
      ),
    );
  }
}
