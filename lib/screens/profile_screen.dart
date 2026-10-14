import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/guest_mode.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/currency_sheet.dart';
import '../widgets/guest_banner.dart';
import '../widgets/logout_sheet.dart';
import 'category_screen.dart';
import 'edit_profile_screen.dart';
import 'payment_methods_screen.dart';
import 'preferences_screen.dart';
import 'recurring_screen.dart';
import 'login_screen.dart';
import '../services/app_entry_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _currency = 'MYR'; // TODO: load/save with the user's preferences
  String _nickname = 'Guest';

  bool get _isGuest => FirebaseAuth.instance.currentUser == null;

  // TODO: replace with real stats.
  static const _daysTracking = 36;
  static const _logged = 34;
  static const _thisMonth = 5;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _nickname = 'Guest');
      return;
    }
    String name = user.displayName ?? user.email?.split('@').first ?? 'User';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final saved = doc.data()?['nickname'] as String?;
      if (saved != null && saved.trim().isNotEmpty) name = saved;
    } catch (_) {
      // offline etc.: keep the fallback name
    }
    if (mounted) setState(() => _nickname = name);
  }

  Future<void> _pickCurrency() async {
    final picked = await showCurrencySheet(context, selected: _currency);
    if (picked != null && mounted) setState(() => _currency = picked);
  }

  /// Guests cannot use account features: send them to log in.
  void _askToLogin() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('Log in required', style: AppTheme.heading(20)),
        content: Text(
          'Log in or create an account to use this feature and save your data.',
          style: AppTheme.body(13, color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Not now',
              style: AppTheme.body(13, weight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              GuestMode.isGuest.value = false; // AuthGate shows login
            },
            child: Text(
              'Log in',
              style: AppTheme.body(
                13,
                weight: FontWeight.w700,
                color: AppColors.terracotta,
              ),
            ),
          ),
        ],
      ),
    );
  }

Future<void> _logout() async {
  final confirmed = await showLogoutSheet(context);
  if (!confirmed || !mounted) return;

  await FirebaseAuth.instance.signOut();
  GuestMode.isGuest.value = false;
  await AppEntryPreferences.chooseAccount();

  if (!mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false, // clear the whole stack so Back can't return to the app
  );
}

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      // Removes the profile document. If you store expenses etc. under
      // users/{uid}/..., delete those too (or use a Cloud Function).
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();
      await user.delete();
      GuestMode.isGuest.value = false;
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _snack('Please log out and log in again, then retry deleting.');
      } else {
        _snack(e.message ?? 'Could not delete account.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final guest = _isGuest;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _TitleBar(),
            const SizedBox(height: 16),
            if (guest) const GuestBanner(),
            _Header(
              initial: _nickname.isEmpty ? '?' : _nickname[0].toUpperCase(),
              currency: _currency,
              onCurrencyTap: _pickCurrency,
            ),
            const SizedBox(height: 18),
            const _StatsCard(
              days: _daysTracking,
              logged: _logged,
              thisMonth: _thisMonth,
            ),
            const SizedBox(height: 16),
            _MenuCard(
              items: [
                _MenuItem(
                  title: 'Edit profile',
                  icon: Icons.manage_accounts_outlined,
                  tint: AppColors.terracottaTint,
                  onTap: () async {
                    if (guest) return _askToLogin();
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );
                    _loadUser(); // refresh name after editing
                  },
                ),
                _MenuItem(
                  title: 'Payment Method',
                  icon: Icons.credit_card_outlined,
                  tint: AppColors.terracottaTint,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PaymentMethodsScreen(),
                    ),
                  ),
                ),
                _MenuItem(
                  title: 'Preferences',
                  icon: Icons.pie_chart_outline,
                  tint: AppColors.sageTint,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PreferencesScreen(),
                    ),
                  ),
                ),
                _MenuItem(
                  title: 'Recurring Transactions',
                  icon: Icons.event_repeat_outlined,
                  tint: AppColors.goldTint,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RecurringScreen()),
                  ),
                ),
                _MenuItem(
                  title: 'Categories',
                  icon: Icons.sell_outlined,
                  tint: AppColors.coralTint,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CategoryScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!guest) ...[
              _PillButton(
                label: 'Log out',
                icon: Icons.logout,
                color: AppColors.text,
                onTap: _logout,
              ),
              const SizedBox(height: 12),
              _PillButton(
                label: 'Delete account',
                color: AppColors.coral,
                onTap: () => _confirmDelete(context),
              ),
            ],
            ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('Delete account?', style: AppTheme.heading(20)),
        content: Text(
          'This permanently removes your account and data.',
          style: AppTheme.body(13, color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTheme.body(13, weight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteAccount();
            },
            child: Text(
              'Delete',
              style: AppTheme.body(
                13,
                weight: FontWeight.w700,
                color: AppColors.coral,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [Text('My Profile', style: AppTheme.heading(17))],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String initial;
  final String currency;
  final VoidCallback onCurrencyTap;
  const _Header({
    required this.initial,
    required this.currency,
    required this.onCurrencyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.backgroundDeep,
                shape: BoxShape.circle,
              ),
              child: Text(
                initial,
                style: AppTheme.heading(20, color: AppColors.terracottaDark),
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.terracotta,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, size: 12, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              const _Tag(
                'Student',
                AppColors.terracottaTint,
                icon: Icons.school_outlined,
              ),
              _Tag(currency, AppColors.sageTint, onTap: onCurrencyTap),
              const _Tag(
                'Balanced Saver',
                AppColors.goldTint,
                icon: Icons.auto_awesome,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final VoidCallback? onTap;
  const _Tag(this.label, this.color, {this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: AppColors.terracottaDark),
              const SizedBox(width: 4),
            ],
            Text(label, style: AppTheme.body(11, weight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: AppColors.paper,
  borderRadius: BorderRadius.circular(22),
  border: Border.all(color: AppColors.border),
);

class _StatsCard extends StatelessWidget {
  final int days, logged, thisMonth;
  const _StatsCard({
    required this.days,
    required this.logged,
    required this.thisMonth,
  });

  Widget _stat(IconData icon, int value, String label) => Expanded(
    child: Column(
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(height: 8),
        Text('$value', style: AppTheme.heading(20)),
        const SizedBox(height: 2),
        Text(label, style: AppTheme.body(11, color: AppColors.textMuted)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final divider = Container(width: 1, height: 46, color: AppColors.border);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _stat(Icons.calendar_today_outlined, days, 'Days tracking'),
          divider,
          _stat(Icons.assignment_outlined, logged, 'Logged'),
          divider,
          _stat(Icons.account_balance_wallet_outlined, thisMonth, 'This month'),
        ],
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;
  const _MenuItem({
    required this.title,
    required this.icon,
    required this.tint,
    required this.onTap,
  });
}

class _MenuCard extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            InkWell(
              onTap: items[i].onTap,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: items[i].tint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        items[i].icon,
                        size: 20,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        items[i].title,
                        style: AppTheme.body(13.5, weight: FontWeight.w700),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppColors.textFaint,
                    ),
                  ],
                ),
              ),
            ),
            if (i != items.length - 1)
              const Divider(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}

/// White pill with centered label (Log out / Delete account).
class _PillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback onTap;
  const _PillButton({
    required this.label,
    this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.paper,
          side: const BorderSide(color: AppColors.border),
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: AppTheme.body(13.5, weight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
