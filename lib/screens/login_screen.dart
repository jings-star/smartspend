import 'package:flutter/material.dart';
import 'package:smartspend/screens/transactions_screen.dart';

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
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await _auth.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TransactionsScreen()),
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
                      const SizedBox(height: 28),
                      Text(
                        'Welcome back',
                        textAlign: TextAlign.center,
                        style: AppTheme.heading(30),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to keep tracking your spending.',
                        textAlign: TextAlign.center,
                        style: AppTheme.body(13, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 32),
                      AppTextField(
                        label: 'Email address',
                        hint: 'name@example.com',
                        icon: Icons.mail_outline,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Password',
                        hint: 'Enter your password',
                        icon: Icons.lock_outline,
                        controller: _passwordController,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        validator: Validators.loginPassword,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ForgotPasswordScreen(
                                initialEmail: _emailController.text.trim(),
                              ),
                            ),
                          ),
                          child: Text(
                            'Forgot password?',
                            style: AppTheme.body(
                              13,
                              weight: FontWeight.w700,
                              color: AppColors.terracottaDark,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      PrimaryButton(
                        label: 'Sign in',
                        loading: _loading,
                        onPressed: _signIn,
                      ),
                      const SizedBox(height: 24),
                      const OrDivider(),
                      const SizedBox(height: 20),
                      GoogleButton(onPressed: _googleSignIn),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            AuthSwitchLink(
              question: "Don't have an account?",
              action: 'Sign up',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
