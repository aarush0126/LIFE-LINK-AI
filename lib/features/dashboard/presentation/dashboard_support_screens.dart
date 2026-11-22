import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_stat_card.dart';
import '../../../core/widgets/glass_card.dart';
import '../../authentication/application/auth_controller.dart';
import '../../authentication/domain/role_access_policy.dart';
import '../../blood_bank/data/synthetic_blood_bank_data.dart';
import '../data/synthetic_dashboard_data.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).currentUser;
    if (user == null) return const SizedBox.shrink();
    final canViewBlood = RoleAccessPolicy.canAccess(
      user.role,
      RouteNames.bloodBank,
    );
    final canViewIcu = RoleAccessPolicy.canAccess(
      user.role,
      RouteNames.icuBeds,
    );
    final canViewEquipment = RoleAccessPolicy.canAccess(
      user.role,
      RouteNames.equipment,
    );
    final canViewOrgan = RoleAccessPolicy.canAccess(
      user.role,
      RouteNames.organCoordination,
    );
    final requests = SyntheticDashboardData.requests.where(
      (request) =>
          canViewOrgan ||
          !request.resourceCategory.toLowerCase().contains('organ'),
    );
    final activeRequests = requests.where((request) => request.status.isActive);
    final pendingVerification = requests.where(
      (request) =>
          request.verification == DemoVerificationStatus.awaitingConfirmation,
    );
    final resources = SyntheticDashboardData.resources.where((resource) {
      return switch (resource.category) {
        DemoResourceCategory.blood => canViewBlood,
        DemoResourceCategory.icu => canViewIcu,
        DemoResourceCategory.equipment => canViewEquipment,
      };
    }).toList();
    final resourceCount = resources.fold<int>(
      0,
      (sum, resource) => sum + resource.listedQuantity,
    );

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(context.isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reports',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Illustrative summary generated from the same synthetic dashboard dataset.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 18),
            const _DemoDataNotice(),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 900
                    ? 3
                    : constraints.maxWidth > 560
                    ? 2
                    : 1;
                return GridView.count(
                  crossAxisCount: columns,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: columns == 1 ? 2.3 : 1.8,
                  children: [
                    AppStatCard(
                      title: 'Coordination activity',
                      value: '${requests.length}',
                      subtitle: 'Synthetic request records',
                      icon: Icons.assignment_outlined,
                    ),
                    AppStatCard(
                      title: 'Active demo workflows',
                      value: '${activeRequests.length}',
                      subtitle: 'Not live operational requests',
                      icon: Icons.sync_alt_rounded,
                      accentColor: AppColors.accentSecondary,
                    ),
                    AppStatCard(
                      title: 'Listed resource units',
                      value: '$resourceCount',
                      subtitle: 'Reported sample totals only',
                      icon: Icons.inventory_2_outlined,
                      accentColor: AppColors.warning,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            _ReportSection(
              icon: Icons.sync_alt_rounded,
              title: 'Coordination activity',
              subtitle: 'Synthetic workflow counts by status.',
              labels: const ['Verify', 'Active', 'Confirmed', 'Closed'],
              values: [
                requests
                    .where(
                      (request) =>
                          request.status ==
                          DemoRequestStatus.awaitingVerification,
                    )
                    .length,
                requests
                    .where(
                      (request) =>
                          request.status == DemoRequestStatus.coordinating,
                    )
                    .length,
                requests
                    .where(
                      (request) =>
                          request.status ==
                          DemoRequestStatus.institutionConfirmed,
                    )
                    .length,
                requests
                    .where(
                      (request) => request.status == DemoRequestStatus.closed,
                    )
                    .length,
              ],
              color: AppColors.accentPrimary,
            ),
            const SizedBox(height: 12),
            _ReportSection(
              icon: Icons.manage_search_rounded,
              title: 'Resource discovery activity',
              subtitle: 'Synthetic listings grouped by resource area.',
              labels: [
                if (canViewBlood) 'Blood',
                if (canViewIcu) 'ICU',
                if (canViewEquipment) 'Equipment',
              ],
              values: [
                if (canViewBlood)
                  resources
                      .where(
                        (resource) =>
                            resource.category == DemoResourceCategory.blood,
                      )
                      .length,
                if (canViewIcu)
                  resources
                      .where(
                        (resource) =>
                            resource.category == DemoResourceCategory.icu,
                      )
                      .length,
                if (canViewEquipment)
                  resources
                      .where(
                        (resource) =>
                            resource.category == DemoResourceCategory.equipment,
                      )
                      .length,
              ],
              color: AppColors.accentSecondary,
            ),
            if (canViewBlood) ...[
              const SizedBox(height: 12),
              _ReportSection(
                icon: Icons.water_drop_outlined,
                title: 'Blood bank status summary',
                subtitle: 'Synthetic inventory records by reporting/verification state.',
                labels: DemoBloodVerification.values
                    .map((status) => status.label)
                    .toList(),
                values: DemoBloodVerification.values
                    .map(
                      (status) => SyntheticBloodBankData.inventory
                          .where((item) => item.verification == status)
                          .length,
                    )
                    .toList(),
                color: AppColors.bloodRed,
              ),
            ],
            if (canViewIcu) ...[
              const SizedBox(height: 12),
              _ReportSection(
                icon: Icons.hotel_outlined,
                title: 'ICU capacity trend',
                subtitle: 'Illustrative synthetic weekly indicators; not confirmed beds.',
                labels: const ['W1', 'W2', 'W3', 'W4', 'W5', 'W6'],
                values: const [18, 20, 19, 23, 21, 24],
                color: AppColors.icuBlue,
              ),
            ],
            if (canViewEquipment) ...[
              const SizedBox(height: 12),
              _ReportSection(
                icon: Icons.precision_manufacturing_outlined,
                title: 'Equipment availability trend',
                subtitle: 'Illustrative synthetic reported listings by week.',
                labels: const ['W1', 'W2', 'W3', 'W4', 'W5', 'W6'],
                values: const [26, 25, 28, 30, 29, 33],
                color: AppColors.equipmentAmber,
              ),
            ],
            if (RoleAccessPolicy.canAccess(
              user.role,
              RouteNames.aiAssistant,
            )) ...[
              const SizedBox(height: 12),
              _ReportSection(
                icon: Icons.auto_awesome_outlined,
                title: 'AI search activity',
                subtitle: 'Synthetic example-query volume; no personal query content is stored.',
                labels: const ['W1', 'W2', 'W3', 'W4', 'W5', 'W6'],
                values: const [14, 18, 16, 23, 21, 27],
                color: AppColors.aiPurple,
              ),
            ],
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$pendingVerification synthetic request(s) are marked as awaiting institution confirmation.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppButton(
                    label: 'Return to overview',
                    icon: Icons.dashboard_outlined,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => context.go(RouteNames.dashboard),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  const _ReportSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.labels,
    required this.values,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> labels;
  final List<int> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.isEmpty
        ? 1
        : values
              .reduce((left, right) => left > right ? left : right)
              .clamp(1, 1000000);
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: color),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          if (labels.isEmpty)
            const Text(
              'No report categories are available for this role.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            )
          else
            SizedBox(
              height: 118,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(labels.length, (index) {
                  final value = values[index];
                  final barHeight = (72 * value / maxValue)
                      .clamp(5.0, 72.0)
                      .toDouble();
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '$value',
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: color.withAlpha(145),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            labels[index],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(context.isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Workspace configuration and account controls.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 18),
            const _DemoDataNotice(),
            const SizedBox(height: 18),
            _SettingsTile(
              icon: Icons.palette_outlined,
              title: 'Appearance',
              detail: 'Premium dark theme',
              status: 'Active',
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.verified_user_outlined,
              title: 'Authentication',
              detail: 'Demo sign-in is in-memory. Production authentication is not configured.',
              status: 'Demo mode',
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Data handling',
              detail: 'No live hospital systems are connected. Verify information through authorized institutional pathways.',
              status: 'Synthetic data',
            ),
            const SizedBox(height: 18),
            AppButton(
              label: 'Open user profile',
              icon: Icons.person_outline_rounded,
              variant: AppButtonVariant.secondary,
              onPressed: () => context.go(RouteNames.profile),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoDataNotice extends StatelessWidget {
  const _DemoDataNotice();

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
              'Synthetic demonstration data only. Figures are illustrative and do not represent confirmed resource availability, allocations, or healthcare outcomes.',
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

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final String status;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.detail,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentPrimary, size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            status,
            style: const TextStyle(
              color: AppColors.accentPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
