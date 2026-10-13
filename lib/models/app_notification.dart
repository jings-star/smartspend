import 'package:flutter/foundation.dart';

enum NotifSeverity { critical, warning, success }

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String emoji;
  final NotifSeverity severity;
  final DateTime createdAt;
  final bool read;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.emoji,
    required this.severity,
    required this.createdAt,
    this.read = false,
  });

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        title: title,
        body: body,
        emoji: emoji,
        severity: severity,
        createdAt: createdAt,
        read: read ?? this.read,
      );
}

/// Shared by the Alerts page (bell badge + recent list) and the
/// Notifications page. Replace the sample data / methods with your
/// service / database (e.g. Firestore) when ready.
class NotificationStore extends ChangeNotifier {
  NotificationStore._();
  static final NotificationStore instance = NotificationStore._();

  final List<AppNotification> _items = _sample();

  List<AppNotification> get items {
    final list = [..._items]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }

  int get unreadCount => _items.where((n) => !n.read).length;

  void markRead(String id) {
    final i = _items.indexWhere((n) => n.id == id);
    if (i == -1 || _items[i].read) return;
    _items[i] = _items[i].copyWith(read: true);
    notifyListeners();
  }

  void markAllRead() {
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(read: true);
    }
    notifyListeners();
  }

  void delete(String id) {
    _items.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  static List<AppNotification> _sample() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'n1',
        title: 'Budget limit alert',
        body: 'Food & Dining reached 92% of its RM500 budget.',
        emoji: '⚠️',
        severity: NotifSeverity.critical,
        createdAt: now.subtract(const Duration(minutes: 2)),
      ),
      AppNotification(
        id: 'n2',
        title: 'Spending suggestion',
        body: 'Cut food delivery orders to 2x a week.',
        emoji: '💡',
        severity: NotifSeverity.warning,
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      AppNotification(
        id: 'n3',
        title: 'Goal progress',
        body: "You're 64% of the way to Emergency Fund.",
        emoji: '🎯',
        severity: NotifSeverity.success,
        createdAt: now.subtract(const Duration(hours: 5)),
        read: true,
      ),
      AppNotification(
        id: 'n4',
        title: 'Budget reset',
        body: 'Transport budget renewed for this month.',
        emoji: '✅',
        severity: NotifSeverity.success,
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        read: true,
      ),
    ];
  }
}

/// "2 min ago", "1 hour ago", "Yesterday", "3 days ago"
String timeAgo(DateTime t) {
  final now = DateTime.now();
  final diff = now.difference(t);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';

  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(t.year, t.month, t.day);
  final days = today.difference(day).inDays;
  if (days == 0) {
    final h = diff.inHours;
    return '$h hour${h > 1 ? 's' : ''} ago';
  }
  if (days == 1) return 'Yesterday';
  return '$days days ago';
}

bool isToday(DateTime t) {
  final n = DateTime.now();
  return t.year == n.year && t.month == n.month && t.day == n.day;
}
