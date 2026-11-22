import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/authentication/application/auth_controller.dart';
import '../../features/authentication/application/auth_session_actions.dart';
import '../../features/authentication/domain/role_access_policy.dart';
import '../../shared/models/user_model.dart';
import '../constants/app_constants.dart';
import '../routing/route_names.dart';
import '../theme/app_colors.dart';
import 'app_status_badge.dart';

class SidebarItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  final int? badgeCount;
  final bool isEmergency;

  const SidebarItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
    this.badgeCount,
    this.isEmergency = false,
  });
}

const List<SidebarItem> sidebarNavigationItems = [
  SidebarItem(
    label: 'Overview',
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard_rounded,
    route: RouteNames.dashboard,
  ),
  SidebarItem(
    label: 'Hospital Network',
    icon: Icons.local_hospital_outlined,
    activeIcon: Icons.local_hospital_rounded,
    route: RouteNames.hospitals,
  ),
  SidebarItem(
    label: 'Organ & Tissue Coordination',
    icon: Icons.favorite_border_rounded,
    activeIcon: Icons.favorite_rounded,
    route: RouteNames.organCoordination,
    isEmergency: true,
  ),
  SidebarItem(
    label: 'Blood Bank',
    icon: Icons.water_drop_outlined,
    activeIcon: Icons.water_drop_rounded,
    route: RouteNames.bloodBank,
  ),
  SidebarItem(
    label: 'ICU & Emergency Beds',
    icon: Icons.hotel_outlined,
    activeIcon: Icons.hotel_rounded,
    route: RouteNames.icuBeds,
  ),
  SidebarItem(
    label: 'Medical Equipment',
    icon: Icons.precision_manufacturing_outlined,
    activeIcon: Icons.precision_manufacturing_rounded,
    route: RouteNames.equipment,
  ),
  SidebarItem(
    label: 'AI Assistant',
    icon: Icons.auto_awesome_outlined,
    activeIcon: Icons.auto_awesome_rounded,
    route: RouteNames.aiAssistant,
  ),
  SidebarItem(
    label: 'Notifications',
    icon: Icons.notifications_none_rounded,
    activeIcon: Icons.notifications_rounded,
    route: RouteNames.notifications,
  ),
  SidebarItem(
    label: 'Reports',
    icon: Icons.summarize_outlined,
    activeIcon: Icons.summarize_rounded,
    route: RouteNames.reports,
  ),
  SidebarItem(
    label: 'Settings',
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings_rounded,
    route: RouteNames.settings,
  ),
  SidebarItem(
    label: 'Administration',
    icon: Icons.admin_panel_settings_outlined,
    activeIcon: Icons.admin_panel_settings_rounded,
    route: RouteNames.admin,
  ),
  SidebarItem(
    label: 'Audit Log',
    icon: Icons.fact_check_outlined,
    activeIcon: Icons.fact_check_rounded,
    route: RouteNames.adminAudit,
  ),
];

class AppSidebar extends ConsumerWidget {
  final String currentRoute;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;

  const AppSidebar({
    super.key,
    required this.currentRoute,
    this.isCollapsed = false,
    this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = isCollapsed ? 76.0 : 250.0;
    final user = ref.watch(authControllerProvider).currentUser;
    final permittedRoutes = user == null
        ? const <String>{}
        : RoleAccessPolicy.routesFor(user.role);
    final visibleItems = sidebarNavigationItems
        .where((item) => permittedRoutes.contains(item.route))
        .toList();
    final activeRoute = visibleItems
        .where((item) => currentRoute.startsWith(item.route))
        .fold<String?>(
          null,
          (bestMatch, item) =>
              bestMatch == null || item.route.length > bestMatch.length
              ? item.route
              : bestMatch,
        );
    final initials = user?.fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(
          right: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Platform Header Logo
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 14 : 20,
              vertical: 20,
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accentPrimary, Color(0xFF0F8F82)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentPrimary.withAlpha(80),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.health_and_safety_rounded,
                    color: AppColors.bgPrimary,
                    size: 20,
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          AppConstants.appName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'COORDINATION WORKSPACE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: AppColors.accentPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (onToggleCollapse != null)
                  IconButton(
                    tooltip: isCollapsed
                        ? 'Expand sidebar'
                        : 'Collapse sidebar',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 28,
                      height: 28,
                    ),
                    icon: Icon(
                      isCollapsed
                          ? Icons.chevron_right_rounded
                          : Icons.chevron_left_rounded,
                      color: AppColors.textSecondary,
                      size: 19,
                    ),
                    onPressed: onToggleCollapse,
                  ),
              ],
            ),
          ),

          // Grid Status Telemetry Pill (when expanded)
          if (!isCollapsed)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: const [
                  Flexible(
                    child: AppStatusBadge(
                      label: 'DEMO MODE',
                      variant: StatusBadgeVariant.info,
                      isPulsing: false,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'SYNTHETIC DATA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Navigation Links
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              itemCount: visibleItems.length,
              itemBuilder: (context, index) {
                final item = visibleItems[index];
                final isActive = item.route == activeRoute;

                return _SidebarNavTile(
                  item: item,
                  isActive: isActive,
                  isCollapsed: isCollapsed,
                  onTap: () => context.go(item.route),
                );
              },
            ),
          ),

          // Healthcare Officer Bottom Info
          Container(
            padding: EdgeInsets.all(isCollapsed ? 12 : 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: isCollapsed
                ? Center(
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.accentPrimary.withAlpha(30),
                      child: Text(
                        initials ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentPrimary,
                        ),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: AppColors.accentPrimary.withAlpha(30),
                        child: Text(
                          initials ?? '',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              user?.fullName ?? 'No active session',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              user?.role.label ?? '',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.logout_rounded,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                        tooltip: 'Sign out',
                        onPressed: user == null
                            ? null
                            : () async {
                                await signOutAndNavigate(context, ref);
                              },
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavTile extends StatefulWidget {
  final SidebarItem item;
  final bool isActive;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _SidebarNavTile({
    required this.item,
    required this.isActive,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  State<_SidebarNavTile> createState() => _SidebarNavTileState();
}

class _SidebarNavTileState extends State<_SidebarNavTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.item.isEmergency
        ? AppColors.danger
        : AppColors.accentPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCollapsed ? 12 : 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: widget.isActive
                ? activeColor.withAlpha(20)
                : (_isHovered ? AppColors.bgCard : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: widget.isActive
                ? Border(left: BorderSide(color: activeColor, width: 3))
                : null,
          ),
          child: Row(
            mainAxisAlignment: widget.isCollapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                widget.isActive ? widget.item.activeIcon : widget.item.icon,
                size: 19,
                color: widget.isActive
                    ? activeColor
                    : (_isHovered
                          ? AppColors.textPrimary
                          : AppColors.textSecondary),
              ),
              if (!widget.isCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.item.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: widget.isActive
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: widget.isActive
                          ? AppColors.textPrimary
                          : (_isHovered
                                ? AppColors.textPrimary
                                : AppColors.textSecondary),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.item.badgeCount != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: widget.item.isEmergency
                          ? AppColors.danger
                          : AppColors.accentSecondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.item.badgeCount}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
