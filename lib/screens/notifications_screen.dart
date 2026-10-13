import 'package:flutter/material.dart';
import '../models/app_notification.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/round_back_button.dart';
import 'notification_tile.dart';

enum _Filter { all, unread, critical, warning, success }

extension on _Filter {
  String get label => switch (this) {
        _Filter.all => 'All',
        _Filter.unread => 'Unread',
        _Filter.critical => 'Critical',
        _Filter.warning => 'Warning',
        _Filter.success => 'Success',
      };

  bool matches(AppNotification n) => switch (this) {
        _Filter.all => true,
        _Filter.unread => !n.read,
        _Filter.critical => n.severity == NotifSeverity.critical,
        _Filter.warning => n.severity == NotifSeverity.warning,
        _Filter.success => n.severity == NotifSeverity.success,
      };
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _store = NotificationStore.instance;
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _store,
          builder: (context, _) {
            final visible = _store.items.where(_filter.matches).toList();
            final today = visible.where((n) => isToday(n.createdAt)).toList();
            final earlier =
                visible.where((n) => !isToday(n.createdAt)).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(children: [
                    const RoundBackButton(),
                    const SizedBox(width: 12),
                    Text('Notifications', style: AppTheme.heading(20)),
                    const Spacer(),
                    GestureDetector(
                      onTap: _store.markAllRead,
                      child: const Tooltip(
                        message: 'Mark all as read',
                        child: Icon(Icons.done_all,
                            size: 20, color: AppColors.terracottaDark),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _Filter.values.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => _chip(_Filter.values[i]),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: visible.isEmpty
                      ? _emptyState()
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          children: [
                            if (today.isNotEmpty) _group('TODAY', today),
                            if (earlier.isNotEmpty) _group('EARLIER', earlier),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
      // If your app shell already owns the bottom nav, remove this.
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.terracotta,
        unselectedItemColor: AppColors.textFaint,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 0,
        onTap: (_) => Navigator.pop(context),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.savings_outlined), label: 'Goals'),
          BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none), label: 'Alerts'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Account'),
        ],
      ),
    );
  }

  Widget _emptyState() {
    // Nothing at all vs. nothing matching the selected filter.
    if (_store.items.isEmpty || _filter == _Filter.all) {
      return const NotificationEmptyState();
    }
    return switch (_filter) {
      _Filter.unread => const NotificationEmptyState(
          title: 'No unread notifications',
          message: "You're all caught up!"),
      _Filter.critical => const NotificationEmptyState(
          title: 'No critical alerts',
          message: 'Nothing needs urgent attention right now.'),
      _Filter.warning => const NotificationEmptyState(
          title: 'No warnings',
          message: 'You have no spending warnings at the moment.'),
      _Filter.success => const NotificationEmptyState(
          title: 'No success messages yet',
          message: 'Reached goals and budget resets will show up here.'),
      _Filter.all => const NotificationEmptyState(),
    };
  }

  Widget _chip(_Filter f) {
    final selected = _filter == f;
    return GestureDetector(
      onTap: () => setState(() => _filter = f),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.terracotta : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? AppColors.terracotta : AppColors.border),
        ),
        child: Text(f.label,
            style: AppTheme.body(12,
                weight: FontWeight.w800,
                color: selected ? Colors.white : AppColors.text)),
      ),
    );
  }

  Widget _group(String title, List<AppNotification> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTheme.body(11,
                  weight: FontWeight.w800, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: [
              for (final n in items)
                NotificationTile(
                  n: n,
                  showActions: true,
                  onTap: () => _store.markRead(n.id),
                  onMarkRead: () => _store.markRead(n.id),
                  onDelete: () => _store.delete(n.id),
                ),
            ]),
          ),
        ],
      ),
    );
  }
}