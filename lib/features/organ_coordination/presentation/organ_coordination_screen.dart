import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_data_table.dart';
import '../../../core/widgets/app_notification_card.dart';
import '../../../core/widgets/app_stat_card.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../core/widgets/glass_card.dart';
import '../../authentication/application/auth_controller.dart';
import '../../authentication/domain/role_access_policy.dart';
import '../../../shared/models/user_model.dart';
import '../data/synthetic_organ_coordination_data.dart';

enum _WorkspaceView {
  overview('Coordination Overview', Icons.dashboard_outlined),
  createCase('Create New Case', Icons.add_circle_outline_rounded),
  caseDetails('Case Details', Icons.description_outlined),
  discovery('AI-Assisted Discovery', Icons.search_rounded),
  workflow('Official Workflow & Logistics', Icons.route_outlined);

  const _WorkspaceView(this.label, this.icon);

  final String label;
  final IconData icon;
}

class OrganCoordinationScreen extends ConsumerStatefulWidget {
  const OrganCoordinationScreen({super.key});

  @override
  ConsumerState<OrganCoordinationScreen> createState() =>
      _OrganCoordinationScreenState();
}

class _OrganCoordinationScreenState
    extends ConsumerState<OrganCoordinationScreen> {
  final _caseFormKey = GlobalKey<FormState>();
  final _caseReferenceController = TextEditingController();
  final _lastUpdatedController = TextEditingController();
  final _capabilityController = TextEditingController();
  final _discoverySearchController = TextEditingController();

  final List<DemoOrganCase> _cases = [...SyntheticOrganCoordinationData.cases];

  _WorkspaceView _view = _WorkspaceView.overview;
  DemoPathway _selectedPathway = DemoPathway.institutionReportedDeceased;
  DemoOrganCategory _selectedCategory = DemoOrganCategory.kidney;
  DemoVerificationStatus _selectedVerification =
      DemoVerificationStatus.awaitingConfirmation;
  String _selectedHospital = SyntheticOrganCoordinationData.hospitals.first;
  String _selectedCoordinator =
      SyntheticOrganCoordinationData.coordinators.first;
  DemoTransplantCentre _selectedCentre =
      SyntheticOrganCoordinationData.centres.first;
  String _selectedCaseReference =
      SyntheticOrganCoordinationData.cases.first.caseReference;
  DemoOrganCategory? _discoveryCategory;
  String _discoveryRegion = 'All demo regions';
  String? _formError;

  @override
  void initState() {
    super.initState();
    _caseReferenceController.text = _createUniqueReference();
    _lastUpdatedController.text = _formatDateTime(DateTime.now());
    _capabilityController.text = _selectedCentre.capabilities.join(' · ');
  }

  @override
  void dispose() {
    _caseReferenceController.dispose();
    _lastUpdatedController.dispose();
    _capabilityController.dispose();
    _discoverySearchController.dispose();
    super.dispose();
  }

  String _createUniqueReference() =>
      'DEMO-OT-${DateTime.now().microsecondsSinceEpoch}';

  String _formatDateTime(DateTime value) =>
      DateFormat('MMM d, yyyy · HH:mm').format(value);

  DemoOrganCase? get _selectedCase {
    for (final item in _cases) {
      if (item.caseReference == _selectedCaseReference) return item;
    }
    return null;
  }

  int get _activeCount => _cases
      .where((item) => item.status != DemoCaseStatus.completedSimulation)
      .length;

  int get _pendingVerificationCount => _cases
      .where(
        (item) =>
            item.verificationStatus ==
            DemoVerificationStatus.awaitingConfirmation,
      )
      .length;

  int get _awaitingResponseCount => _cases
      .where(
        (item) => item.status == DemoCaseStatus.awaitingInstitutionalResponse,
      )
      .length;

  int get _completedCount => _cases
      .where((item) => item.status == DemoCaseStatus.completedSimulation)
      .length;

  void _selectCase(
    DemoOrganCase item, {
    _WorkspaceView view = _WorkspaceView.caseDetails,
  }) {
    setState(() {
      _selectedCaseReference = item.caseReference;
      _view = view;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _updateCase(DemoOrganCase updated) {
    final index = _cases.indexWhere(
      (item) => item.caseReference == updated.caseReference,
    );
    if (index < 0) return;
    setState(() => _cases[index] = updated);
  }

  Future<bool> _requestDemoAcknowledgement({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    var acknowledged = false;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: acknowledged,
                onChanged: (value) =>
                    setDialogState(() => acknowledged = value ?? false),
                title: const Text(
                  'I understand this only updates local synthetic demo state.',
                ),
                subtitle: const Text(
                  'No institution or authority is contacted. No clinical or allocation decision is made.',
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: acknowledged
                  ? () => Navigator.pop(dialogContext, true)
                  : null,
              child: Text(confirmLabel),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  Future<void> _recordHumanReview(DemoOrganCase item) async {
    if (item.humanReviewRecorded) return;
    final acknowledged = await _requestDemoAcknowledgement(
      title: 'Record human review (demo)',
      message: 'Review the administrative case details only. This action does not assess donor eligibility, certify death, establish consent, rank recipients, or approve allocation.',
      confirmLabel: 'Record demo review',
    );
    if (!acknowledged || !mounted) return;

    final now = DateTime.now();
    final actor = _reviewerLabel;
    final event = DemoCaseEvent(
      title: 'Human review recorded (demo)',
      detail: 'Administrative review acknowledged locally. No clinical or allocation decision was made.',
      occurredAt: now,
      actorLabel: actor,
    );
    _updateCase(
      item.copyWith(
        status: item.routeRecorded
            ? DemoCaseStatus.awaitingInstitutionalResponse
            : DemoCaseStatus.activeSimulation,
        humanReviewRecorded: true,
        lastUpdatedAt: now,
        timeline: [...item.timeline, event],
        workflowHistory: [...item.workflowHistory, event],
        auditEvents: [
          ...item.auditEvents,
          DemoCaseEvent(
            title: 'Demo audit event: human review acknowledgement',
            detail: 'Local state change only; not a legal authorization.',
            occurredAt: now,
            actorLabel: actor,
          ),
        ],
        verificationChecklist: item.verificationChecklist
            .map(
              (check) => check.label.startsWith('Human coordinator')
                  ? DemoVerificationCheck(label: check.label, complete: true)
                  : check,
            )
            .toList(),
        notifications: [
          ...item.notifications,
          DemoCaseEvent(
            title: 'Demo human review recorded',
            detail: 'No external party was notified.',
            occurredAt: now,
            actorLabel: 'Prototype notifications',
          ),
        ],
      ),
    );
    _showMessage('Demo review recorded locally. No institution was notified.');
  }

  Future<void> _recordSimulatedRoute(DemoOrganCase item) async {
    if (!item.humanReviewRecorded) {
      _showMessage(
        'Record authorized human review before routing the demo case.',
      );
      return;
    }
    if (item.routeRecorded) return;
    final acknowledged = await _requestDemoAcknowledgement(
      title: 'Record simulated official-pathway step',
      message: 'The prototype will record a local pathway reference to SOTTO, ROTTO, and/or NOTTO as applicable. Competent authorities determine the actual pathway; nothing will be submitted.',
      confirmLabel: 'Record demo pathway',
    );
    if (!acknowledged || !mounted) return;

    final now = DateTime.now();
    final event = DemoCaseEvent(
      title: 'Simulated official-pathway routing recorded',
      detail: 'Reference only: the relevant SOTTO, ROTTO, and/or NOTTO pathway must be determined and actioned by authorized authorities.',
      occurredAt: now,
      actorLabel: 'Prototype workflow',
    );
    _updateCase(
      item.copyWith(
        status: DemoCaseStatus.awaitingInstitutionalResponse,
        routeRecorded: true,
        lastUpdatedAt: now,
        timeline: [...item.timeline, event],
        workflowHistory: [...item.workflowHistory, event],
        auditEvents: [
          ...item.auditEvents,
          DemoCaseEvent(
            title: 'Demo audit event: pathway reference recorded',
            detail: 'No external endpoint was contacted.',
            occurredAt: now,
            actorLabel: _reviewerLabel,
          ),
        ],
        notifications: [
          ...item.notifications,
          DemoCaseEvent(
            title: 'Simulated pathway update',
            detail: 'No institution or authority was contacted.',
            occurredAt: now,
            actorLabel: 'Prototype notifications',
          ),
        ],
      ),
    );
    _showMessage(
      'Simulated route recorded locally. No authority or institution was contacted.',
    );
  }

  Future<void> _recordSyntheticResponse(DemoOrganCase item) async {
    if (!item.routeRecorded) return;
    final acknowledged = await _requestDemoAcknowledgement(
      title: 'Add synthetic response event',
      message: 'This adds a clearly marked demo event only. It does not represent an actual institutional response, acceptance, allocation, or clinical decision.',
      confirmLabel: 'Add demo event',
    );
    if (!acknowledged || !mounted) return;

    final now = DateTime.now();
    final event = DemoCaseEvent(
      title: 'Synthetic response event recorded',
      detail: 'Demo workflow closed for illustration only. No acceptance or allocation is implied.',
      occurredAt: now,
      actorLabel: 'Prototype workflow',
    );
    _updateCase(
      item.copyWith(
        status: DemoCaseStatus.completedSimulation,
        verificationStatus: DemoVerificationStatus.authorityResponseRecorded,
        lastUpdatedAt: now,
        timeline: [...item.timeline, event],
        workflowHistory: [...item.workflowHistory, event],
        auditEvents: [
          ...item.auditEvents,
          DemoCaseEvent(
            title: 'Demo audit event: synthetic response',
            detail: 'Illustrative local event; not received from an authority.',
            occurredAt: now,
            actorLabel: 'Prototype workflow',
          ),
        ],
        notifications: [
          ...item.notifications,
          DemoCaseEvent(
            title: 'Synthetic workflow completion',
            detail: 'Demo-only state change; no real-world outcome.',
            occurredAt: now,
            actorLabel: 'Prototype notifications',
          ),
        ],
      ),
    );
    _showMessage('Synthetic response event recorded. No allocation occurred.');
  }

  String get _reviewerLabel {
    final role = ref.read(authControllerProvider).currentUser?.role;
    return role == null
        ? 'Authorized demo reviewer'
        : 'Demo reviewer · ${role.label}';
  }

  Future<void> _createCase() async {
    if (!(_caseFormKey.currentState?.validate() ?? false)) return;
    final reference = _caseReferenceController.text.trim();
    if (_cases.any((item) => item.caseReference == reference)) {
      setState(() {
        _formError =
            'Reference collision detected. A new demo reference was generated.';
        _caseReferenceController.text = _createUniqueReference();
      });
      return;
    }

    final centre = _selectedCentre;
    final item = SyntheticOrganCoordinationData.createCase(
      reference: reference,
      hospital: _selectedHospital,
      pathway: _selectedPathway,
      category: _selectedCategory,
      verification: _selectedVerification,
      coordinator: _selectedCoordinator,
      centre: centre,
    );
    setState(() {
      _cases.insert(0, item);
      _selectedCaseReference = item.caseReference;
      _view = _WorkspaceView.caseDetails;
      _formError = null;
      _caseReferenceController.text = _createUniqueReference();
      _lastUpdatedController.text = _formatDateTime(DateTime.now());
    });
    _showMessage(
      'Synthetic case created locally. No external pathway was started.',
    );
  }

  List<DemoTransplantCentre> get _matchingCentres {
    final query = _discoverySearchController.text.trim().toLowerCase();
    final matching = SyntheticOrganCoordinationData.centres.where((centre) {
      if (_discoveryCategory != null &&
          !centre.categories.contains(_discoveryCategory)) {
        return false;
      }
      if (_discoveryRegion != 'All demo regions' &&
          centre.region != _discoveryRegion) {
        return false;
      }
      if (query.isEmpty) return true;
      return [
        centre.name,
        centre.region,
        ...centre.capabilities,
      ].any((value) => value.toLowerCase().contains(query));
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
    return matching;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authControllerProvider).currentUser;
    final selectedCase = _selectedCase;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(context.isDesktop ? 24 : 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSafetyDisclaimer(),
                const SizedBox(height: 18),
                _buildModuleHeader(currentUser),
                const SizedBox(height: 16),
                _buildNavigation(),
                const SizedBox(height: 20),
                if (_view == _WorkspaceView.overview) _buildOverview(),
                if (_view == _WorkspaceView.createCase) _buildCreateCase(),
                if (_view == _WorkspaceView.caseDetails)
                  _buildCaseDetails(selectedCase),
                if (_view == _WorkspaceView.discovery) _buildDiscovery(),
                if (_view == _WorkspaceView.workflow)
                  _buildWorkflow(selectedCase),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSafetyDisclaimer() {
    return GlassCard(
      glowAccent: GlowAccent.warning,
      padding: const EdgeInsets.all(18),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.health_and_safety_outlined,
                color: AppColors.warning,
                size: 23,
              ),
              SizedBox(width: 11),
              Expanded(
                child: Text(
                  'AI assistance only. Clinical and allocation decisions remain with authorized authorities and medical professionals.',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Competition prototype · all cases and institutions are fictional. This module does not determine donor eligibility, certify death, establish consent, rank recipients, or allocate organs. No external institution or authority is contacted.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleHeader(UserModel? currentUser) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Organ & Tissue Coordination',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              currentUser == null
                  ? 'Authorized coordinator workspace · synthetic data'
                  : '${currentUser.role.label} workspace · synthetic data',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        );
        final actions = Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            AppButton(
              label: 'New demo case',
              icon: Icons.add_rounded,
              onPressed: () =>
                  setState(() => _view = _WorkspaceView.createCase),
            ),
            AppButton(
              label: 'Discover centres',
              icon: Icons.search_rounded,
              variant: AppButtonVariant.secondary,
              onPressed: () => setState(() => _view = _WorkspaceView.discovery),
            ),
          ],
        );

        if (constraints.maxWidth < 720) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 14), actions],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: title),
            const SizedBox(width: 14),
            actions,
          ],
        );
      },
    );
  }

  Widget _buildNavigation() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _WorkspaceView.values.map((view) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              key: Key('organ-view-${view.name}'),
              selected: _view == view,
              onSelected: (_) => setState(() => _view = view),
              avatar: Icon(view.icon, size: 16),
              label: Text(view.label),
              selectedColor: AppColors.accentPrimary.withAlpha(35),
              side: BorderSide(
                color: _view == view
                    ? AppColors.accentPrimary.withAlpha(130)
                    : AppColors.borderSubtle,
              ),
              labelStyle: TextStyle(
                color: _view == view
                    ? AppColors.accentPrimary
                    : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              backgroundColor: AppColors.bgSecondary,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
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
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildOverview() {
    final stats = [
      AppStatCard(
        title: 'Active simulated cases',
        value: '$_activeCount',
        subtitle: 'Fictional local workflows',
        icon: Icons.sync_alt_rounded,
        accentColor: AppColors.accentPrimary,
      ),
      AppStatCard(
        title: 'Pending verification',
        value: '$_pendingVerificationCount',
        subtitle: 'Institution confirmation needed',
        icon: Icons.fact_check_outlined,
        accentColor: AppColors.warning,
      ),
      AppStatCard(
        title: 'Awaiting institutional response',
        value: '$_awaitingResponseCount',
        subtitle: 'No external request sent',
        icon: Icons.hourglass_bottom_rounded,
        accentColor: AppColors.accentSecondary,
      ),
      AppStatCard(
        title: 'Completed workflows',
        value: '$_completedCount',
        subtitle: 'Demo closure only · no allocation',
        icon: Icons.task_alt_rounded,
        accentColor: AppColors.success,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(
          'Coordination overview',
          'Pseudonymized cases, verification progress, and workflow status for this local competition prototype.',
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1150
                ? 4
                : constraints.maxWidth >= 680
                ? 2
                : 1;
            return GridView.count(
              crossAxisCount: columns,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: columns == 1 ? 1.9 : 1.5,
              children: stats,
            );
          },
        ),
        const SizedBox(height: 22),
        _sectionTitle(
          'Recent synthetic cases',
          'No donor or recipient identity is stored or displayed. Select a case to review its administrative history.',
        ),
        const SizedBox(height: 12),
        _buildCaseTable(),
      ],
    );
  }

  Widget _buildCaseTable() {
    final orderedCases = [..._cases]
      ..sort((a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt));
    return AppDataTable(
      columns: const [
        AppTableColumn(title: 'Case reference', width: 180),
        AppTableColumn(title: 'Hospital', width: 250),
        AppTableColumn(title: 'Pathway', width: 260),
        AppTableColumn(title: 'Category', width: 130),
        AppTableColumn(title: 'Workflow status', width: 220),
        AppTableColumn(title: 'Verification', width: 240),
        AppTableColumn(title: 'Last updated', width: 180),
      ],
      rows: orderedCases.map((item) {
        return AppTableRow(
          onTap: () => _selectCase(item),
          cells: [
            Text(
              item.caseReference,
              style: const TextStyle(
                color: AppColors.accentPrimary,
                fontSize: 12,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              item.hospital,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
            Text(
              item.pathway.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            Text(
              item.category.label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
            AppStatusBadge(
              label: item.status.label,
              variant: _caseStatusVariant(item.status),
              showDot: false,
            ),
            AppStatusBadge(
              label: item.verificationStatus.label,
              variant: _verificationVariant(item.verificationStatus),
              showDot: false,
            ),
            Text(
              _formatDateTime(item.lastUpdatedAt),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        );
      }).toList(),
      totalRecords: orderedCases.length,
      emptyMessage: 'No synthetic cases are available.',
    );
  }

  StatusBadgeVariant _caseStatusVariant(DemoCaseStatus status) {
    return switch (status) {
      DemoCaseStatus.pendingVerification => StatusBadgeVariant.warning,
      DemoCaseStatus.awaitingInstitutionalResponse => StatusBadgeVariant.info,
      DemoCaseStatus.activeSimulation => StatusBadgeVariant.active,
      DemoCaseStatus.completedSimulation => StatusBadgeVariant.neutral,
    };
  }

  StatusBadgeVariant _verificationVariant(DemoVerificationStatus status) {
    return status == DemoVerificationStatus.awaitingConfirmation
        ? StatusBadgeVariant.warning
        : StatusBadgeVariant.info;
  }

  Widget _buildCreateCase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(
          'Create a new synthetic case',
          'Administrative enquiry fields only. Pathway and verification values are institution-reported; this form does not establish clinical facts.',
        ),
        const SizedBox(height: 14),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _caseFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _formField(
                  label: 'Unique case reference',
                  controller: _caseReferenceController,
                  readOnly: true,
                  helper: 'Generated locally for this demonstration; no production record is created.',
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 640;
                    final hospital = _dropdownField<String>(
                      label: 'Hospital',
                      value: _selectedHospital,
                      values: SyntheticOrganCoordinationData.hospitals,
                      itemLabel: (value) => value,
                      onChanged: (value) => setState(
                        () => _selectedHospital = value ?? _selectedHospital,
                      ),
                    );
                    final pathway = _dropdownField<DemoPathway>(
                      label: 'Donation pathway (institution-reported)',
                      value: _selectedPathway,
                      values: DemoPathway.values,
                      itemLabel: (value) => value.label,
                      onChanged: (value) => setState(
                        () => _selectedPathway = value ?? _selectedPathway,
                      ),
                    );
                    final category = _dropdownField<DemoOrganCategory>(
                      label: 'Organ/tissue category',
                      value: _selectedCategory,
                      values: DemoOrganCategory.values,
                      itemLabel: (value) => value.label,
                      onChanged: (value) => setState(
                        () => _selectedCategory = value ?? _selectedCategory,
                      ),
                    );
                    final verification = _dropdownField<DemoVerificationStatus>(
                      label: 'Verification status',
                      value: _selectedVerification,
                      values: DemoVerificationStatus.values,
                      itemLabel: (value) => value.label,
                      onChanged: (value) => setState(
                        () => _selectedVerification =
                            value ?? _selectedVerification,
                      ),
                    );
                    if (narrow) {
                      return Column(
                        children: [
                          hospital,
                          const SizedBox(height: 14),
                          pathway,
                          const SizedBox(height: 14),
                          category,
                          const SizedBox(height: 14),
                          verification,
                        ],
                      );
                    }
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: hospital),
                            const SizedBox(width: 14),
                            Expanded(child: pathway),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: category),
                            const SizedBox(width: 14),
                            Expanded(child: verification),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 640;
                    final updated = _formField(
                      label: 'Last updated',
                      controller: _lastUpdatedController,
                      readOnly: true,
                    );
                    final coordinator = _dropdownField<String>(
                      label: 'Authorized coordinator (pseudonymized)',
                      value: _selectedCoordinator,
                      values: SyntheticOrganCoordinationData.coordinators,
                      itemLabel: (value) => value,
                      onChanged: (value) => setState(
                        () => _selectedCoordinator =
                            value ?? _selectedCoordinator,
                      ),
                    );
                    if (narrow) {
                      return Column(
                        children: [
                          updated,
                          const SizedBox(height: 14),
                          coordinator,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: updated),
                        const SizedBox(width: 14),
                        Expanded(child: coordinator),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                _dropdownField<DemoTransplantCentre>(
                  label: 'Relevant centre capability (synthetic directory)',
                  value: _selectedCentre,
                  values: SyntheticOrganCoordinationData.centres,
                  itemLabel: (centre) => '${centre.name} · ${centre.region}',
                  onChanged: (centre) {
                    if (centre == null) return;
                    setState(() {
                      _selectedCentre = centre;
                      _capabilityController.text = centre.capabilities.join(
                        ' · ',
                      );
                    });
                  },
                ),
                const SizedBox(height: 12),
                _formField(
                  label: 'Capability summary (demo directory)',
                  controller: _capabilityController,
                  readOnly: true,
                  maxLines: 2,
                  helper: 'A declared directory capability is not confirmation of suitability, capacity, or availability.',
                ),
                if (_formError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _formError!,
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    AppButton(
                      label: 'Create synthetic case',
                      icon: Icons.add_task_rounded,
                      onPressed: _createCase,
                    ),
                    AppButton(
                      label: 'Cancel',
                      variant: AppButtonVariant.ghost,
                      onPressed: () =>
                          setState(() => _view = _WorkspaceView.overview),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _formField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    int maxLines = 1,
    String? helper,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines,
          validator: maxLines == 1 && !readOnly
              ? (value) => Validators.requiredField(value)
              : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? AppColors.bgSecondary : AppColors.bgInput,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 5),
          Text(
            helper,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  Widget _dropdownField<T>({
    required String label,
    required T value,
    required List<T> values,
    required String Function(T value) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: values
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (item) => item == null ? 'Select $label' : null,
    );
  }

  Widget _buildCaseDetails(DemoOrganCase? item) {
    if (item == null) {
      return _emptyState('Select a synthetic case to view details.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _sectionTitle(
                'Case details · ${item.caseReference}',
                'Pseudonymized case view. No donor or recipient identity is present.',
              ),
            ),
            IconButton(
              tooltip: 'Back to coordination overview',
              onPressed: () => setState(() => _view = _WorkspaceView.overview),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.accentPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppStatusBadge(
                label: item.status.label,
                variant: _caseStatusVariant(item.status),
                showDot: false,
              ),
              AppStatusBadge(
                label: item.verificationStatus.label,
                variant: _verificationVariant(item.verificationStatus),
                showDot: false,
              ),
              Text(
                'Last updated ${_formatDateTime(item.lastUpdatedAt)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildCaseSummary(item),
        const SizedBox(height: 14),
        _buildDetailPanels(item),
      ],
    );
  }

  Widget _buildCaseSummary(DemoOrganCase item) {
    final fields = <MapEntry<String, String>>[
      MapEntry('Hospital', item.hospital),
      MapEntry('Donation pathway', item.pathway.label),
      MapEntry('Organ/tissue category', item.category.label),
      MapEntry('Authorized coordinator', item.authorizedCoordinator),
      MapEntry('Relevant centre', item.relevantCentre),
      MapEntry('Relevant centre capability', item.relevantCentreCapability),
    ];
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Administrative case summary',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 760 ? 2 : 1;
              return Wrap(
                spacing: 20,
                runSpacing: 14,
                children: fields.map((field) {
                  return SizedBox(
                    width: columns == 2
                        ? (constraints.maxWidth - 20) / 2
                        : constraints.maxWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          field.key,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          field.value,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanels(DemoOrganCase item) {
    final checklist = _checklistPanel(item);
    final institutions = _institutionsPanel(item);
    final timeline = _eventPanel('Case timeline', item.timeline);
    final notifications = _notificationPanel(item);
    final workflow = _eventPanel('Workflow history', item.workflowHistory);
    final audit = _eventPanel('Audit events', item.auditEvents);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 860) {
          return Column(
            children: [
              checklist,
              const SizedBox(height: 12),
              institutions,
              const SizedBox(height: 12),
              timeline,
              const SizedBox(height: 12),
              notifications,
              const SizedBox(height: 12),
              workflow,
              const SizedBox(height: 12),
              audit,
            ],
          );
        }
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: checklist),
                const SizedBox(width: 14),
                Expanded(child: institutions),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: timeline),
                const SizedBox(width: 14),
                Expanded(child: notifications),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: workflow),
                const SizedBox(width: 14),
                Expanded(child: audit),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _checklistPanel(DemoOrganCase item) {
    return _panel(
      'Verification checklist · administrative only',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This checklist does not determine eligibility, certify death, establish consent, or approve allocation.',
            style: TextStyle(
              color: AppColors.warning,
              fontSize: 10,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          ...item.verificationChecklist.map(
            (check) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    check.complete
                        ? Icons.check_circle_outline_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: check.complete
                        ? AppColors.accentPrimary
                        : AppColors.textMuted,
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      check.label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _institutionsPanel(DemoOrganCase item) {
    return _panel(
      'Participating institutions',
      Column(
        children: item.institutions.map((institution) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.account_balance_outlined,
                  color: AppColors.accentSecondary,
                  size: 17,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        institution.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${institution.role} · ${institution.responseStatus}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _eventPanel(String title, List<DemoCaseEvent> events) {
    return _panel(
      title,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: events.isEmpty
            ? [
                const Text(
                  'No events recorded in this synthetic case.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ]
            : events.reversed.map((event) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.circle,
                        color: AppColors.accentPrimary,
                        size: 7,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              event.detail,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatDateTime(event.occurredAt)} · ${event.actorLabel}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
      ),
    );
  }

  Widget _notificationPanel(DemoOrganCase item) {
    return _panel(
      'Notifications',
      Column(
        children: item.notifications.reversed.map((notification) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppNotificationCard(
              title: notification.title,
              message: notification.detail,
              timeAgo: _formatDateTime(notification.occurredAt),
              severity: NotificationSeverity.info,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _panel(String title, Widget child) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDiscovery() {
    final regions = {
      'All demo regions',
      ...SyntheticOrganCoordinationData.centres.map((centre) => centre.region),
    };
    final centres = _matchingCentres;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(
          'AI-assisted centre discovery',
          'Search directory capabilities using approved criteria only: declared capability, region, and organ/tissue category.',
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Advisory search only. Results are fictional directory records, sorted alphabetically—not ranked, matched to a recipient, or validated for a specific case.',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final search = TextField(
                    key: const Key('organ-centre-search'),
                    controller: _discoverySearchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Search declared capability',
                      hintText: 'e.g. tissue preservation',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  );
                  final category = _dropdownField<DemoOrganCategory?>(
                    label: 'Organ/tissue category',
                    value: _discoveryCategory,
                    values: [null, ...DemoOrganCategory.values],
                    itemLabel: (value) => value?.label ?? 'All categories',
                    onChanged: (value) =>
                        setState(() => _discoveryCategory = value),
                  );
                  final region = DropdownButtonFormField<String>(
                    initialValue: _discoveryRegion,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Region'),
                    items: regions
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(
                      () => _discoveryRegion = value ?? _discoveryRegion,
                    ),
                  );
                  if (constraints.maxWidth < 720) {
                    return Column(
                      children: [
                        search,
                        const SizedBox(height: 12),
                        category,
                        const SizedBox(height: 12),
                        region,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(flex: 2, child: search),
                      const SizedBox(width: 12),
                      Expanded(child: category),
                      const SizedBox(width: 12),
                      Expanded(child: region),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _sectionTitle(
          'Directory results · ${centres.length}',
          'Capability descriptions are synthetic and require independent institutional confirmation.',
        ),
        const SizedBox(height: 12),
        if (centres.isEmpty)
          _emptyState(
            'No fictional centre entries match these search criteria.',
          )
        else
          ...centres.map(_centreCard),
      ],
    );
  }

  Widget _centreCard(DemoTransplantCentre centre) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(17),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  centre.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  centre.region,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: centre.categories
                      .map((category) => _categoryChip(category.label))
                      .toList(),
                ),
                const SizedBox(height: 8),
                ...centre.capabilities.map(
                  (capability) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check,
                          color: AppColors.accentPrimary,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            capability,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  centre.directoryStatus,
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 10,
                  ),
                ),
              ],
            );
            final action = AppButton(
              label: 'Use capability in draft',
              icon: Icons.edit_note_rounded,
              variant: AppButtonVariant.secondary,
              onPressed: () {
                setState(() {
                  _selectedCentre = centre;
                  _capabilityController.text = centre.capabilities.join(' · ');
                  _view = _WorkspaceView.createCase;
                });
              },
            );
            if (constraints.maxWidth < 780) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [details, const SizedBox(height: 12), action],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: details),
                const SizedBox(width: 16),
                action,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _categoryChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
      ),
    );
  }

  Widget _buildWorkflow(DemoOrganCase? item) {
    if (item == null) {
      return _emptyState('Select a synthetic case to view its workflow.');
    }
    final currentUser = ref.watch(authControllerProvider).currentUser;
    final mayReview =
        currentUser != null &&
        RoleAccessPolicy.canAccess(currentUser.role, '/organ-coordination');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(
          'Official workflow routing · simulation',
          'Human review is required before a simulated pathway step can be recorded.',
        ),
        const SizedBox(height: 12),
        _buildSelectedCaseHeader(item),
        const SizedBox(height: 14),
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Illustrative authority pathway',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'This prototype does not determine the correct route. The competent authority and the institution decide which SOTTO, ROTTO, and/or NOTTO pathway applies and how to submit.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              _routeStage(
                '1',
                'Submitting institution’s authorized coordinator',
                'Prepare and verify the enquiry through the institution’s established pathway.',
                'Institution action required',
              ),
              _routeStage(
                '2',
                'SOTTO / ROTTO review (as applicable)',
                'State or regional review pathway determined by the competent authority.',
                'Authority determines applicability',
              ),
              _routeStage(
                '3',
                'NOTTO pathway (where applicable)',
                'National-level coordination only through the appropriate official process.',
                'Authority determines applicability',
              ),
              if (item.routeRecorded)
                const AppStatusBadge(
                  label: 'DEMO PATHWAY REFERENCE RECORDED LOCALLY',
                  variant: StatusBadgeVariant.info,
                  showDot: false,
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          glowAccent: item.humanReviewRecorded
              ? GlowAccent.cyan
              : GlowAccent.warning,
          padding: const EdgeInsets.all(18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final info = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.humanReviewRecorded
                        ? 'Human review recorded (demo)'
                        : 'Human review required',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.humanReviewRecorded
                        ? 'Reviewer: $_reviewerLabel. This records administrative acknowledgement only.'
                        : 'An authorized coordinator must review the administrative record before any simulated workflow step. AI suggestions cannot approve or progress a case.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                ],
              );
              final action = item.humanReviewRecorded
                  ? const AppStatusBadge(
                      label: 'REVIEW STEP COMPLETE · DEMO',
                      variant: StatusBadgeVariant.success,
                      showDot: false,
                    )
                  : AppButton(
                      label: 'Record human review',
                      icon: Icons.how_to_reg_outlined,
                      onPressed: mayReview
                          ? () => _recordHumanReview(item)
                          : null,
                    );
              if (constraints.maxWidth < 740) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [info, const SizedBox(height: 12), action],
                );
              }
              return Row(
                children: [
                  Expanded(child: info),
                  const SizedBox(width: 14),
                  action,
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppButton(
                label: item.routeRecorded
                    ? 'Pathway reference recorded'
                    : 'Record simulated pathway step',
                icon: Icons.route_outlined,
                variant: AppButtonVariant.secondary,
                onPressed:
                    !mayReview ||
                        !item.humanReviewRecorded ||
                        item.routeRecorded
                    ? null
                    : () => _recordSimulatedRoute(item),
              ),
              if (item.routeRecorded &&
                  item.status != DemoCaseStatus.completedSimulation)
                AppButton(
                  label: 'Add synthetic response event',
                  icon: Icons.mark_email_read_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: mayReview
                      ? () => _recordSyntheticResponse(item)
                      : null,
                ),
              if (item.status == DemoCaseStatus.completedSimulation)
                const AppStatusBadge(
                  label: 'DEMO WORKFLOW CLOSED · NO ALLOCATION IMPLIED',
                  variant: StatusBadgeVariant.neutral,
                  showDot: false,
                ),
              if (!item.humanReviewRecorded)
                const Text(
                  'Routing is disabled until an authorized human review is recorded.',
                  style: TextStyle(color: AppColors.warning, fontSize: 10),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _sectionTitle(
          'Logistics tracking · simulated',
          'Status indicators below are placeholders only; no retrieval, preservation, transport, or receiving-centre arrangement has been initiated.',
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 920
                ? 4
                : constraints.maxWidth > 560
                ? 2
                : 1;
            return GridView.count(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: columns == 1 ? 2.4 : 1.3,
              children: item.logistics.map(_logisticsCard).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSelectedCaseHeader(DemoOrganCase item) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            item.caseReference,
            style: const TextStyle(
              color: AppColors.accentPrimary,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            item.category.label,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
          ),
          AppStatusBadge(
            label: item.status.label,
            variant: _caseStatusVariant(item.status),
            showDot: false,
          ),
          Text(
            'Updated ${_formatDateTime(item.lastUpdatedAt)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeStage(
    String number,
    String title,
    String detail,
    String status,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: AppColors.accentSecondary.withAlpha(25),
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.accentSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  status,
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _logisticsCard(DemoLogisticsStage stage) {
    return GlassCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.local_shipping_outlined,
            color: AppColors.accentSecondary,
            size: 19,
          ),
          const SizedBox(height: 9),
          Text(
            stage.label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            stage.status,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              height: 1.4,
            ),
          ),
          const Spacer(),
          Text(
            'Last updated · ${_formatDateTime(stage.lastUpdatedAt)}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String message) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ),
    );
  }
}
