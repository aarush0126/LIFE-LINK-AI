import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../constants/app_constants.dart';
import '../../features/authentication/application/auth_controller.dart';
import '../../features/authentication/application/auth_session_actions.dart';
import '../../features/dashboard/data/synthetic_dashboard_data.dart';
import '../../shared/models/user_model.dart';
import '../routing/route_names.dart';
import '../theme/app_colors.dart';
import '../utils/responsive_utils.dart';
import 'app_status_badge.dart';

class AppTopBar extends ConsumerWidget implements PreferredSizeWidget {
  final String currentRoute;
  final VoidCallback? onMenuPressed;

  const AppTopBar({super.key, required this.currentRoute, this.onMenuPressed});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  String _getRouteTitle() {
    if (currentRoute.startsWith(RouteNames.dashboard)) {
      return 'Hospital coordination overview';
    }
    if (currentRoute.startsWith(RouteNames.hospitals)) {
      return 'Hospital Network';
    }
    if (currentRoute.startsWith(RouteNames.organCoordination)) {
      return 'Organ & Tissue Coordination';
    }
    if (currentRoute.startsWith(RouteNames.bloodBank)) {
      return 'Blood Bank';
    }
    if (currentRoute.startsWith(RouteNames.icuBeds)) {
      return 'ICU & Emergency Beds';
    }
    if (currentRoute.startsWith(RouteNames.equipment)) {
      return 'Medical Equipment';
    }
    if (currentRoute.startsWith(RouteNames.aiAssistant)) {
      return 'AI Assistant';
    }
    if (currentRoute.startsWith(RouteNames.notifications)) {
      return 'Notifications';
    }
    if (currentRoute.startsWith(RouteNames.profile)) {
      return 'User Profile';
    }
    if (currentRoute.startsWith(RouteNames.admin)) {
      return 'Administration';
    }
    if (currentRoute.startsWith(RouteNames.reports)) {
      return 'Reports';
    }
    if (currentRoute.startsWith(RouteNames.settings)) {
      return 'Settings';
    }
    return AppConstants.appName;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = context.isDesktop;
    final isCompact = MediaQuery.sizeOf(context).width < 400;
    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm').format(now);
    final user = ref.watch(authControllerProvider).currentUser;
    final pendingNotifications = SyntheticDashboardData.requests
        .where(
          (request) => request.status == DemoRequestStatus.awaitingVerification,
        )
        .length;
    final recentRequests = SyntheticDashboardData.requests.take(3).toList();
    final initials = user?.fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 20),
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (!isDesktop) ...[
            IconButton(
              icon: const Icon(
                Icons.menu_rounded,
                color: AppColors.textPrimary,
              ),
              onPressed: onMenuPressed,
            ),
            const SizedBox(width: 8),
          ],

          // Breadcrumb Title
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    _getRouteTitle(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isDesktop) ...[
                  const SizedBox(width: 12),
                  const AppStatusBadge(
                    label: 'SYNTHETIC DEMO',
                    variant: StatusBadgeVariant.warning,
                  ),
                ],
              ],
            ),
          ),

          // Right Action Cluster
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<String>(
                tooltip: 'Recent synthetic notifications',
                onSelected: (_) => context.go(RouteNames.notifications),
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    enabled: false,
                    height: 36,
                    child: Text(
                      'RECENT SYNTHETIC EVENTS',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  ...recentRequests.map(
                    (request) => PopupMenuItem<String>(
                      enabled: false,
                      child: SizedBox(
                        width: 240,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.requestId,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${request.resourceCategory} · ${request.status.label}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'all',
                    child: SizedBox(
                      width: 220,
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications_active_outlined,
                            size: 16,
                            color: AppColors.accentPrimary,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'View notifications',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Badge(
                    label: Text('$pendingNotifications'),
                    backgroundColor: AppColors.accentSecondary,
                    textColor: Colors.white,
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: isCompact ? 0 : 8),

              // Live Time Clock (on desktop)
              if (isDesktop) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: AppColors.accentSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],

              PopupMenuButton<String>(
                tooltip: 'User profile menu',
                onSelected: (value) async {
                  if (value == 'profile') {
                    context.go(RouteNames.profile);
                  } else if (value == 'settings') {
                    context.go(RouteNames.settings);
                  } else if (value == 'signOut') {
                    await signOutAndNavigate(context, ref);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'No active session',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (user != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            user.role.label,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'profile',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.person_outline_rounded),
                      title: Text('Profile'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'settings',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.settings_outlined),
                      title: Text('Settings'),
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'signOut',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.logout_rounded),
                      title: Text('Sign out'),
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accentPrimary.withAlpha(120),
                      width: 1.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.accentPrimary.withAlpha(35),
                    child: Text(
                      initials ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
