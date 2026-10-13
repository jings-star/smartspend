import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/app_text_field.dart';
import '../widgets/auth_switch_link.dart';
import '../widgets/google_button.dart';
import '../widgets/or_divider.dart';
import '../widgets/primary_button.dart';
import '../widgets/round_back_button.dart';
import 'home_placeholder.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await _auth.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      // Remove Login + Register from the stack, then show the home page.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePlaceholder()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    await _auth.signInWithGoogle();
    if (!mounted) return;
    _showMessage('Google sign-in is not connected yet');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      Text(
                        'Create account',
                        textAlign: TextAlign.center,
                        style: AppTheme.heading(28),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Get started with your free SmartSpend account.',
                        textAlign: TextAlign.center,
                        style: AppTheme.body(13, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 28),
                      AppTextField(
                        label: 'Full name',
                        hint: 'Your full name',
                        icon: Icons.person_outline,
                        controller: _nameController,
                        validator: Validators.name,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: 'Email address',
                        hint: 'name@example.com',
                        icon: Icons.mail_outline,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: 'Password',
                        hint: 'At least 8 characters',
                        icon: Icons.lock_outline,
                        controller: _passwordController,
                        isPassword: true,
                        validator: Validators.newPassword,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: 'Confirm password',
                        hint: 'Repeat your password',
                        icon: Icons.lock_outline,
                        controller: _confirmController,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        validator: (value) => Validators.confirmPassword(
                          value,
                          _passwordController.text,
                        ),
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: 'Create account',
                        loading: _loading,
                        onPressed: _register,
                      ),
                      const SizedBox(height: 22),
                      const OrDivider(),
                      const SizedBox(height: 18),
                      GoogleButton(onPressed: _googleSignIn),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            AuthSwitchLink(
              question: 'Already have an account?',
              action: 'Sign in',
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
