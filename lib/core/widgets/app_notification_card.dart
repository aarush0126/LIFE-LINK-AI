import 'package:material_ui/material_ui.dart';
import '../theme/app_colors.dart';
import 'app_button.dart';
import 'glass_card.dart';

enum NotificationSeverity {
  emergency,  // Green corridor, code red
  urgent,     // Blood stock low, bed depleted
  info,       // Telemetry synced
  ai,         // AI triage alert
}

class AppNotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final String timeAgo;
  final NotificationSeverity severity;
  final bool isUnread;
  final VoidCallback? onAction;
  final String? actionLabel;
  final VoidCallback? onDismiss;

  const AppNotificationCard({
    super.key,
    required this.title,
    required this.message,
    required this.timeAgo,
    this.severity = NotificationSeverity.info,
    this.isUnread = false,
    this.onAction,
    this.actionLabel,
    this.onDismiss,
  });

  Color _getIconColor() {
    switch (severity) {
      case NotificationSeverity.emergency:
        return AppColors.danger;
      case NotificationSeverity.urgent:
        return AppColors.warning;
      case NotificationSeverity.info:
        return AppColors.accentSecondary;
      case NotificationSeverity.ai:
        return AppColors.aiPurple;
    }
  }

  IconData _getIcon() {
    switch (severity) {
      case NotificationSeverity.emergency:
        return Icons.emergency_rounded;
      case NotificationSeverity.urgent:
        return Icons.warning_amber_rounded;
      case NotificationSeverity.info:
        return Icons.info_outline_rounded;
      case NotificationSeverity.ai:
        return Icons.auto_awesome_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _getIconColor();

    return GlassCard(
      glowAccent: severity == NotificationSeverity.emergency
          ? GlowAccent.danger
          : severity == NotificationSeverity.urgent
              ? GlowAccent.warning
              : GlowAccent.none,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(30),
              shape: BoxShape.circle,
              border: Border.all(color: iconColor.withAlpha(80), width: 1),
            ),
            child: Icon(_getIcon(), color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (isUnread) ...[
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.accentPrimary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 12),
                  AppButton(
                    label: actionLabel!,
                    size: AppButtonSize.small,
                    variant: severity == NotificationSeverity.emergency
                        ? AppButtonVariant.danger
                        : AppButtonVariant.primary,
                    onPressed: onAction,
                  ),
                ],
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
              onPressed: onDismiss,
              tooltip: 'Dismiss alert',
            ),
        ],
      ),
    );
  }
}
