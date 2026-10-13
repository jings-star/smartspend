import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'transactions_screen.dart';
import 'profile_screen.dart';
import 'savings_goals_screen.dart';
import 'budget_screen.dart';
import 'dashboard_screen.dart';

/// Owns the bottom navigation bar and switches between the main pages.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  // Order must match the bottom navigation items below.
  final _pages = const <Widget>[
    TransactionsScreen(),
    SavingsGoalsScreen(),
    DashboardScreen(),
    BudgetScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.terracotta,
        unselectedItemColor: AppColors.textFaint,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.savings_outlined),
            label: 'Saving',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.account_balance_wallet_outlined,
              size: 22,
            ),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
