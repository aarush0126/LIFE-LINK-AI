import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/glass_card.dart';

class ResourceModuleSwitcher extends StatelessWidget {
  final bool equipmentSelected;

  const ResourceModuleSwitcher({super.key, required this.equipmentSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        AppButton(
          label: 'Beds & emergency capacity',
          icon: Icons.local_hotel_outlined,
          variant: equipmentSelected
              ? AppButtonVariant.secondary
              : AppButtonVariant.primary,
          onPressed: equipmentSelected
              ? () => context.go(RouteNames.icuBeds)
              : null,
        ),
        AppButton(
          label: 'Medical equipment',
          icon: Icons.precision_manufacturing_outlined,
          variant: equipmentSelected
              ? AppButtonVariant.primary
              : AppButtonVariant.secondary,
          onPressed: equipmentSelected
              ? null
              : () => context.go(RouteNames.equipment),
        ),
      ],
    );
  }
}

class ResourceSafetyBanner extends StatelessWidget {
  const ResourceSafetyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glowAccent: GlowAccent.warning,
      padding: const EdgeInsets.all(16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.health_and_safety_outlined,
                color: AppColors.warning,
                size: 22,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'A displayed bed or equipment item is an indication for enquiry, not a confirmed admission or guaranteed transfer.',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'All records are synthetic. Confirm current status, capacity and clinical suitability directly with authorized hospital staff. Actual transfers and clinical suitability require human confirmation.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class ResourceDiscoveryToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final String searchKey;
  final String searchHint;
  final String selectedLocation;
  final List<String> locations;
  final ValueChanged<String?> onLocationChanged;
  final List<Widget> additionalFilters;
  final VoidCallback onReset;

  const ResourceDiscoveryToolbar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.searchKey,
    required this.searchHint,
    required this.selectedLocation,
    required this.locations,
    required this.onLocationChanged,
    this.additionalFilters = const [],
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Common resource discovery',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Search synthetic reports by institution, type, status or location. Results are enquiry indications, not confirmed availability.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth < 240
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
                      key: Key(searchKey),
                      controller: searchController,
                      onChanged: onSearchChanged,
                      decoration: InputDecoration(
                        labelText: 'Search resources',
                        hintText: searchHint,
                        prefixIcon: const Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: DropdownButtonFormField<String>(
                      key: const Key('resource-location-filter'),
                      initialValue: selectedLocation,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Location'),
                      items: [
                        const DropdownMenuItem(
                          value: 'All demo locations',
                          child: Text('All demo locations'),
                        ),
                        ...locations.map(
                          (location) => DropdownMenuItem(
                            value: location,
                            child: Text(
                              location,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: onLocationChanged,
                    ),
                  ),
                  ...additionalFilters,
                  AppButton(
                    label: 'Reset filters',
                    icon: Icons.filter_alt_off_rounded,
                    variant: AppButtonVariant.ghost,
                    onPressed: onReset,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
