
import 'package:flutter/material.dart';

import '../services/app_entry_preferences.dart';
import '../theme/app_colors.dart';
import 'app_shell.dart';
import 'login_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  bool _loading = false;

  Future<void> _continueAsGuest() async {
    if (_loading) return;

    setState(() => _loading = true);

    try {
      await AppEntryPreferences.chooseGuest();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const AppShell(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save your choice: $e'),
        ),
      );

      setState(() => _loading = false);
    }
  }

  Future<void> _continueWithAccount() async {
    if (_loading) return;

    setState(() => _loading = true);

    try {
      await AppEntryPreferences.chooseAccount();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const LoginScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save your choice: $e'),
        ),
      );

      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F3),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 88,
                    color: AppColors.terracotta,
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'SmartSpend',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF382D29),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Manage your money, track your spending, '
                    'and build better financial habits.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Color(0xFF756762),
                    ),
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed:
                          _loading ? null : _continueWithAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.terracotta,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Login / Register',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed:
                          _loading ? null : _continueAsGuest,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.terracotta,
                        side: const BorderSide(
                          color: AppColors.terracotta,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Continue as Guest',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  if (_loading) ...[
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(
                      color: AppColors.terracotta,
                    ),
                  ],

                  const SizedBox(height: 20),

                  const Text(
                    'Track your spending your way.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8B7D76),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
