import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../core/widgets/glass_card.dart';
import '../data/synthetic_hospital_network_data.dart';

class HospitalsScreen extends StatefulWidget {
  final TileProvider? tileProvider;

  const HospitalsScreen({super.key, this.tileProvider});

  @override
  State<HospitalsScreen> createState() => _HospitalsScreenState();
}

class _HospitalsScreenState extends State<HospitalsScreen> {
  final _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedState = 'All states';
  String _selectedCity = 'All cities';
  String _selectedResource = 'All resource types';
  String _selectedHospitalId =
      SyntheticHospitalNetworkData.hospitals.first.institutionId;

  List<String> get _resourceTypes {
    return SyntheticHospitalNetworkData.hospitals
        .expand((hospital) => hospital.coordinationModules)
        .toSet()
        .toList()
      ..sort();
  }

  List<DemoHospital> get _filteredHospitals {
    final query = _searchQuery.trim().toLowerCase();
    return SyntheticHospitalNetworkData.hospitals.where((hospital) {
      if (_selectedState != 'All states' && hospital.state != _selectedState) {
        return false;
      }
      if (_selectedCity != 'All cities' && hospital.city != _selectedCity) {
        return false;
      }
      if (_selectedResource != 'All resource types' &&
          !hospital.supportsResource(_selectedResource)) {
        return false;
      }
      if (query.isEmpty) return true;
      return [
        hospital.name,
        hospital.institutionId,
        hospital.city,
        hospital.state,
        hospital.type.label,
        ...hospital.coordinationModules,
        ...hospital.capabilities,
      ].any((value) => value.toLowerCase().contains(query));
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime value) =>
      DateFormat('MMM d, yyyy · HH:mm').format(value);

  void _updateFilters(VoidCallback update) {
    setState(() {
      update();
      final matches = _filteredHospitals;
      if (matches.isNotEmpty &&
          !matches.any(
            (hospital) => hospital.institutionId == _selectedHospitalId,
          )) {
        _selectedHospitalId = matches.first.institutionId;
      }
    });
  }

  Future<void> _contactCoordinator(DemoHospital hospital) async {
    final shouldCreateEnquiry = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Contact institutional coordination desk'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hospital.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Coordinator contact details are not public in this prototype. An authorized user can prepare a local demo enquiry through the institutional channel.',
            ),
            const SizedBox(height: 10),
            const Text(
              'This action does not send a message or disclose private coordinator information.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Prepare demo enquiry'),
          ),
        ],
      ),
    );
    if (shouldCreateEnquiry != true || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Local demo enquiry prepared for ${hospital.name}. No contact was made.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final hospitals = _filteredHospitals;
    DemoHospital? selected;
    for (final hospital in hospitals) {
      if (hospital.institutionId == _selectedHospitalId) {
        selected = hospital;
        break;
      }
    }
    final states = ['All states', ...SyntheticHospitalNetworkData.states];
    final cities = [
      'All cities',
      ...SyntheticHospitalNetworkData.citiesForState(_selectedState),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(context.isDesktop ? 24 : 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDemoNotice(),
                const SizedBox(height: 18),
                _buildHeader(hospitals.length),
                const SizedBox(height: 16),
                _buildSearchAndFilters(states, cities),
                const SizedBox(height: 16),
                _buildMapAndDetails(context, hospitals, selected),
                const SizedBox(height: 14),
                _buildMarkerLegend(),
                const SizedBox(height: 16),
                _buildSearchResults(hospitals),
                const SizedBox(height: 18),
                const Center(
                  child: Text(
                    'Fictional hospital network · Map tiles © OpenStreetMap contributors · No live institutional connection',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoNotice() {
    return GlassCard(
      glowAccent: GlowAccent.warning,
      padding: const EdgeInsets.all(14),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.privacy_tip_outlined, color: AppColors.warning, size: 21),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Demonstration directory only. Every institution profile and marker is fictional; coordinates are illustrative city-level points and do not identify real hospitals. No patient information or private coordinator contacts are displayed.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int resultCount) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hospital Network',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Discover ${SyntheticHospitalNetworkData.hospitals.length} fictional institutions across ${SyntheticHospitalNetworkData.states.length} states and union territories.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        );
        final count = AppStatusBadge(
          label: '$resultCount MATCHING INSTITUTIONS',
          variant: StatusBadgeVariant.info,
          showDot: false,
        );
        if (constraints.maxWidth < 620) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 10), count],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: title),
            const SizedBox(width: 12),
            count,
          ],
        );
      },
    );
  }

  Widget _buildSearchAndFilters(List<String> states, List<String> cities) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth < 220
              ? constraints.maxWidth
              : 240.0;
          return Wrap(
            spacing: 10,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: width,
                child: TextField(
                  key: const Key('hospital-network-search'),
                  controller: _searchController,
                  onChanged: (value) =>
                      _updateFilters(() => _searchQuery = value),
                  decoration: const InputDecoration(
                    labelText: 'Search hospitals',
                    hintText: 'City, state, hospital, resource...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              SizedBox(
                width: width,
                child: _dropdown(
                  key: const Key('hospital-state-filter'),
                  label: 'State / union territory',
                  value: _selectedState,
                  options: states,
                  onChanged: (value) => _updateFilters(() {
                    _selectedState = value ?? 'All states';
                    _selectedCity = 'All cities';
                  }),
                ),
              ),
              SizedBox(
                width: width,
                child: _dropdown(
                  key: const Key('hospital-city-filter'),
                  label: 'City',
                  value: cities.contains(_selectedCity)
                      ? _selectedCity
                      : 'All cities',
                  options: cities,
                  onChanged: (value) => _updateFilters(
                    () => _selectedCity = value ?? 'All cities',
                  ),
                ),
              ),
              SizedBox(
                width: width,
                child: _dropdown(
                  key: const Key('hospital-resource-filter'),
                  label: 'Resource / coordination type',
                  value: _selectedResource,
                  options: ['All resource types', ..._resourceTypes],
                  onChanged: (value) => _updateFilters(
                    () => _selectedResource = value ?? 'All resource types',
                  ),
                ),
              ),
              AppButton(
                label: 'Clear filters',
                icon: Icons.filter_alt_off_rounded,
                variant: AppButtonVariant.ghost,
                onPressed: () {
                  _searchController.clear();
                  _updateFilters(() {
                    _searchQuery = '';
                    _selectedState = 'All states';
                    _selectedCity = 'All cities';
                    _selectedResource = 'All resource types';
                  });
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMapAndDetails(
    BuildContext context,
    List<DemoHospital> hospitals,
    DemoHospital? selected,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final map = _buildMap(hospitals);
        final panel = selected == null
            ? _emptyDetails()
            : _buildDetails(selected);

        if (constraints.maxWidth < 960) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 420, child: map),
              const SizedBox(height: 14),
              panel,
            ],
          );
        }
        return SizedBox(
          height: 620,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 6, child: map),
              const SizedBox(width: 14),
              Expanded(flex: 4, child: panel),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMap(List<DemoHospital> hospitals) {
    final mapMarkers = hospitals.map((hospital) {
      final isSelected = hospital.institutionId == _selectedHospitalId;
      final color = _markerColor(hospital.type);
      return Marker(
        point: hospital.coordinates,
        width: isSelected ? 56 : 46,
        height: isSelected ? 62 : 52,
        child: Tooltip(
          message: '${hospital.name}\n${hospital.locationLabel}',
          child: GestureDetector(
            key: Key('hospital-marker-${hospital.institutionId}'),
            onTap: () =>
                setState(() => _selectedHospitalId = hospital.institutionId),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: isSelected ? 42 : 34,
                  height: isSelected ? 42 : 34,
                  decoration: BoxDecoration(
                    color: color.withAlpha(isSelected ? 235 : 210),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.textPrimary
                          : Colors.white.withAlpha(190),
                      width: isSelected ? 2.5 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withAlpha(isSelected ? 150 : 90),
                        blurRadius: isSelected ? 16 : 9,
                        spreadRadius: isSelected ? 3 : 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    _markerIcon(hospital.type),
                    size: isSelected ? 21 : 18,
                    color: AppColors.bgPrimary,
                  ),
                ),
                Container(width: 2, height: 7, color: color),
              ],
            ),
          ),
        ),
      );
    }).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          FlutterMap(
            key: const Key('hospital-network-map'),
            options: const MapOptions(
              initialCenter: LatLng(22.8, 79.0),
              initialZoom: 4.3,
              minZoom: 3.5,
              maxZoom: 13,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.lifelink.ai',
                maxNativeZoom: 19,
                tileProvider: widget.tileProvider,
              ),
              MarkerLayer(markers: mapMarkers),
              RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                showFlutterMapAttribution: false,
                attributions: [
                  TextSourceAttribution(
                    '© OpenStreetMap contributors',
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.bgPrimary.withAlpha(225),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.public_rounded,
                      color: AppColors.accentPrimary,
                      size: 17,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'India · illustrative network',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (hospitals.isEmpty)
            Positioned.fill(
              child: ColoredBox(
                color: AppColors.bgPrimary.withAlpha(210),
                child: const Center(
                  child: Text(
                    'No fictional institutions match the selected filters.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetails(DemoHospital hospital) {
    return GlassCard(
      key: const Key('hospital-details-panel'),
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _markerColor(hospital.type).withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _markerColor(hospital.type).withAlpha(110),
                      ),
                    ),
                    child: Icon(
                      _markerIcon(hospital.type),
                      color: _markerColor(hospital.type),
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hospital.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AppStatusBadge(
                          label: hospital.verification.label,
                          variant: _verificationVariant(hospital.verification),
                          showDot: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _profileField('Institution ID', hospital.institutionId),
              _profileField('City / State', hospital.locationLabel),
              _profileField('Institution category', hospital.type.label),
              _profileField(
                'Last synchronized',
                _formatDateTime(hospital.lastSynchronizedAt),
              ),
              const SizedBox(height: 12),
              _panelHeading('Available coordination modules'),
              const SizedBox(height: 7),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: hospital.coordinationModules
                    .map(
                      (module) => AppStatusBadge(
                        label: module,
                        variant: StatusBadgeVariant.info,
                        showDot: false,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 15),
              _panelHeading('Institution capability details'),
              const SizedBox(height: 7),
              ...hospital.capabilities.map(
                (capability) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.accentPrimary,
                        size: 15,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          capability,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              AppButton(
                key: const Key('hospital-contact-coordinator'),
                label: 'Contact coordination desk',
                icon: Icons.mark_email_unread_outlined,
                isFullWidth: constraints.maxWidth < 360,
                onPressed: () => _contactCoordinator(hospital),
              ),
              const SizedBox(height: 8),
              const Text(
                'Public coordinator details are withheld. Contact requests are not sent from this demo.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _profileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panelHeading(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _emptyDetails() {
    return const GlassCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, color: AppColors.textMuted, size: 32),
          SizedBox(height: 10),
          Text(
            'No institution selected',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Adjust the search filters to discover demo profiles.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkerLegend() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Wrap(
        spacing: 16,
        runSpacing: 9,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: DemoHospitalType.values.map((type) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _markerColor(type),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _markerColor(type).withAlpha(100),
                      blurRadius: 5,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  type.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchResults(List<DemoHospital> hospitals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Institution search results',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${hospitals.length} results',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (hospitals.isEmpty)
          const GlassCard(
            child: Text(
              'No fictional institutions matched your search. Try another city, state, or coordination type.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          )
        else
          ...hospitals.map(
            (hospital) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                padding: const EdgeInsets.all(12),
                onTap: () => setState(
                  () => _selectedHospitalId = hospital.institutionId,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final identity = Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _markerIcon(hospital.type),
                          color: _markerColor(hospital.type),
                          size: 19,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hospital.name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${hospital.locationLabel} · ${hospital.coordinationModules.join(' · ')}',
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
                      ],
                    );
                    final verification = AppStatusBadge(
                      label: hospital.verification.label,
                      variant: _verificationVariant(hospital.verification),
                      showDot: false,
                    );
                    if (constraints.maxWidth < 540) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          identity,
                          const SizedBox(height: 8),
                          verification,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: identity),
                        const SizedBox(width: 9),
                        verification,
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _dropdown({
    Key? key,
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      key: key,
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: options
          .map(
            (option) => DropdownMenuItem(
              value: option,
              child: Text(option, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Color _markerColor(DemoHospitalType type) {
    return switch (type) {
      DemoHospitalType.apexTeaching => AppColors.accentPrimary,
      DemoHospitalType.regional => AppColors.accentSecondary,
      DemoHospitalType.traumaBlood => AppColors.danger,
      DemoHospitalType.specialty => AppColors.aiPurple,
    };
  }

  IconData _markerIcon(DemoHospitalType type) {
    return switch (type) {
      DemoHospitalType.apexTeaching => Icons.school_rounded,
      DemoHospitalType.regional => Icons.local_hospital_rounded,
      DemoHospitalType.traumaBlood => Icons.bloodtype_rounded,
      DemoHospitalType.specialty => Icons.medical_services_rounded,
    };
  }

  StatusBadgeVariant _verificationVariant(
    DemoHospitalVerification verification,
  ) {
    return switch (verification) {
      DemoHospitalVerification.demoVerified => StatusBadgeVariant.success,
      DemoHospitalVerification.pending => StatusBadgeVariant.warning,
      DemoHospitalVerification.reported => StatusBadgeVariant.neutral,
    };
  }
}
