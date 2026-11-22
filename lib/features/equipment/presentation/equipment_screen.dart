import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_data_table.dart';
import '../../../core/widgets/app_stat_card.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../core/widgets/glass_card.dart';
import '../../resource_discovery/data/synthetic_resource_data.dart';
import '../../resource_discovery/presentation/resource_discovery_widgets.dart';

enum _EquipmentSort {
  newest('Most recently updated'),
  oldest('Least recently updated'),
  equipmentId('Equipment ID'),
  hospital('Hospital A–Z');

  const _EquipmentSort(this.label);

  final String label;
}

class _EquipmentEnquiry {
  final String reference;
  final String requestingHospital;
  final String destinationHospital;
  final DemoEquipmentCategory category;
  final String equipmentId;
  final int quantity;
  final String coordinator;
  final DateTime lastUpdatedAt;
  final String status;

  const _EquipmentEnquiry({
    required this.reference,
    required this.requestingHospital,
    required this.destinationHospital,
    required this.category,
    required this.equipmentId,
    required this.quantity,
    required this.coordinator,
    required this.lastUpdatedAt,
    required this.status,
  });
}

class _EquipmentNotification {
  final String hospital;
  final String enquiryReference;
  final String detail;
  final DateTime occurredAt;

  const _EquipmentNotification({
    required this.hospital,
    required this.enquiryReference,
    required this.detail,
    required this.occurredAt,
  });
}

class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  static const _pageSize = 10;

  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _coordinatorController = TextEditingController();
  final _enquiries = <_EquipmentEnquiry>[];
  final _notifications = <_EquipmentNotification>[];

  String _searchQuery = '';
  String _selectedLocation = 'All demo locations';
  DemoEquipmentCategory? _selectedCategory;
  DemoEquipmentStatus? _selectedStatus;
  DemoResourceVerification? _selectedVerification;
  _EquipmentSort _sort = _EquipmentSort.newest;
  String _requestingHospital = SyntheticResourceData.hospitals.first.name;
  String _destinationHospital = 'Any matching demo hospital';
  DemoEquipmentCategory _requestCategory = DemoEquipmentCategory.ventilators;
  String _equipmentId = 'Any equipment in category';
  int _currentPage = 1;

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    _coordinatorController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime value) =>
      DateFormat('MMM d, yyyy · HH:mm').format(value);

  List<DemoEquipmentRecord> get _filteredEquipment {
    final query = _searchQuery.trim().toLowerCase();
    final results = SyntheticResourceData.equipmentRecords.where((item) {
      if (_selectedLocation != 'All demo locations' &&
          item.location != _selectedLocation) {
        return false;
      }
      if (_selectedCategory != null && item.category != _selectedCategory) {
        return false;
      }
      if (_selectedStatus != null && item.status != _selectedStatus) {
        return false;
      }
      if (_selectedVerification != null &&
          item.verification != _selectedVerification) {
        return false;
      }
      if (query.isEmpty) return true;
      return [
        item.equipmentId,
        item.hospital,
        item.location,
        item.category.label,
        item.status.label,
        item.verification.label,
      ].any((value) => value.toLowerCase().contains(query));
    }).toList();

    switch (_sort) {
      case _EquipmentSort.newest:
        results.sort((a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt));
      case _EquipmentSort.oldest:
        results.sort((a, b) => a.lastUpdatedAt.compareTo(b.lastUpdatedAt));
      case _EquipmentSort.equipmentId:
        results.sort((a, b) => a.equipmentId.compareTo(b.equipmentId));
      case _EquipmentSort.hospital:
        results.sort((a, b) => a.hospital.compareTo(b.hospital));
    }
    return results;
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedLocation = 'All demo locations';
      _selectedCategory = null;
      _selectedStatus = null;
      _selectedVerification = null;
      _sort = _EquipmentSort.newest;
      _currentPage = 1;
    });
  }

  void _submitEnquiry() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final now = DateTime.now();
    final reference = 'DEMO-EQ-REQ-${now.microsecondsSinceEpoch}';
    final quantity = int.parse(_quantityController.text.trim());
    final matchingHospitals =
        _destinationHospital == 'Any matching demo hospital'
        ? SyntheticResourceData.equipmentRecords
              .where((item) => item.category == _requestCategory)
              .map((item) => item.hospital)
              .toSet()
        : {_destinationHospital};
    final destinations = matchingHospitals.toList()..sort();
    final enquiry = _EquipmentEnquiry(
      reference: reference,
      requestingHospital: _requestingHospital,
      destinationHospital: destinations.join(', '),
      category: _requestCategory,
      equipmentId: _equipmentId,
      quantity: quantity,
      coordinator: _coordinatorController.text.trim(),
      lastUpdatedAt: now,
      status: 'Enquiry logged · demo',
    );
    setState(() {
      _enquiries.insert(0, enquiry);
      _notifications.insertAll(
        0,
        destinations.map(
          (hospital) => _EquipmentNotification(
            hospital: hospital,
            enquiryReference: reference,
            detail:
                'Synthetic ${_requestCategory.label.toLowerCase()} enquiry received in the local demo inbox for $quantity requested units. No external message was sent.',
            occurredAt: now,
          ),
        ),
      );
      _quantityController.text = '1';
      _coordinatorController.clear();
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Synthetic equipment enquiry created locally. No hospital was contacted.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final equipment = _filteredEquipment;
    final pageCount = (equipment.length / _pageSize).ceil().clamp(1, 999);
    final page = _currentPage.clamp(1, pageCount);
    final pageItems = equipment.skip((page - 1) * _pageSize).take(_pageSize);
    final available = SyntheticResourceData.equipmentRecords
        .where((item) => item.status == DemoEquipmentStatus.available)
        .length;
    final inUse = SyntheticResourceData.equipmentRecords
        .where((item) => item.status == DemoEquipmentStatus.inUse)
        .length;
    final maintenance = SyntheticResourceData.equipmentRecords
        .where((item) => item.status == DemoEquipmentStatus.underMaintenance)
        .length;
    final confirmation = SyntheticResourceData.equipmentRecords
        .where(
          (item) => item.status == DemoEquipmentStatus.requiresConfirmation,
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
                const ResourceSafetyBanner(),
                const SizedBox(height: 16),
                _buildHeader(),
                const SizedBox(height: 14),
                const ResourceModuleSwitcher(equipmentSelected: true),
                const SizedBox(height: 20),
                _buildOverview(
                  available: available,
                  inUse: inUse,
                  maintenance: maintenance,
                  confirmation: confirmation,
                ),
                const SizedBox(height: 24),
                _buildDiscovery(equipment, pageItems, page, pageCount),
                const SizedBox(height: 24),
                _buildHospitalSummary(equipment),
                const SizedBox(height: 24),
                _buildEnquiryForm(),
                const SizedBox(height: 24),
                _buildEnquiryTracking(),
                const SizedBox(height: 24),
                _buildNotifications(),
                const SizedBox(height: 18),
                const Center(
                  child: Text(
                    'Synthetic demo environment · Verify status, quantity, suitability and transfer directly with the institution.',
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Medical Equipment Network',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Synthetic equipment reports and institutional enquiry workflow.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 9),
        const AppStatusBadge(
          label: 'SYNTHETIC EQUIPMENT RECORDS · NOT LIVE TELEMETRY',
          variant: StatusBadgeVariant.info,
          showDot: false,
        ),
      ],
    );
  }

  Widget _buildOverview({
    required int available,
    required int inUse,
    required int maintenance,
    required int confirmation,
  }) {
    final cards = [
      _statusCard(
        'Reported available',
        available,
        Icons.check_circle_outline_rounded,
        AppColors.success,
      ),
      _statusCard(
        'In use',
        inUse,
        Icons.sync_rounded,
        AppColors.accentSecondary,
      ),
      _statusCard(
        'Under maintenance',
        maintenance,
        Icons.build_circle_outlined,
        AppColors.warning,
      ),
      _statusCard(
        'Requires confirmation',
        confirmation,
        Icons.help_outline_rounded,
        AppColors.danger,
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
          childAspectRatio: columns == 1 ? 2 : 1.45,
          children: cards,
        );
      },
    );
  }

  AppStatCard _statusCard(String title, int total, IconData icon, Color color) {
    return AppStatCard(
      title: title,
      value: '$total',
      subtitle: 'Synthetic records only',
      icon: icon,
      accentColor: color,
    );
  }

  Widget _buildDiscovery(
    List<DemoEquipmentRecord> equipment,
    Iterable<DemoEquipmentRecord> pageItems,
    int page,
    int pageCount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResourceDiscoveryToolbar(
          searchController: _searchController,
          onSearchChanged: (value) => setState(() {
            _searchQuery = value;
            _currentPage = 1;
          }),
          searchKey: 'equipment-resource-search',
          searchHint: 'ID, hospital, category, status...',
          selectedLocation: _selectedLocation,
          locations: SyntheticResourceData.locations,
          onLocationChanged: (value) => setState(() {
            _selectedLocation = value ?? 'All demo locations';
            _currentPage = 1;
          }),
          additionalFilters: [
            SizedBox(
              width: 240,
              child: _filterDropdown<DemoEquipmentCategory>(
                key: const Key('equipment-category-filter'),
                label: 'Equipment category',
                selected: _selectedCategory,
                options: DemoEquipmentCategory.values,
                optionLabel: (value) => value.label,
                onChanged: (value) => setState(() {
                  _selectedCategory = value;
                  _currentPage = 1;
                }),
              ),
            ),
            SizedBox(
              width: 240,
              child: _filterDropdown<DemoEquipmentStatus>(
                key: const Key('equipment-status-filter'),
                label: 'Availability status',
                selected: _selectedStatus,
                options: DemoEquipmentStatus.values,
                optionLabel: (value) => value.label,
                onChanged: (value) => setState(() {
                  _selectedStatus = value;
                  _currentPage = 1;
                }),
              ),
            ),
            SizedBox(
              width: 240,
              child: _filterDropdown<DemoResourceVerification>(
                key: const Key('equipment-verification-filter'),
                label: 'Verification',
                selected: _selectedVerification,
                options: DemoResourceVerification.values,
                optionLabel: (value) => value.label,
                onChanged: (value) => setState(() {
                  _selectedVerification = value;
                  _currentPage = 1;
                }),
              ),
            ),
            SizedBox(
              width: 240,
              child: DropdownButtonFormField<_EquipmentSort>(
                key: const Key('equipment-sort-filter'),
                initialValue: _sort,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Sort by'),
                items: _EquipmentSort.values
                    .map(
                      (sort) => DropdownMenuItem(
                        value: sort,
                        child: Text(
                          sort.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _sort = value;
                    _currentPage = 1;
                  });
                },
              ),
            ),
          ],
          onReset: _resetFilters,
        ),
        const SizedBox(height: 12),
        _sectionTitle(
          'Equipment availability indications',
          'Status and quantity are synthetic reports. “Available” is not a reservation or suitability confirmation.',
        ),
        const SizedBox(height: 10),
        AppDataTable(
          columns: const [
            AppTableColumn(title: 'Equipment ID', width: 150),
            AppTableColumn(title: 'Hospital', width: 270),
            AppTableColumn(title: 'Location', width: 210),
            AppTableColumn(title: 'Category', width: 230),
            AppTableColumn(title: 'Availability status', width: 210),
            AppTableColumn(title: 'Quantity · synthetic', width: 170),
            AppTableColumn(title: 'Last updated', width: 190),
            AppTableColumn(title: 'Verification', width: 200),
          ],
          rows: pageItems.map((record) {
            return AppTableRow(
              cells: [
                Text(
                  record.equipmentId,
                  style: const TextStyle(
                    color: AppColors.accentPrimary,
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  record.hospital,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 10,
                  ),
                ),
                Text(
                  record.location,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                Text(
                  record.category.label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 10,
                  ),
                ),
                AppStatusBadge(
                  label: record.status.label,
                  variant: _equipmentStatusVariant(record.status),
                  showDot: false,
                ),
                Text(
                  '${record.quantity} listed',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                Text(
                  _formatDateTime(record.lastUpdatedAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                AppStatusBadge(
                  label: record.verification.label,
                  variant: _verificationVariant(record.verification),
                  showDot: false,
                ),
              ],
            );
          }).toList(),
          emptyMessage: 'No synthetic equipment matches these filters.',
          currentPage: page,
          totalPages: pageCount,
          totalRecords: equipment.length,
          onPageChanged: (value) => setState(() => _currentPage = value),
        ),
      ],
    );
  }

  Widget _buildHospitalSummary(List<DemoEquipmentRecord> filtered) {
    final byHospital = <String, List<DemoEquipmentRecord>>{};
    for (final record in filtered) {
      byHospital.putIfAbsent(record.hospital, () => []).add(record);
    }
    final rows = byHospital.entries.map((entry) {
      final quantities = entry.value.fold<int>(
        0,
        (total, record) => total + record.quantity,
      );
      final needsConfirmation = entry.value
          .where(
            (record) =>
                record.status == DemoEquipmentStatus.requiresConfirmation,
          )
          .length;
      return AppTableRow(
        cells: [
          Text(
            entry.key,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 10),
          ),
          Text(
            entry.value.length.toString(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          Text(
            '$quantities listed units · synthetic',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          Text(
            '$needsConfirmation require status confirmation',
            style: const TextStyle(color: AppColors.warning, fontSize: 10),
          ),
        ],
      );
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(
          'Hospital-wise equipment listings',
          'Summary reflects the active discovery filters. Quantities are not confirmed inventory.',
        ),
        const SizedBox(height: 10),
        AppDataTable(
          columns: const [
            AppTableColumn(title: 'Synthetic hospital', width: 300),
            AppTableColumn(title: 'Matching records', width: 170),
            AppTableColumn(title: 'Quantity listed', width: 240),
            AppTableColumn(title: 'Confirmation follow-up', width: 280),
          ],
          rows: rows,
          emptyMessage: 'No institutions match the selected equipment filters.',
          totalRecords: rows.length,
        ),
      ],
    );
  }

  Widget _buildEnquiryForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(
          'Create an equipment enquiry',
          'Creates a simulated notification in the selected fictional hospital inbox. No real equipment request is sent.',
        ),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final fieldWidth = constraints.maxWidth < 500
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 14) / 2;
                    final availableEquipmentIds = [
                      'Any equipment in category',
                      ...SyntheticResourceData.equipmentRecords
                          .where(
                            (record) =>
                                record.category == _requestCategory &&
                                (_destinationHospital ==
                                        'Any matching demo hospital' ||
                                    record.hospital == _destinationHospital),
                          )
                          .map((record) => record.equipmentId),
                    ];
                    return Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        SizedBox(
                          width: fieldWidth,
                          child: _requestDropdown<String>(
                            key: const Key('equipment-requesting-hospital'),
                            label: 'Requesting hospital',
                            value: _requestingHospital,
                            options: SyntheticResourceData.hospitals
                                .map((hospital) => hospital.name)
                                .toList(),
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
                            key: const Key('equipment-destination-hospital'),
                            label: 'Enquiry destination',
                            value: _destinationHospital,
                            options: [
                              'Any matching demo hospital',
                              ...SyntheticResourceData.hospitals.map(
                                (hospital) => hospital.name,
                              ),
                            ],
                            optionLabel: (value) => value,
                            onChanged: (value) => setState(() {
                              _destinationHospital =
                                  value ?? _destinationHospital;
                              _equipmentId = 'Any equipment in category';
                            }),
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: _requestDropdown<DemoEquipmentCategory>(
                            key: const Key('equipment-request-category'),
                            label: 'Equipment category',
                            value: _requestCategory,
                            options: DemoEquipmentCategory.values,
                            optionLabel: (value) => value.label,
                            onChanged: (value) => setState(() {
                              _requestCategory = value ?? _requestCategory;
                              _equipmentId = 'Any equipment in category';
                            }),
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: _requestDropdown<String>(
                            key: const Key('equipment-request-id'),
                            label: 'Equipment ID (optional)',
                            value: _equipmentId,
                            options: availableEquipmentIds,
                            optionLabel: (value) => value,
                            onChanged: (value) => setState(
                              () => _equipmentId = value ?? _equipmentId,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: TextFormField(
                            key: const Key('equipment-request-quantity'),
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Requested quantity (demo units)',
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
                          child: TextFormField(
                            key: const Key('equipment-request-coordinator'),
                            controller: _coordinatorController,
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
                  'An enquiry does not establish equipment availability, clinical suitability, or transfer approval.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppButton(
                    key: const Key('equipment-submit-enquiry'),
                    label: 'Create synthetic equipment enquiry',
                    icon: Icons.send_outlined,
                    onPressed: _submitEnquiry,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnquiryTracking() {
    final requests = [..._enquiries]
      ..sort((a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(
          'Recent equipment enquiries',
          'Local synthetic status tracking only; no fulfilment, reservation, or dispatch is implied.',
        ),
        const SizedBox(height: 10),
        AppDataTable(
          columns: const [
            AppTableColumn(title: 'Enquiry reference', width: 230),
            AppTableColumn(title: 'Requesting hospital', width: 280),
            AppTableColumn(title: 'Destination hospital', width: 420),
            AppTableColumn(title: 'Category / equipment', width: 260),
            AppTableColumn(title: 'Quantity', width: 120),
            AppTableColumn(title: 'Coordinator', width: 190),
            AppTableColumn(title: 'Status', width: 190),
            AppTableColumn(title: 'Last updated', width: 190),
          ],
          rows: requests.map((enquiry) {
            return AppTableRow(
              cells: [
                Text(
                  enquiry.reference,
                  style: const TextStyle(
                    color: AppColors.accentPrimary,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  enquiry.requestingHospital,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 10,
                  ),
                ),
                Text(
                  enquiry.destinationHospital,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                Text(
                  '${enquiry.category.label} · ${enquiry.equipmentId}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                Text(
                  '${enquiry.quantity} demo units',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                Text(
                  enquiry.coordinator,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                const AppStatusBadge(
                  label: 'Enquiry logged · demo',
                  variant: StatusBadgeVariant.info,
                  showDot: false,
                ),
                Text(
                  _formatDateTime(enquiry.lastUpdatedAt),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            );
          }).toList(),
          emptyMessage: 'No equipment enquiries yet. New enquiries remain synthetic and local.',
          totalRecords: requests.length,
        ),
      ],
    );
  }

  Widget _buildNotifications() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(
          'Simulated hospital notifications',
          'Notifications stay in the local prototype inbox; no SMS, email, or hospital system is contacted.',
        ),
        const SizedBox(height: 10),
        if (_notifications.isEmpty)
          const GlassCard(
            child: Text(
              'No simulated equipment enquiries.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          )
        else
          ..._notifications
              .take(5)
              .map(
                (notification) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
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
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Demo inbox · ${notification.hospital}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${notification.enquiryReference} · ${notification.detail}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDateTime(notification.occurredAt),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 9,
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

  StatusBadgeVariant _equipmentStatusVariant(DemoEquipmentStatus status) {
    return switch (status) {
      DemoEquipmentStatus.available => StatusBadgeVariant.success,
      DemoEquipmentStatus.inUse => StatusBadgeVariant.info,
      DemoEquipmentStatus.underMaintenance => StatusBadgeVariant.warning,
      DemoEquipmentStatus.requiresConfirmation => StatusBadgeVariant.neutral,
    };
  }

  StatusBadgeVariant _verificationVariant(
    DemoResourceVerification verification,
  ) {
    return switch (verification) {
      DemoResourceVerification.reported => StatusBadgeVariant.warning,
      DemoResourceVerification.awaitingConfirmation => StatusBadgeVariant.info,
      DemoResourceVerification.demoConfirmed => StatusBadgeVariant.success,
    };
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
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _filterDropdown<T>({
    Key? key,
    required String label,
    required T? selected,
    required List<T> options,
    required String Function(T value) optionLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T?>(
      key: key,
      initialValue: selected,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        DropdownMenuItem<T?>(value: null, child: Text('All statuses')),
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
      validator: (value) => value == null ? 'Select $label' : null,
    );
  }
}
