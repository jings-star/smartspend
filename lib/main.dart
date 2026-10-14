
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/app_shell.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'services/app_entry_preferences.dart';
import 'services/guest_migration.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await AppEntryPreferences.initialize();

  runApp(const SmartSpendApp());
}

class SmartSpendApp extends StatelessWidget {
  const SmartSpendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartSpend',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Wait until Firebase has restored the login session.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.terracotta,
              ),
            ),
          );
        }

        // An authenticated user goes straight to the app.
        if (snapshot.hasData) {
          return const LoggedInEntry();
        }

        // No signed-in account: restore the saved entry choice.
        if (AppEntryPreferences.isGuest) {
          return const AppShell();
        }

        // A first-time user sees the landing page.
        if (!AppEntryPreferences.hasChosenEntry) {
          return const LandingScreen();
        }

        // A returning user who chose account access sees login.
        return const LoginScreen();
      },
    );
  }
}

class LoggedInEntry extends StatefulWidget {
  const LoggedInEntry({super.key});

  @override
  State<LoggedInEntry> createState() => _LoggedInEntryState();
}

class _LoggedInEntryState extends State<LoggedInEntry> {
  @override
  void initState() {
    super.initState();

    // A signed-in user should no longer be treated as a guest.
    AppEntryPreferences.chooseAccount();

    // Transfer guest data after login, if applicable.
    migrateGuestData();
  }

  @override
  Widget build(BuildContext context) {
    return const AppShell();
  }
}
