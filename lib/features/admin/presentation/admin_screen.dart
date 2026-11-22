import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_data_table.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../shared/models/user_model.dart';
import '../../authentication/application/auth_controller.dart';
import '../../authentication/domain/role_access_policy.dart';
import '../application/admin_demo_controller.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key, this.auditOnly = false});

  final bool auditOnly;

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  static const _allSections = [
    'Verification',
    'Users',
    'Roles & permissions',
    'Institutions',
    'Audit log',
    'System health',
    'Demo data',
  ];

  final _auditSearchController = TextEditingController();

  @override
  void dispose() {
    _auditSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).currentUser;
    final controller = ref.watch(adminDemoControllerProvider);
    if (user == null) return const SizedBox.shrink();

    final isNetworkAdmin = user.role == UserRole.networkAdministrator;
    final canReviewAudit =
        isNetworkAdmin || user.role == UserRole.auditorComplianceOfficer;
    final sections = widget.auditOnly ? const ['Audit log'] : _allSections;
    if ((!isNetworkAdmin && !widget.auditOnly) ||
        (!isNetworkAdmin && !canReviewAudit)) {
      return _AccessDenied(
        message:
            'This administration workspace is restricted to authorized roles.',
        onReturn: () => context.go(RouteNames.dashboard),
      );
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => DefaultTabController(
        length: sections.length,
        child: Scaffold(
          backgroundColor: AppColors.bgPrimary,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  context.isDesktop ? 24 : 16,
                  context.isDesktop ? 22 : 16,
                  context.isDesktop ? 24 : 16,
                  12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.auditOnly ? 'Audit log viewer' : 'Administration',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.auditOnly
                          ? 'Read-only synthetic audit events. Sensitive coordination details are excluded.'
                          : 'Manage fictional network records with least-privilege demo controls.',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _AdministrationNotice(),
                  ],
                ),
              ),
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.accentPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.accentPrimary,
                tabs: sections.map((title) => Tab(text: title)).toList(),
              ),
              Expanded(
                child: TabBarView(
                  children: widget.auditOnly
                      ? [
                          _AuditLogSection(
                            controller: controller,
                            searchController: _auditSearchController,
                            readOnly: true,
                          ),
                        ]
                      : [
                          _VerificationSection(
                            controller: controller,
                            actor: user,
                          ),
                          _UsersSection(controller: controller, actor: user),
                          const _RolesSection(),
                          _InstitutionsSection(
                            controller: controller,
                            actor: user,
                          ),
                          _AuditLogSection(
                            controller: controller,
                            searchController: _auditSearchController,
                          ),
                          const _SystemHealthSection(),
                          _DemoDataSection(controller: controller, actor: user),
                        ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdministrationNotice extends StatelessWidget {
  const _AdministrationNotice();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.science_outlined, color: AppColors.warning, size: 18),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'DEMO ADMINISTRATION ONLY. Changes remain in local in-memory sample records and are not authoritative access controls, hospital verification, or production audit retention.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied({required this.message, required this.onReturn});

  final String message;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.warning,
                  size: 28,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Return to overview',
                  onPressed: onReturn,
                  variant: AppButtonVariant.secondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  const _SectionBody({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.isDesktop ? 24 : 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _VerificationSection extends StatelessWidget {
  const _VerificationSection({required this.controller, required this.actor});

  final AdminDemoController controller;
  final UserModel actor;

  @override
  Widget build(BuildContext context) {
    final pending = controller.institutions
        .where((institution) => institution.verification != 'Demo-verified')
        .toList();
    return _SectionBody(
      children: [
        _SectionHeading(
          title: 'Hospital verification queue',
          detail:
              '${pending.length} synthetic institution record(s) need review. Demo verification is not a real-world credential.',
        ),
        const SizedBox(height: 14),
        if (pending.isEmpty)
          const _EmptySection(
            message: 'No synthetic institutions are pending review.',
          )
        else
          ...pending.map((institution) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final details = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          institution.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${institution.id} · ${institution.location}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Reported status: ${institution.verification}',
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    );
                    final action = AppButton(
                      label: 'Mark demo-verified',
                      icon: Icons.verified_outlined,
                      size: AppButtonSize.small,
                      variant: AppButtonVariant.secondary,
                      onPressed: () => _performAdminAction(
                        context,
                        () => controller.updateVerification(
                          actorRole: actor.role,
                          actorId: actor.id,
                          institutionId: institution.id,
                          verified: true,
                        ),
                      ),
                    );
                    return constraints.maxWidth > 640
                        ? Row(
                            children: [
                              Expanded(child: details),
                              const SizedBox(width: 12),
                              action,
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              details,
                              const SizedBox(height: 12),
                              action,
                            ],
                          );
                  },
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _UsersSection extends StatelessWidget {
  const _UsersSection({required this.controller, required this.actor});

  final AdminDemoController controller;
  final UserModel actor;

  @override
  Widget build(BuildContext context) {
    return _SectionBody(
      children: [
        const _SectionHeading(
          title: 'Demo user management',
          detail: 'Fictional accounts only. Privileged roles cannot be assigned or edited here; your own role is locked.',
        ),
        const SizedBox(height: 14),
        ...controller.users.map((user) {
          final isPrivileged =
              user.role == UserRole.networkAdministrator ||
              user.role == UserRole.auditorComplianceOfficer;
          final isCurrent = user.id == actor.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: AppColors.accentPrimary.withAlpha(25),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          size: 17,
                          color: AppColors.accentPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${user.email} · ${user.institution}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppStatusBadge(
                        label: user.isActive ? 'DEMO ACTIVE' : 'DEMO PAUSED',
                        variant: user.isActive
                            ? StatusBadgeVariant.active
                            : StatusBadgeVariant.warning,
                        isPulsing: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _InfoChip(label: user.role.label),
                      if (isCurrent)
                        const _InfoChip(label: 'Current account · locked'),
                      if (isPrivileged)
                        const _InfoChip(label: 'Privileged · protected'),
                      if (!isPrivileged && !isCurrent) ...[
                        OutlinedButton.icon(
                          key: Key('admin-change-role-${user.id}'),
                          onPressed: () =>
                              _showRoleDialog(context, controller, actor, user),
                          icon: const Icon(Icons.manage_accounts_outlined),
                          label: const Text('Change role'),
                        ),
                        TextButton.icon(
                          onPressed: () => _performAdminAction(
                            context,
                            () => controller.setUserActive(
                              actorRole: actor.role,
                              actorId: actor.id,
                              userId: user.id,
                              active: !user.isActive,
                            ),
                          ),
                          icon: Icon(
                            user.isActive
                                ? Icons.pause_circle_outline
                                : Icons.play_circle_outline,
                          ),
                          label: Text(
                            user.isActive
                                ? 'Pause demo user'
                                : 'Enable demo user',
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

Future<void> _showRoleDialog(
  BuildContext context,
  AdminDemoController controller,
  UserModel actor,
  AdminDemoUserRecord user,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.bgSecondary,
      title: const Text('Assign a demo role'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: AdminDemoController.assignableRoles
            .map(
              (role) => ListTile(
                title: Text(role.label),
                trailing: user.role == role
                    ? const Icon(
                        Icons.check_circle,
                        color: AppColors.accentPrimary,
                      )
                    : null,
                onTap: () {
                  Navigator.of(context).pop();
                  _performAdminAction(
                    context,
                    () => controller.updateUserRole(
                      actorRole: actor.role,
                      actorId: actor.id,
                      userId: user.id,
                      newRole: role,
                    ),
                  );
                },
              ),
            )
            .toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}

class _RolesSection extends StatelessWidget {
  const _RolesSection();

  @override
  Widget build(BuildContext context) {
    return _SectionBody(
      children: [
        const _SectionHeading(
          title: 'Role & permission matrix',
          detail: 'Default route permissions are read-only in this demo. Permission changes require an authenticated backend policy; privileged roles are never self-assigned.',
        ),
        const SizedBox(height: 14),
        ...UserRole.values.map((role) {
          final routes =
              RoleAccessPolicy.routesFor(role)
                  .where((route) => route != RouteNames.profile)
                  .map(adminRouteLabel)
                  .toList()
                ..sort();
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          role.label,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const _InfoChip(label: 'Default policy'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: routes
                        .map((route) => _InfoChip(label: route))
                        .toList(),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _InstitutionsSection extends StatelessWidget {
  const _InstitutionsSection({required this.controller, required this.actor});

  final AdminDemoController controller;
  final UserModel actor;

  @override
  Widget build(BuildContext context) {
    return _SectionBody(
      children: [
        Row(
          children: [
            const Expanded(
              child: _SectionHeading(
                title: 'Institution directory',
                detail: 'Fictional institutions and capability labels only. No private coordinator contact details are stored here.',
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: 'Add synthetic institution',
              onPressed: () =>
                  _showAddInstitutionDialog(context, controller, actor),
              icon: const Icon(Icons.add_business_outlined),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...controller.institutions.map((institution) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.local_hospital_outlined,
                        color: AppColors.accentPrimary,
                        size: 19,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          institution.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      AppStatusBadge(
                        label: institution.isEnabled
                            ? 'DEMO ENABLED'
                            : 'DEMO PAUSED',
                        variant: institution.isEnabled
                            ? StatusBadgeVariant.active
                            : StatusBadgeVariant.warning,
                        isPulsing: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${institution.id} · ${institution.location} · ${institution.type}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Verification: ${institution.verification}',
                    style: TextStyle(
                      color: institution.verification == 'Demo-verified'
                          ? AppColors.success
                          : AppColors.warning,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: institution.modules
                        .map((module) => _InfoChip(label: module))
                        .toList(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _performAdminAction(
                        context,
                        () => controller.setInstitutionEnabled(
                          actorRole: actor.role,
                          actorId: actor.id,
                          institutionId: institution.id,
                          enabled: !institution.isEnabled,
                        ),
                      ),
                      icon: Icon(
                        institution.isEnabled
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline,
                      ),
                      label: Text(
                        institution.isEnabled
                            ? 'Pause demo listing'
                            : 'Enable demo listing',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

Future<void> _showAddInstitutionDialog(
  BuildContext context,
  AdminDemoController controller,
  UserModel actor,
) async {
  final nameController = TextEditingController();
  final locationController = TextEditingController();
  try {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: const Text('Add synthetic institution'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Demo institution name',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Illustrative city / state',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context)
                    .pop((nameController.text, locationController.text)),
            child: const Text('Add demo record'),
          ),
        ],
      ),
    );
    if (result != null && context.mounted) {
      _performAdminAction(
        context,
        () => controller.addInstitution(
          actorRole: actor.role,
          actorId: actor.id,
          name: result.$1,
          location: result.$2,
        ),
      );
    }
  } finally {
    nameController.dispose();
    locationController.dispose();
  }
}

class _AuditLogSection extends StatefulWidget {
  const _AuditLogSection({
    required this.controller,
    required this.searchController,
    this.readOnly = false,
  });

  final AdminDemoController controller;
  final TextEditingController searchController;
  final bool readOnly;

  @override
  State<_AuditLogSection> createState() => _AuditLogSectionState();
}

class _AuditLogSectionState extends State<_AuditLogSection> {
  @override
  Widget build(BuildContext context) {
    final query = widget.searchController.text.trim().toLowerCase();
    final entries = widget.controller.auditEntries.where((entry) {
      return query.isEmpty ||
          entry.actor.toLowerCase().contains(query) ||
          entry.action.toLowerCase().contains(query) ||
          entry.subject.toLowerCase().contains(query);
    }).toList();

    return _SectionBody(
      children: [
        _SectionHeading(
          title: widget.readOnly
              ? 'Read-only audit events'
              : 'Audit log viewer',
          detail: 'Session-local synthetic events. This prototype does not provide tamper-proof or durable audit retention.',
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('admin-audit-search'),
          controller: widget.searchController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Search audit entries',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 12),
        AppDataTable(
          columns: const [
            AppTableColumn(title: 'Timestamp', width: 155),
            AppTableColumn(title: 'Actor', width: 190),
            AppTableColumn(title: 'Action', width: 240),
            AppTableColumn(title: 'Record reference', width: 200),
          ],
          rows: entries
              .map(
                (entry) => AppTableRow(
                  cells: [
                    Text(
                      DateFormat('MMM d, HH:mm:ss').format(entry.occurredAt),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      entry.actor,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      entry.action,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      entry.subject,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
          totalRecords: entries.length,
          emptyMessage: 'No audit events match the current search.',
        ),
      ],
    );
  }
}

class _SystemHealthSection extends StatelessWidget {
  const _SystemHealthSection();

  @override
  Widget build(BuildContext context) {
    const components = [
      (
        'Application',
        'Demo UI available',
        'Local prototype only; not production service monitoring.',
        Icons.web_asset_outlined,
      ),
      (
        'Authentication',
        'Demo sign-in only',
        'Role session is held in memory; no production identity provider.',
        Icons.lock_outline,
      ),
      (
        'Hospital integrations',
        'Not connected',
        'No live hospital, blood-bank, or transfer system connection.',
        Icons.sync_disabled_rounded,
      ),
      (
        'Audit retention',
        'Session-local',
        'Sample audit actions are not durably stored or tamper-proof.',
        Icons.fact_check_outlined,
      ),
      (
        'Dataset',
        'Synthetic fixtures',
        'Resource reports are illustrative and require independent confirmation.',
        Icons.science_outlined,
      ),
    ];
    return _SectionBody(
      children: [
        const _SectionHeading(
          title: 'System health (demo environment)',
          detail: 'These are configuration disclosures, not live uptime, security, or infrastructure measurements.',
        ),
        const SizedBox(height: 14),
        ...components.map(
          (component) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    component.$4,
                    color: AppColors.accentSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          component.$1,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          component.$3,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _InfoChip(label: component.$2),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DemoDataSection extends StatelessWidget {
  const _DemoDataSection({required this.controller, required this.actor});

  final AdminDemoController controller;
  final UserModel actor;

  @override
  Widget build(BuildContext context) {
    return _SectionBody(
      children: [
        const _SectionHeading(
          title: 'Demo data management',
          detail: 'Reset affects only this session’s simulated institution records and user assignments. It does not erase app fixtures or production data.',
        ),
        const SizedBox(height: 14),
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${controller.institutions.length} demo institutions · ${controller.users.length} fictional demo accounts',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Verification and role changes are session-local and recorded in the local demo audit view.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Reset admin demo records',
                icon: Icons.restart_alt_rounded,
                variant: AppButtonVariant.danger,
                onPressed: () => _confirmReset(context, controller, actor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> _confirmReset(
  BuildContext context,
  AdminDemoController controller,
  UserModel actor,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.bgSecondary,
      title: const Text('Reset demo administration records?'),
      content: const Text(
        'This restores the sample hospital verification and demo user roles. The reset will be added to the session-local audit list.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Reset demo records'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    _performAdminAction(
      context,
      () => controller.resetDemoWorkspace(
        actorRole: actor.role,
        actorId: actor.id,
      ),
    );
  }
}

void _performAdminAction(BuildContext context, VoidCallback action) {
  try {
    action();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Demo record updated and audit event added.'),
      ),
    );
  } on StateError catch (error) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error.message)));
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          detail,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(22),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    );
  }
}
