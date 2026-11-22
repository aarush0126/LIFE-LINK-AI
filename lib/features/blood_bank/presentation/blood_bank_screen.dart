import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_data_table.dart';
import '../../../core/widgets/app_stat_card.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../core/widgets/glass_card.dart';
import '../data/synthetic_blood_bank_data.dart';

class BloodBankScreen extends StatefulWidget {
  const BloodBankScreen({super.key});

  @override
  State<BloodBankScreen> createState() => _BloodBankScreenState();
}

class _BloodBankScreenState extends State<BloodBankScreen> {
  static const _pageSize = 8;

  final _requestFormKey = GlobalKey<FormState>();
  final _requestSectionKey = GlobalKey();
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController(text: '2');
  final _coordinatorController = TextEditingController();
  final _inventory = [...SyntheticBloodBankData.inventory];
  final _requests = [...SyntheticBloodBankData.initialRequests];
  final _notifications = [...SyntheticBloodBankData.initialNotifications];

  String _searchQuery = '';
  String? _selectedBloodGroup;
  DemoBloodComponent? _selectedComponent;
  DemoBloodQuantityBand? _selectedQuantityBand;
  DemoBloodExpiryWindow? _selectedExpiryWindow;
  DemoBloodVerification? _selectedVerification;
  String _requestingHospital = SyntheticBloodBankData.hospitals.first;
  String _requestBloodGroup = SyntheticBloodBankData.bloodGroups.first;
  DemoBloodComponent _requestComponent = DemoBloodComponent.packedRedBloodCells;
  DemoBloodUrgency _requestUrgency = DemoBloodUrgency.routine;
  int _currentPage = 1;
  String? _formError;

  List<DemoBloodInventoryListing> get _filteredInventory {
    final query = _searchQuery.trim().toLowerCase();
    final result =
        _inventory.where((listing) {
          if (_selectedBloodGroup != null &&
              listing.bloodGroup != _selectedBloodGroup) {
            return false;
          }
          if (_selectedComponent != null &&
              listing.component != _selectedComponent) {
            return false;
          }
          if (_selectedQuantityBand != null &&
              listing.quantityBand != _selectedQuantityBand) {
            return false;
          }
          if (_selectedExpiryWindow != null &&
              listing.expiryWindow != _selectedExpiryWindow) {
            return false;
          }
          if (_selectedVerification != null &&
              listing.verification != _selectedVerification) {
            return false;
          }
          if (query.isEmpty) return true;
          return [
            listing.hospital,
            listing.location,
            listing.bloodGroup,
            listing.component.label,
            listing.quantityBand.label,
            listing.expiryWindow.label,
            listing.verification.label,
          ].any((value) => value.toLowerCase().contains(query));
        }).toList()..sort((a, b) {
          final hospitalOrder = a.hospital.compareTo(b.hospital);
          if (hospitalOrder != 0) return hospitalOrder;
          final groupOrder = a.bloodGroup.compareTo(b.bloodGroup);
          if (groupOrder != 0) return groupOrder;
          return a.component.index.compareTo(b.component.index);
        });
    return result;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    _coordinatorController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime value) =>
      DateFormat('MMM d, yyyy · HH:mm').format(value);

  String _formatDate(DateTime value) => DateFormat('MMM d, yyyy').format(value);

  void _updateFilters(VoidCallback update) {
    setState(() {
      update();
      _currentPage = 1;
    });
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedBloodGroup = null;
      _selectedComponent = null;
      _selectedQuantityBand = null;
      _selectedExpiryWindow = null;
      _selectedVerification = null;
      _currentPage = 1;
    });
  }

  String _newRequestId() => 'DEMO-BR-${DateTime.now().microsecondsSinceEpoch}';

  void _submitRequest() {
    if (!(_requestFormKey.currentState?.validate() ?? false)) return;
    final quantity = int.parse(_quantityController.text.trim());
    final now = DateTime.now();
    final requestId = _newRequestId();
    final request = DemoBloodRequest(
      requestId: requestId,
      requestingHospital: _requestingHospital,
      bloodGroup: _requestBloodGroup,
      component: _requestComponent,
      requiredQuantity: quantity,
      urgency: _requestUrgency,
      contactCoordinator: _coordinatorController.text.trim(),
      status: DemoBloodRequestStatus.enquiryLogged,
      lastUpdatedAt: now,
    );
    final receivingHospitals = _inventory
        .where(
          (listing) =>
              listing.bloodGroup == _requestBloodGroup &&
              listing.component == _requestComponent,
        )
        .map((listing) => listing.hospital)
        .toSet();
    final recipients = receivingHospitals.isEmpty
        ? const ['LIFE-LINK Demo Blood Bank Inbox']
        : receivingHospitals;
    final notifications = recipients.map(
      (hospital) => DemoBloodNotification(
        title: 'Simulated blood enquiry received',
        detail:
            '$requestId · $_requestBloodGroup ${_requestComponent.label} · $quantity requested units. Local demo inbox only; no external message was sent.',
        hospital: hospital,
        occurredAt: now,
        requestId: requestId,
      ),
    );

    setState(() {
      _requests.insert(0, request);
      _notifications.insertAll(0, notifications);
      _formError = null;
      _quantityController.text = '2';
      _coordinatorController.clear();
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Synthetic enquiry created locally. No hospital was contacted.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredInventory;
    final pageCount = (filtered.length / _pageSize).ceil().clamp(1, 999);
    final page = _currentPage.clamp(1, pageCount);
    final pageItems = filtered.skip((page - 1) * _pageSize).take(_pageSize);
    final listedUnits = _inventory.fold<int>(
      0,
      (total, listing) => total + listing.reportedUnits,
    );
    final demoConfirmedCount = _inventory
        .where(
          (listing) =>
              listing.verification == DemoBloodVerification.demoConfirmed,
        )
        .length;
    final pendingCount = _inventory
        .where(
          (listing) => listing.verification == DemoBloodVerification.pending,
        )
        .length;

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
                _buildSafetyNotice(),
                const SizedBox(height: 18),
                _buildHeader(),
                const SizedBox(height: 18),
                _buildOverview(
                  listedUnits: listedUnits,
                  demoConfirmedCount: demoConfirmedCount,
                  pendingCount: pendingCount,
                ),
                const SizedBox(height: 24),
                _buildInventorySection(filtered, pageItems, page, pageCount),
                const SizedBox(height: 24),
                _buildHospitalAvailability(filtered),
                const SizedBox(height: 24),
                _buildRequestForm(),
                const SizedBox(height: 24),
                _buildRecentRequests(),
                const SizedBox(height: 24),
                _buildNotifications(),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'Synthetic demonstration environment · No live blood-bank systems are connected',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSafetyNotice() {
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
                  'Blood compatibility, reservation, issue and transfusion decisions must remain with authorized blood-bank professionals.',
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
          SizedBox(height: 9),
          Text(
            'All listings, requests, institutions, and notifications are fictional demo data. Reported quantities are not confirmed or guaranteed availability. “Demo-confirmed” is illustrative only and does not indicate real institutional verification.',
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

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Blood Bank Network',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Synthetic inventory, institutional enquiries, and verification tracking.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 10),
            const AppStatusBadge(
              label: 'SYNTHETIC INVENTORY · NO LIVE STOCK',
              variant: StatusBadgeVariant.info,
              showDot: false,
            ),
          ],
        );
        final action = AppButton(
          label: 'New blood enquiry',
          icon: Icons.add_rounded,
          onPressed: () {
            final targetContext = _requestSectionKey.currentContext;
            if (targetContext != null) {
              Scrollable.ensureVisible(
                targetContext,
                duration: const Duration(milliseconds: 350),
                alignment: 0.1,
              );
            }
          },
        );

        if (constraints.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 14), action],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: title),
            const SizedBox(width: 16),
            action,
          ],
        );
      },
    );
  }

  Widget _buildOverview({
    required int listedUnits,
    required int demoConfirmedCount,
    required int pendingCount,
  }) {
    final cards = [
      AppStatCard(
        title: 'Synthetic inventory listings',
        value: '${_inventory.length}',
        subtitle: 'Across fictional institutions',
        icon: Icons.bloodtype_outlined,
        accentColor: AppColors.bloodRed,
      ),
      AppStatCard(
        title: 'Reported units · demo',
        value: '$listedUnits',
        subtitle: 'Not confirmed or reservable',
        icon: Icons.inventory_2_outlined,
        accentColor: AppColors.accentSecondary,
      ),
      AppStatCard(
        title: 'Demo-confirmed listings',
        value: '$demoConfirmedCount',
        subtitle: 'Illustrative status only',
        icon: Icons.verified_outlined,
        accentColor: AppColors.success,
      ),
      AppStatCard(
        title: 'Verification pending',
        value: '$pendingCount',
        subtitle: 'No real verification performed',
        icon: Icons.pending_actions_outlined,
        accentColor: AppColors.warning,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
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
          childAspectRatio: columns == 1 ? 2.0 : 1.45,
          children: cards,
        );
      },
    );
  }

  Widget _buildInventorySection(
    List<DemoBloodInventoryListing> filtered,
    Iterable<DemoBloodInventoryListing> pageItems,
    int page,
    int pageCount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(
          'Blood inventory overview',
          'Search and filter fictional institution reports. Verify every listing directly through authorized blood-bank staff.',
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth < 280
                      ? constraints.maxWidth
                      : 250.0;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: width,
                        child: TextField(
                          key: const Key('blood-inventory-search'),
                          controller: _searchController,
                          onChanged: (value) =>
                              _updateFilters(() => _searchQuery = value),
                          decoration: const InputDecoration(
                            labelText: 'Search inventory',
                            hintText: 'Hospital, group, component...',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: _filterDropdown<String>(
                          key: const Key('blood-group-filter'),
                          label: 'Blood group',
                          value: _selectedBloodGroup,
                          options: SyntheticBloodBankData.bloodGroups,
                          optionLabel: (value) => value,
                          onChanged: (value) =>
                              _updateFilters(() => _selectedBloodGroup = value),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: _filterDropdown<DemoBloodComponent>(
                          key: const Key('blood-component-filter'),
                          label: 'Component',
                          value: _selectedComponent,
                          options: DemoBloodComponent.values,
                          optionLabel: (value) => value.label,
                          onChanged: (value) =>
                              _updateFilters(() => _selectedComponent = value),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: _filterDropdown<DemoBloodQuantityBand>(
                          key: const Key('blood-quantity-filter'),
                          label: 'Quantity band',
                          value: _selectedQuantityBand,
                          options: DemoBloodQuantityBand.values,
                          optionLabel: (value) => value.label,
                          onChanged: (value) => _updateFilters(
                            () => _selectedQuantityBand = value,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: _filterDropdown<DemoBloodExpiryWindow>(
                          key: const Key('blood-expiry-filter'),
                          label: 'Expiry window',
                          value: _selectedExpiryWindow,
                          options: DemoBloodExpiryWindow.values,
                          optionLabel: (value) => value.label,
                          onChanged: (value) => _updateFilters(
                            () => _selectedExpiryWindow = value,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: _filterDropdown<DemoBloodVerification>(
                          key: const Key('blood-verification-filter'),
                          label: 'Institution verification',
                          value: _selectedVerification,
                          options: DemoBloodVerification.values,
                          optionLabel: (value) => value.label,
                          onChanged: (value) => _updateFilters(
                            () => _selectedVerification = value,
                          ),
                        ),
                      ),
                      AppButton(
                        label: 'Reset filters',
                        icon: Icons.filter_alt_off_rounded,
                        variant: AppButtonVariant.ghost,
                        onPressed: _resetFilters,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              AppDataTable(
                columns: const [
                  AppTableColumn(title: 'Institution', width: 250),
                  AppTableColumn(title: 'Blood group', width: 110),
                  AppTableColumn(title: 'Component', width: 230),
                  AppTableColumn(title: 'Reported quantity', width: 150),
                  AppTableColumn(title: 'Quantity band', width: 130),
                  AppTableColumn(title: 'Expiry window', width: 190),
                  AppTableColumn(title: 'Last updated', width: 180),
                  AppTableColumn(title: 'Verification status', width: 200),
                ],
                rows: pageItems.map(_inventoryRow).toList(),
                emptyMessage: 'No synthetic listings match these filters. Reset or change the search.',
                currentPage: page,
                totalPages: pageCount,
                totalRecords: filtered.length,
                onPageChanged: (value) => setState(() => _currentPage = value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  AppTableRow _inventoryRow(DemoBloodInventoryListing listing) {
    return AppTableRow(
      cells: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              listing.hospital,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              listing.location,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
            ),
          ],
        ),
        Text(
          listing.bloodGroup,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          listing.component.label,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
        ),
        Text(
          '${listing.reportedUnits} units · synthetic report',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        Text(
          listing.quantityBand.label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${listing.expiryWindow.label} · demo',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
              ),
            ),
            Text(
              'Illustrative date ${_formatDate(listing.expiresAt)}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
            ),
          ],
        ),
        Text(
          _formatDateTime(listing.lastUpdatedAt),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
        ),
        AppStatusBadge(
          label: listing.verification.label,
          variant: _verificationVariant(listing.verification),
          showDot: false,
        ),
      ],
    );
  }

  StatusBadgeVariant _verificationVariant(DemoBloodVerification status) {
    return switch (status) {
      DemoBloodVerification.reported => StatusBadgeVariant.warning,
      DemoBloodVerification.pending => StatusBadgeVariant.info,
      DemoBloodVerification.demoConfirmed => StatusBadgeVariant.success,
    };
  }

  Widget _buildHospitalAvailability(List<DemoBloodInventoryListing> filtered) {
    final byHospital = <String, List<DemoBloodInventoryListing>>{};
    for (final listing in filtered) {
      byHospital.putIfAbsent(listing.hospital, () => []).add(listing);
    }

    final rows = byHospital.entries.map((entry) {
      final units = entry.value.fold<int>(
        0,
        (total, listing) => total + listing.reportedUnits,
      );
      final demoConfirmed = entry.value
          .where(
            (listing) =>
                listing.verification == DemoBloodVerification.demoConfirmed,
          )
          .length;
      return AppTableRow(
        cells: [
          Text(
            entry.key,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${entry.value.length}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          Text(
            '$units · reported synthetic units',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          Text(
            '$demoConfirmed · demo only',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(
          'Hospital-wise reported listings',
          'This summary follows the selected filters. Aggregated units remain synthetic reports—not confirmed stock or a transfer recommendation.',
        ),
        const SizedBox(height: 12),
        AppDataTable(
          columns: const [
            AppTableColumn(title: 'Fictional institution', width: 330),
            AppTableColumn(title: 'Matching listings', width: 160),
            AppTableColumn(title: 'Reported quantity', width: 250),
            AppTableColumn(title: 'Demo-confirmed listings', width: 220),
          ],
          rows: rows,
          emptyMessage: 'No hospitals match the selected inventory filters.',
          totalRecords: rows.length,
        ),
      ],
    );
  }

  Widget _buildRequestForm() {
    return Column(
      key: _requestSectionKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(
          'Create a synthetic blood enquiry',
          'Records a local demo request and creates a simulated notification in the matching fictional institution inbox. Nothing is sent externally.',
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _requestFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final fieldWidth = constraints.maxWidth < 500
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 14) / 2;
                    return Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        SizedBox(
                          width: fieldWidth,
                          child: _requestDropdown<String>(
                            key: const Key('blood-request-hospital'),
                            label: 'Requesting hospital',
                            value: _requestingHospital,
                            options: SyntheticBloodBankData.hospitals,
                            optionLabel: (value) => value,
                            onChanged: (value) => setState(
                              () => _requestingHospital =
                                  value ?? _requestingHospital,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: _requestDropdown<String>(
                            key: const Key('blood-request-group'),
                            label: 'Blood group',
                            value: _requestBloodGroup,
                            options: SyntheticBloodBankData.bloodGroups,
                            optionLabel: (value) => value,
                            onChanged: (value) => setState(
                              () => _requestBloodGroup =
                                  value ?? _requestBloodGroup,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: _requestDropdown<DemoBloodComponent>(
                            key: const Key('blood-request-component'),
                            label: 'Component type',
                            value: _requestComponent,
                            options: DemoBloodComponent.values,
                            optionLabel: (value) => value.label,
                            onChanged: (value) => setState(
                              () => _requestComponent =
                                  value ?? _requestComponent,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: TextFormField(
                            key: const Key('blood-request-quantity'),
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Required quantity (demo units)',
                            ),
                            validator: (value) {
                              final quantity = int.tryParse(
                                value?.trim() ?? '',
                              );
                              if (quantity == null || quantity <= 0) {
                                return 'Enter a whole number greater than zero';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: _requestDropdown<DemoBloodUrgency>(
                            key: const Key('blood-request-urgency'),
                            label: 'Administrative urgency',
                            value: _requestUrgency,
                            options: DemoBloodUrgency.values,
                            optionLabel: (value) => value.label,
                            onChanged: (value) => setState(
                              () => _requestUrgency = value ?? _requestUrgency,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: TextFormField(
                            key: const Key('blood-request-coordinator'),
                            controller: _coordinatorController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Contact coordinator',
                            ),
                            validator: (value) =>
                                (value?.trim().isEmpty ?? true)
                                ? 'Enter a coordinator name'
                                : null,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                const Text(
                  'Urgency is a requester-provided administrative field only; it does not provide clinical triage or compatibility guidance.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
                if (_formError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _formError!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppButton(
                    key: const Key('blood-submit-request'),
                    label: 'Create demo enquiry',
                    icon: Icons.send_outlined,
                    onPressed: _submitRequest,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentRequests() {
    final requests = [..._requests]
      ..sort((a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(
          'Recent requests & status tracking',
          'All rows are fictional demo enquiries. Status changes do not represent a response, reservation, issue, or transfusion.',
        ),
        const SizedBox(height: 12),
        AppDataTable(
          columns: const [
            AppTableColumn(title: 'Request ID', width: 190),
            AppTableColumn(title: 'Requesting hospital', width: 260),
            AppTableColumn(title: 'Requested item', width: 250),
            AppTableColumn(title: 'Quantity', width: 120),
            AppTableColumn(title: 'Urgency', width: 130),
            AppTableColumn(title: 'Contact coordinator', width: 190),
            AppTableColumn(title: 'Request status', width: 230),
            AppTableColumn(title: 'Last updated', width: 180),
          ],
          rows: requests.map((request) {
            return AppTableRow(
              cells: [
                Text(
                  request.requestId,
                  style: const TextStyle(
                    color: AppColors.accentPrimary,
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  request.requestingHospital,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '${request.bloodGroup} · ${request.component.label}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '${request.requiredQuantity} demo units',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                AppStatusBadge(
                  label: request.urgency.label,
                  variant: _urgencyVariant(request.urgency),
                  showDot: false,
                ),
                Text(
                  request.contactCoordinator,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                AppStatusBadge(
                  label: request.status.label,
                  variant: _requestStatusVariant(request.status),
                  showDot: false,
                ),
                Text(
                  _formatDateTime(request.lastUpdatedAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            );
          }).toList(),
          emptyMessage: 'No synthetic requests have been recorded.',
          totalRecords: requests.length,
        ),
      ],
    );
  }

  StatusBadgeVariant _urgencyVariant(DemoBloodUrgency urgency) {
    return switch (urgency) {
      DemoBloodUrgency.routine => StatusBadgeVariant.neutral,
      DemoBloodUrgency.urgent => StatusBadgeVariant.warning,
      DemoBloodUrgency.emergency => StatusBadgeVariant.critical,
    };
  }

  StatusBadgeVariant _requestStatusVariant(DemoBloodRequestStatus status) {
    return switch (status) {
      DemoBloodRequestStatus.enquiryLogged => StatusBadgeVariant.info,
      DemoBloodRequestStatus.awaitingDemoResponse => StatusBadgeVariant.warning,
      DemoBloodRequestStatus.syntheticResponse => StatusBadgeVariant.success,
      DemoBloodRequestStatus.closedForDemo => StatusBadgeVariant.neutral,
    };
  }

  Widget _buildNotifications() {
    final notifications = _notifications.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(
          'Simulated hospital notifications',
          'Local demo inbox events only. No email, SMS, hospital system, or external service is contacted.',
        ),
        const SizedBox(height: 12),
        if (notifications.isEmpty)
          const GlassCard(
            child: Text(
              'No simulated blood enquiries yet.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          )
        else
          ...notifications.map(
            (notification) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.notifications_active_outlined,
                      color: AppColors.accentSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Demo inbox · ${notification.hospital} · ${notification.requestId}',
                            style: const TextStyle(
                              color: AppColors.accentSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.detail,
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
                      _formatDateTime(notification.occurredAt),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
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

  Widget _filterDropdown<T>({
    Key? key,
    required String label,
    required T? value,
    required List<T> options,
    required String Function(T value) optionLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T?>(
      key: key,
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        DropdownMenuItem<T?>(
          value: null,
          child: Text('All $label', overflow: TextOverflow.ellipsis),
        ),
        ...options.map(
          (option) => DropdownMenuItem<T?>(
            value: option,
            child: Text(optionLabel(option), overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }

  Widget _requestDropdown<T>({
    Key? key,
    required String label,
    required T value,
    required List<T> options,
    required String Function(T value) optionLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      key: key,
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: options
          .map(
            (option) => DropdownMenuItem<T>(
              value: option,
              child: Text(optionLabel(option), overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (selection) => selection == null ? 'Select $label' : null,
    );
  }
}
