import 'package:flutter/material.dart';
import '../models/app_notification.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

const _criticalColor = Color(0xFFB4533F);
const _unreadBg = Color(0xFFEEDDD0);

Color _dotColor(NotifSeverity s) {
  switch (s) {
    case NotifSeverity.critical:
      return _criticalColor;
    case NotifSeverity.warning:
      return AppColors.gold;
    case NotifSeverity.success:
      return AppColors.sage;
  }
}

Color _iconBg(NotifSeverity s) {
  switch (s) {
    case NotifSeverity.critical:
      return const Color(0xFFF3DAD3);
    case NotifSeverity.warning:
      return const Color(0xFFF5E8C4);
    case NotifSeverity.success:
      return const Color(0xFFDCEBDF);
  }
}

/// One notification row. Unread = tinted with a coloured dot; read = plain.
/// Set [showActions] to show the ✓ (mark read) and 🗑 (delete) buttons.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.n,
    this.showActions = false,
    this.onMarkRead,
    this.onDelete,
    this.onTap,
  });

  final AppNotification n;
  final bool showActions;
  final VoidCallback? onMarkRead;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !n.read;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: unread ? _unreadBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // dot column (always reserved so icons line up)
                SizedBox(
                  width: 10,
                  height: 40,
                  child: unread
                      ? Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _dotColor(n.severity),
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _iconBg(n.severity),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(n.emoji, style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.title,
                          style: AppTheme.body(13,
                              weight: FontWeight.w800,
                              color: unread
                                  ? AppColors.text
                                  : AppColors.textMuted)),
                      const SizedBox(height: 3),
                      Text(n.body,
                          style:
                              AppTheme.body(11, color: AppColors.textMuted)),
                      const SizedBox(height: 8),
                      Text(timeAgo(n.createdAt),
                          style:
                              AppTheme.body(10, color: AppColors.textFaint)),
                    ],
                  ),
                ),
                if (showActions) ...[
                  const SizedBox(width: 6),
                  if (unread)
                    GestureDetector(
                      onTap: onMarkRead,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.check,
                            size: 16, color: AppColors.textFaint),
                      ),
                    ),
                  GestureDetector(
                    onTap: onDelete,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.delete,
                          size: 16, color: AppColors.textFaint),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Friendly message shown when there is nothing to list.
class NotificationEmptyState extends StatelessWidget {
  const NotificationEmptyState({
    super.key,
    this.title = 'No notifications yet',
    this.message =
        "You're all caught up. We'll let you know when something needs your attention.",
    this.compact = false,
  });

  final String title;
  final String message;

  /// Smaller padding for use inside a card (Alerts page).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: 24, vertical: compact ? 24 : 0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.terracotta.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_off_outlined,
                  size: 26, color: AppColors.terracottaDark),
            ),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style: AppTheme.body(14, weight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTheme.body(12, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}