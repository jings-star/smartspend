import 'package:flutter/material.dart';
import '../models/app_notification.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'notification_tile.dart';
import 'notifications_screen.dart';

const _purple = Color(0xFF7B5EA7);
const _thresholds = [50, 70, 80, 90];

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final _store = NotificationStore.instance;

  // TODO: persist the chosen threshold (e.g. in your database / settings).
  int _threshold = 70;

  void _openNotifications() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      );

  void _askAi() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Why did I get this?', style: AppTheme.heading(18)),
              const SizedBox(height: 10),
              // TODO: replace with a real AI answer built from the user's data.
              Text(
                'Your Food & Dining spending is at 92% of your RM500 monthly '
                'budget, which is above your alert level of $_threshold%. '
                'Most of it comes from frequent food delivery orders. '
                'Cutting delivery to about 2 times a week could keep you '
                'within budget for the rest of the month.',
                style: AppTheme.body(13, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _store,
          builder: (context, _) {
            final recent = _store.items.take(3).toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Alerts', style: AppTheme.heading(28)),
                          const SizedBox(height: 4),
                          Text('Get notified before you overspend.',
                              style: AppTheme.body(12,
                                  color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    _bell(_store.unreadCount),
                  ],
                ),
                const SizedBox(height: 18),
                _recommendationCard(),
                const SizedBox(height: 22),
                _sectionLabel('ALERT ME AT'),
                const SizedBox(height: 10),
                Row(children: [
                  for (var i = 0; i < _thresholds.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(child: _thresholdChip(_thresholds[i])),
                  ],
                ]),
                const SizedBox(height: 10),
                Text.rich(TextSpan(
                  style: AppTheme.body(11, color: AppColors.textMuted),
                  children: [
                    const TextSpan(
                        text: "You'll be alerted when a category reaches "),
                    TextSpan(
                        text: '$_threshold%',
                        style: AppTheme.body(11,
                            weight: FontWeight.w800,
                            color: AppColors.terracottaDark)),
                    const TextSpan(text: ' of its budget.'),
                  ],
                )),
                const SizedBox(height: 22),
                _sectionLabel('RECENT NOTIFICATIONS'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: recent.isEmpty
                      ? const NotificationEmptyState(compact: true)
                      : Column(children: [
                          for (final n in recent)
                            NotificationTile(
                              n: n,
                              onTap: () => _store.markRead(n.id),
                            ),
                        ]),
                ),
                const SizedBox(height: 14),
                if (recent.isNotEmpty)
                Center(
                  child: TextButton(
                    onPressed: _openNotifications,
                    child: Text('See all notifications →',
                        style: AppTheme.body(12,
                            weight: FontWeight.w800,
                            color: AppColors.terracottaDark)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _bell(int unread) {
    return GestureDetector(
      onTap: _openNotifications,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.notifications,
                  size: 20, color: AppColors.text),
            ),
            if (unread > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB4533F),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.background, width: 1.5),
                  ),
                  child: Text('$unread',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _recommendationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E9CC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8D6A8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.star, size: 13, color: AppColors.gold),
            const SizedBox(width: 6),
            Text('SMART RECOMMENDATION',
                style: AppTheme.body(10,
                    weight: FontWeight.w800, color: AppColors.gold)),
          ]),
          const SizedBox(height: 10),
          Text('🍜  Cut back on Food & Dining',
              style: AppTheme.body(14, weight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            "You've spent more on Food this month than usual. Ask the "
            'assistant why, and what could help.',
            style: AppTheme.body(12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _askAi,
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: Text('Ask AI: Why did I get this?',
                style: AppTheme.body(12,
                    weight: FontWeight.w800, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String s) => Text(s,
      style: AppTheme.body(11,
          weight: FontWeight.w800, color: AppColors.textMuted));

  Widget _thresholdChip(int v) {
    final selected = _threshold == v;
    return GestureDetector(
      onTap: () => setState(() => _threshold = v),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.terracotta : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? AppColors.terracotta : AppColors.border),
        ),
        child: Text('$v%',
            style: AppTheme.body(13,
                weight: FontWeight.w800,
                color: selected ? Colors.white : AppColors.text)),
      ),
    );
  }
}