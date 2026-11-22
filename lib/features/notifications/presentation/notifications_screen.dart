import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_notification_card.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../features/authentication/application/auth_controller.dart';
import '../application/notification_controller.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _searchController = TextEditingController();
  DemoNotificationCategory? _category;
  bool _unreadOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).currentUser;
    final controller = ref.watch(demoNotificationsControllerProvider);
    if (user == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final allNotifications = controller.forRole(user.role);
        final query = _searchController.text.trim().toLowerCase();
        final notifications = allNotifications.where((notification) {
          final matchesCategory =
              _category == null || notification.category == _category;
          final matchesRead = !_unreadOnly || notification.isUnread;
          final matchesQuery =
              query.isEmpty ||
              notification.title.toLowerCase().contains(query) ||
              notification.message.toLowerCase().contains(query) ||
              notification.category.label.toLowerCase().contains(query);
          return matchesCategory && matchesRead && matchesQuery;
        }).toList()..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
        final unreadCount = allNotifications
            .where((notification) => notification.isUnread)
            .length;

        return Scaffold(
          backgroundColor: AppColors.bgPrimary,
          body: SingleChildScrollView(
            padding: EdgeInsets.all(context.isDesktop ? 24 : 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Review role-scoped synthetic coordination activity.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _SyntheticNotice(),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _CountPill(
                          label: '$unreadCount unread',
                          color: unreadCount == 0
                              ? AppColors.textSecondary
                              : AppColors.accentPrimary,
                        ),
                        AppButton(
                          label: 'Mark all read',
                          icon: Icons.done_all_rounded,
                          size: AppButtonSize.small,
                          variant: AppButtonVariant.secondary,
                          onPressed: unreadCount == 0
                              ? null
                              : () => controller.markAllRead(user.role),
                        ),
                        FilterChip(
                          label: const Text('Unread only'),
                          selected: _unreadOnly,
                          onSelected: (value) =>
                              setState(() => _unreadOnly = value),
                          selectedColor: AppColors.accentPrimary.withAlpha(35),
                          checkmarkColor: AppColors.accentPrimary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final search = TextField(
                          key: const Key('notifications-search'),
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Search notifications',
                            prefixIcon: Icon(Icons.search_rounded),
                            border: OutlineInputBorder(),
                          ),
                        );
                        final category =
                            DropdownButtonFormField<DemoNotificationCategory?>(
                              key: const Key('notifications-category-filter'),
                              initialValue: _category,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('All categories'),
                                ),
                                ...DemoNotificationCategory.values.map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value.label),
                                  ),
                                ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _category = value),
                            );

                        if (constraints.maxWidth > 640) {
                          return Row(
                            children: [
                              Expanded(flex: 3, child: search),
                              const SizedBox(width: 12),
                              Expanded(flex: 2, child: category),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            search,
                            const SizedBox(height: 10),
                            category,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Showing ${notifications.length} of ${allNotifications.length} notifications',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (notifications.isEmpty)
                      const _EmptyNotifications()
                    else
                      ...notifications.map((notification) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 4,
                                  bottom: 5,
                                ),
                                child: Text(
                                  notification.category.label.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.accentSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                              AppNotificationCard(
                                title: notification.title,
                                message: notification.message,
                                timeAgo: DateFormat('MMM d, yyyy · HH:mm')
                                    .format(notification.occurredAt),
                                severity:
                                    notification.category ==
                                        DemoNotificationCategory
                                            .pendingVerification
                                    ? NotificationSeverity.urgent
                                    : NotificationSeverity.info,
                                isUnread: notification.isUnread,
                                actionLabel: notification.isUnread
                                    ? 'Mark as read'
                                    : 'Mark as unread',
                                onAction: () => controller.setRead(
                                  notification.id,
                                  isRead: notification.isUnread,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SyntheticNotice extends StatelessWidget {
  const _SyntheticNotice();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.science_outlined, color: AppColors.warning, size: 19),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Synthetic demonstration events only. No live hospital events, patient information, confirmed availability, or real-world allocation decisions are shown.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(28),
      child: const Column(
        children: [
          Icon(
            Icons.notifications_off_outlined,
            color: AppColors.textMuted,
            size: 30,
          ),
          SizedBox(height: 8),
          Text(
            'No notifications match these filters.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
