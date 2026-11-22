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

class _BedEnquiry {
  final String reference;
  final String hospital;
  final DemoBedCategory category;
  final String transferReference;
  final DemoBedUrgency urgency;
  final String coordinator;
  final DateTime lastUpdatedAt;
  final String status;

  const _BedEnquiry({
    required this.reference,
    required this.hospital,
    required this.category,
    required this.transferReference,
    required this.urgency,
    required this.coordinator,
    required this.lastUpdatedAt,
    required this.status,
  });
}

class _BedNotification {
  final String hospital;
  final String enquiryReference;
  final String message;
  final DateTime occurredAt;

  const _BedNotification({
    required this.hospital,
    required this.enquiryReference,
    required this.message,
    required this.occurredAt,
  });
}

class IcuBedsScreen extends StatefulWidget {
  const IcuBedsScreen({super.key});

  @override
  State<IcuBedsScreen> createState() => _IcuBedsScreenState();
}

class _IcuBedsScreenState extends State<IcuBedsScreen> {
  static const _pageSize = 8;

  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _transferReferenceController = TextEditingController();
  final _coordinatorController = TextEditingController();
  final _enquiries = <_BedEnquiry>[];
  final _notifications = <_BedNotification>[];

  String _searchQuery = '';
  String _selectedLocation = 'All demo locations';
  DemoBedCategory? _selectedCategory;
  DemoResourceVerification? _selectedVerification;
  String _requestHospital = SyntheticResourceData.hospitals.first.name;
  DemoBedCategory _requestCategory = DemoBedCategory.icu;
  DemoBedUrgency _requestUrgency = DemoBedUrgency.routine;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _transferReferenceController.text = _newTransferReference();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _transferReferenceController.dispose();
    _coordinatorController.dispose();
    super.dispose();
  }

  String _newTransferReference() =>
      'DEMO-TRANSFER-${DateTime.now().microsecondsSinceEpoch}';

  String _formatDateTime(DateTime value) =>
      DateFormat('MMM d, yyyy · HH:mm').format(value);

  List<DemoBedListing> get _filteredBeds {
    final query = _searchQuery.trim().toLowerCase();
    final results =
        SyntheticResourceData.bedListings.where((listing) {
          if (_selectedLocation != 'All demo locations' &&
              listing.location != _selectedLocation) {
            return false;
          }
          if (_selectedCategory != null &&
              listing.category != _selectedCategory) {
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
            listing.category.label,
            listing.verification.label,
          ].any((value) => value.toLowerCase().contains(query));
        }).toList()..sort((a, b) {
          final hospitalOrder = a.hospital.compareTo(b.hospital);
          if (hospitalOrder != 0) return hospitalOrder;
          return a.category.index.compareTo(b.category.index);
        });
    return results;
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedLocation = 'All demo locations';
      _selectedCategory = null;
      _selectedVerification = null;
      _currentPage = 1;
    });
  }

  void _createEnquiry() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final now = DateTime.now();
    final reference = 'DEMO-BED-${now.microsecondsSinceEpoch}';
    final transferReference = _transferReferenceController.text.trim();
    final enquiry = _BedEnquiry(
      reference: reference,
      hospital: _requestHospital,
      category: _requestCategory,
      transferReference: transferReference,
      urgency: _requestUrgency,
      coordinator: _coordinatorController.text.trim(),
      lastUpdatedAt: now,
      status: 'Enquiry logged · demo',
    );
    setState(() {
      _enquiries.insert(0, enquiry);
      _notifications.insert(
        0,
        _BedNotification(
          hospital: _requestHospital,
          enquiryReference: reference,
          message:
              'Synthetic ${_requestCategory.label} enquiry received in the local demo inbox. No admission or transfer is confirmed.',
          occurredAt: now,
        ),
      );
      _transferReferenceController.text = _newTransferReference();
      _coordinatorController.clear();
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Synthetic bed enquiry recorded locally. No hospital was contacted.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final beds = _filteredBeds;
    final pageCount = (beds.length / _pageSize).ceil().clamp(1, 999);
    final page = _currentPage.clamp(1, pageCount);
    final pageItems = beds.skip((page - 1) * _pageSize).take(_pageSize);
    final icuBeds = SyntheticResourceData.bedListings
        .where((bed) => bed.category == DemoBedCategory.icu)
        .fold<int>(0, (total, bed) => total + bed.reportedOpenBeds);
    final generalBeds = SyntheticResourceData.bedListings
        .where((bed) => bed.category == DemoBedCategory.general)
        .fold<int>(0, (total, bed) => total + bed.reportedOpenBeds);
    final emergencyBeds = SyntheticResourceData.bedListings
        .where((bed) => bed.category == DemoBedCategory.emergency)
        .fold<int>(0, (total, bed) => total + bed.reportedOpenBeds);

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
                const ResourceModuleSwitcher(equipmentSelected: false),
                const SizedBox(height: 20),
                _buildOverview(
                  icuBeds: icuBeds,
                  generalBeds: generalBeds,
                  emergencyBeds: emergencyBeds,
                ),
                const SizedBox(height: 24),
                _buildDiscovery(beds, pageItems, page, pageCount),
                const SizedBox(height: 24),
                _buildHospitalCapacity(beds),
                const SizedBox(height: 24),
                _buildEnquiryForm(),
                const SizedBox(height: 24),
                _buildEnquiryTracking(),
                const SizedBox(height: 24),
                _buildNotifications(),
                const SizedBox(height: 18),
                const Center(
                  child: Text(
                    'Synthetic demo environment · Confirm every bed indicator with the institution before acting.',
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
          'ICU & Emergency Beds',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Hospital capacity indicators and secure, human-reviewed enquiries.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 9),
        const AppStatusBadge(
          label: 'SYNTHETIC CAPACITY · NOT ADMISSION CONFIRMATION',
          variant: StatusBadgeVariant.info,
          showDot: false,
        ),
      ],
    );
  }

  Widget _buildOverview({
    required int icuBeds,
    required int generalBeds,
    required int emergencyBeds,
  }) {
    final cards = [
      _capacityCard(
        'ICU bed indicators',
        icuBeds,
        Icons.monitor_heart_outlined,
        AppColors.accentPrimary,
      ),
      _capacityCard(
        'General bed indicators',
        generalBeds,
        Icons.hotel_outlined,
        AppColors.accentSecondary,
      ),
      _capacityCard(
        'Emergency bed indicators',
        emergencyBeds,
        Icons.emergency_outlined,
        AppColors.warning,
      ),
      AppStatCard(
        title: 'Synthetic hospitals',
        value: '${SyntheticResourceData.hospitals.length}',
        subtitle: 'Fictional institutions',
        icon: Icons.local_hospital_outlined,
        accentColor: AppColors.aiPurple,
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

  AppStatCard _capacityCard(
    String title,
    int total,
    IconData icon,
    Color color,
  ) {
    return AppStatCard(
      title: title,
      value: '$total',
      subtitle: 'Reported open · synthetic only',
      icon: icon,
      accentColor: color,
    );
  }

  Widget _buildDiscovery(
    List<DemoBedListing> beds,
    Iterable<DemoBedListing> pageItems,
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
          searchKey: 'bed-resource-search',
          searchHint: 'Hospital, care category...',
          selectedLocation: _selectedLocation,
          locations: SyntheticResourceData.locations,
          onLocationChanged: (value) => setState(() {
            _selectedLocation = value ?? 'All demo locations';
            _currentPage = 1;
          }),
          additionalFilters: [
            SizedBox(
              width: 240,
              child: _filterDropdown<DemoBedCategory>(
                key: const Key('bed-care-filter'),
                label: 'Required care category',
                selected: _selectedCategory,
                options: DemoBedCategory.values,
                optionLabel: (value) => value.label,
                onChanged: (value) => setState(() {
                  _selectedCategory = value;
                  _currentPage = 1;
                }),
              ),
            ),
            SizedBox(
              width: 240,
              child: _filterDropdown<DemoResourceVerification>(
                key: const Key('bed-verification-filter'),
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
          ],
          onReset: _resetFilters,
        ),
        const SizedBox(height: 12),
        _sectionTitle(
          'Bed availability indicators',
          'Reported open counts are not admission offers or guarantees. Last-updated and institution verification labels are shown for every synthetic listing.',
        ),
        const SizedBox(height: 10),
        AppDataTable(
          columns: const [
            AppTableColumn(title: 'Hospital', width: 270),
            AppTableColumn(title: 'Location', width: 210),
            AppTableColumn(title: 'Care category', width: 150),
            AppTableColumn(title: 'Reported open / capacity', width: 210),
            AppTableColumn(title: 'Last updated', width: 190),
            AppTableColumn(title: 'Institution status', width: 210),
          ],
          rows: pageItems.map((bed) {
            return AppTableRow(
              cells: [
                Text(
                  bed.hospital,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  bed.location,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                Text(
                  bed.category.label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '${bed.reportedOpenBeds} reported / ${bed.totalCapacity} beds',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  _formatDateTime(bed.lastUpdatedAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                AppStatusBadge(
                  label: bed.verification.label,
                  variant: _verificationVariant(bed.verification),
                  showDot: false,
                ),
              ],
            );
          }).toList(),
          emptyMessage: 'No synthetic bed indicators match these filters.',
          currentPage: page,
          totalPages: pageCount,
          totalRecords: beds.length,
          onPageChanged: (value) => setState(() => _currentPage = value),
        ),
      ],
    );
  }

  Widget _buildHospitalCapacity(List<DemoBedListing> filteredBeds) {
    final byHospital = <String, List<DemoBedListing>>{};
    for (final bed in filteredBeds) {
      byHospital.putIfAbsent(bed.hospital, () => []).add(bed);
    }
    final rows = byHospital.entries.map((entry) {
      String categoryCapacity(DemoBedCategory category) {
        final beds = entry.value.where((bed) => bed.category == category);
        if (beds.isEmpty) return '—';
        final bed = beds.first;
        return '${bed.reportedOpenBeds} / ${bed.totalCapacity} reported';
      }

      final lastUpdated = entry.value
          .map((bed) => bed.lastUpdatedAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      return AppTableRow(
        cells: [
          Text(
            entry.key,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
          ),
          Text(
            entry.value.first.location,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          Text(
            categoryCapacity(DemoBedCategory.icu),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          Text(
            categoryCapacity(DemoBedCategory.general),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          Text(
            categoryCapacity(DemoBedCategory.emergency),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          Text(
            _formatDateTime(lastUpdated),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(
          'Hospital-wise capacity',
          'Aggregated reported counts reflect the common search filters and are not confirmed placements.',
        ),
        const SizedBox(height: 10),
        AppDataTable(
          columns: const [
            AppTableColumn(title: 'Synthetic hospital', width: 270),
            AppTableColumn(title: 'Location', width: 210),
            AppTableColumn(title: 'ICU open / total', width: 190),
            AppTableColumn(title: 'General open / total', width: 200),
            AppTableColumn(title: 'Emergency open / total', width: 210),
            AppTableColumn(title: 'Updated', width: 190),
          ],
          rows: rows,
          emptyMessage: 'No hospital capacity matches the selected filters.',
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
          'Create a bed enquiry',
          'A local, synthetic enquiry only. It does not confirm admission, suitability, transport, or transfer.',
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
                    return Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        SizedBox(
                          width: fieldWidth,
                          child: _requestDropdown<String>(
                            key: const Key('bed-request-hospital'),
                            label: 'Hospital',
                            value: _requestHospital,
                            options: SyntheticResourceData.hospitals
                                .map((hospital) => hospital.name)
                                .toList(),
                            optionLabel: (value) => value,
                            onChanged: (value) => setState(
                              () =>
                                  _requestHospital = value ?? _requestHospital,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: _requestDropdown<DemoBedCategory>(
                            key: const Key('bed-request-category'),
                            label: 'Required care category',
                            value: _requestCategory,
                            options: DemoBedCategory.values,
                            optionLabel: (value) => value.label,
                            onChanged: (value) => setState(
                              () =>
                                  _requestCategory = value ?? _requestCategory,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: TextFormField(
                            key: const Key('bed-transfer-reference'),
                            controller: _transferReferenceController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText:
                                  'Patient transfer reference (synthetic)',
                            ),
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: _requestDropdown<DemoBedUrgency>(
                            key: const Key('bed-request-urgency'),
                            label: 'Administrative urgency',
                            value: _requestUrgency,
                            options: DemoBedUrgency.values,
                            optionLabel: (value) => value.label,
                            onChanged: (value) => setState(
                              () => _requestUrgency = value ?? _requestUrgency,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: TextFormField(
                            key: const Key('bed-request-coordinator'),
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
                const SizedBox(height: 9),
                const Text(
                  'Do not enter patient names or other identifying health information. The generated reference is synthetic.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppButton(
                    key: const Key('bed-submit-enquiry'),
                    label: 'Create synthetic bed enquiry',
                    icon: Icons.send_outlined,
                    onPressed: _createEnquiry,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(
          'Recent bed enquiries',
          'Track local demonstration workflow status. No enquiry has been delivered to an actual hospital.',
        ),
        const SizedBox(height: 10),
        AppDataTable(
          columns: const [
            AppTableColumn(title: 'Enquiry reference', width: 210),
            AppTableColumn(title: 'Hospital', width: 270),
            AppTableColumn(title: 'Care category', width: 160),
            AppTableColumn(title: 'Transfer reference', width: 260),
            AppTableColumn(title: 'Urgency', width: 130),
            AppTableColumn(title: 'Coordinator', width: 190),
            AppTableColumn(title: 'Status', width: 180),
            AppTableColumn(title: 'Last updated', width: 190),
          ],
          rows: _enquiries.map((enquiry) {
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
                  enquiry.hospital,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 10,
                  ),
                ),
                Text(
                  enquiry.category.label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                Text(
                  enquiry.transferReference,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
                AppStatusBadge(
                  label: enquiry.urgency.label,
                  variant: switch (enquiry.urgency) {
                    DemoBedUrgency.routine => StatusBadgeVariant.neutral,
                    DemoBedUrgency.urgent => StatusBadgeVariant.warning,
                    DemoBedUrgency.emergency => StatusBadgeVariant.critical,
                  },
                  showDot: false,
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
          emptyMessage:
              'No bed enquiries yet. New enquiries remain synthetic and local.',
          totalRecords: _enquiries.length,
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
          'Notifications appear only in this prototype’s local demo inbox.',
        ),
        const SizedBox(height: 10),
        if (_notifications.isEmpty)
          const GlassCard(
            child: Text(
              'No simulated notifications.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          )
        else
          ..._notifications
              .take(4)
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
                                '${notification.enquiryReference} · ${notification.message}',
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
        DropdownMenuItem<T?>(value: null, child: Text('All categories')),
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
