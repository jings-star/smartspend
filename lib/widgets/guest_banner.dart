import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import '../services/app_entry_preferences.dart';
import '../theme/app_colors.dart';

/// Shows only for guests. Put it at the top of Home or Profile.
class GuestBanner extends StatelessWidget {
  const GuestBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser != null) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.terracotta.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.terracotta),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'You are using guest mode. Your data will be lost when you '
              'close the app.',
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              await AppEntryPreferences.chooseAccount();
              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            icon: const Icon(Icons.login, size: 18),
            label: const Text('Log in / Sign up'),
          ),
        ],
      ),
    );
  }
}