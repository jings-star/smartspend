import 'package:flutter/material.dart';
import 'package:smartspend/screens/login_screen.dart';

// import 'screens/login_screen.dart';
// import 'screens/forgot_password_screen.dart';
import 'screens/app_shell.dart';
import 'theme/app_theme.dart';

void main() {
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
      home: const AppShell(),
      // home: const LoginScreen(),
    );
  }
}