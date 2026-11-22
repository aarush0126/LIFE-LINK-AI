import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_charts.dart';
import '../../../core/widgets/app_data_table.dart';
import '../../../core/widgets/app_notification_card.dart';
import '../../../core/widgets/app_stat_card.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../core/widgets/glass_card.dart';
import '../data/synthetic_dashboard_data.dart';

enum _DashboardDateRange { last24Hours, last7Days, last30Days, custom }

enum _DashboardSort { newest, oldest, requestId, status }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _pageSize = 5;

  _DashboardDateRange _dateRange = _DashboardDateRange.last7Days;
  _DashboardSort _sort = _DashboardSort.newest;
  DateTimeRange? _customRange;
  String _searchQuery = '';
  int _currentPage = 1;

  DateTime _rangeStart() {
    if (_dateRange == _DashboardDateRange.custom && _customRange != null) {
      return _customRange!.start;
    }
    final now = DateTime.now();
    switch (_dateRange) {
      case _DashboardDateRange.last24Hours:
        return now.subtract(const Duration(hours: 24));
      case _DashboardDateRange.last7Days:
        return now.subtract(const Duration(days: 7));
      case _DashboardDateRange.last30Days:
        return now.subtract(const Duration(days: 30));
      case _DashboardDateRange.custom:
        return now.subtract(const Duration(days: 7));
    }
  }

  DateTime _rangeEnd() {
    if (_dateRange == _DashboardDateRange.custom && _customRange != null) {
      return _customRange!.end.add(const Duration(days: 1));
    }
    return DateTime.now().add(const Duration(seconds: 1));
  }

  bool _isInDateRange(DateTime date) {
    return !date.isBefore(_rangeStart()) && date.isBefore(_rangeEnd());
  }

  List<DemoCoordinationRequest> get _filteredRequests {
    final query = _searchQuery.trim().toLowerCase();
    final requests = SyntheticDashboardData.requests.where((request) {
      if (!_isInDateRange(request.lastUpdatedAt)) return false;
      if (query.isEmpty) return true;
      return [
        request.requestId,
        request.resourceCategory,
        request.requestingHospital,
        request.location,
        request.status.label,
      ].any((field) => field.toLowerCase().contains(query));
    }).toList();

    switch (_sort) {
      case _DashboardSort.newest:
        requests.sort((a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt));
      case _DashboardSort.oldest:
        requests.sort((a, b) => a.lastUpdatedAt.compareTo(b.lastUpdatedAt));
      case _DashboardSort.requestId:
        requests.sort((a, b) => a.requestId.compareTo(b.requestId));
      case _DashboardSort.status:
        requests.sort((a, b) => a.status.index.compareTo(b.status.index));
    }
    return requests;
  }

  List<DemoResourceListing> get _filteredResources => SyntheticDashboardData
      .resources
      .where((resource) => _isInDateRange(resource.lastUpdatedAt))
      .toList();

  List<DemoNetworkActivity> get _filteredActivity =>
      SyntheticDashboardData.networkActivity
          .where((activity) => _isInDateRange(activity.occurredAt))
          .toList()
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

  Future<void> _selectDateRange(_DashboardDateRange? range) async {
    if (range == null) return;
    if (range != _DashboardDateRange.custom) {
      setState(() {
        _dateRange = range;
        _currentPage = 1;
      });
      return;
    }

    final now = DateTime.now();
    final selected = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      initialDateRange:
          _customRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _dateRange = _DashboardDateRange.custom;
      _customRange = selected;
      _currentPage = 1;
    });
  }

  void _updateSearch(String value) {
    setState(() {
      _searchQuery = value;
      _currentPage = 1;
    });
  }

  void _updateSort(_DashboardSort? value) {
    if (value == null) return;
    setState(() {
      _sort = value;
      _currentPage = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final requests = _filteredRequests;
    final resources = _filteredResources;
    final activity = _filteredActivity;
    final pageCount = (requests.length / _pageSize).ceil().clamp(1, 999);
    final page = _currentPage > pageCount ? pageCount : _currentPage;
    final pageItems = requests
        .skip((page - 1) * _pageSize)
        .take(_pageSize)
        .toList();
    final activeRequests = requests.where((r) => r.status.isActive).length;
    final bloodCount = _listedCount(resources, DemoResourceCategory.blood);
    final icuCount = _listedCount(resources, DemoResourceCategory.icu);
    final equipmentCount = _listedCount(
      resources,
      DemoResourceCategory.equipment,
    );
    final pendingCount = requests
        .where(
          (request) =>
              request.verification ==
              DemoVerificationStatus.awaitingConfirmation,
        )
        .length;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSyntheticNotice(),
            const SizedBox(height: 22),
            _buildPageHeader(context),
            const SizedBox(height: 18),
            _buildFilters(),
            const SizedBox(height: 26),
            _sectionHeading(
              'Resource overview',
              'Synthetic listings for the selected date range. Confirm every resource with its institution.',
            ),
            const SizedBox(height: 14),
            _buildStatCards(
              context,
              activeRequests: activeRequests,
              bloodCount: bloodCount,
              icuCount: icuCount,
              equipmentCount: equipmentCount,
            ),
            const SizedBox(height: 28),
            _sectionHeading(
              'Recent coordination requests',
              'Demo request records only. “Confirmed” refers to a synthetic example, not a real allocation.',
            ),
            const SizedBox(height: 14),
            AppDataTable(
              columns: const [
                AppTableColumn(title: 'Request ID', width: 140),
                AppTableColumn(title: 'Resource category', width: 170),
                AppTableColumn(title: 'Requesting hospital', width: 240),
                AppTableColumn(title: 'Location', width: 190),
                AppTableColumn(title: 'Status', width: 160),
                AppTableColumn(title: 'Verification', width: 180),
                AppTableColumn(title: 'Last updated', width: 150),
              ],
              rows: pageItems.map(_requestRow).toList(),
              emptyMessage: 'No synthetic requests match these filters. Try a wider date range or a different search.',
              currentPage: page,
              totalPages: pageCount,
              totalRecords: requests.length,
              onPageChanged: (value) => setState(() => _currentPage = value),
            ),
            const SizedBox(height: 28),
            _sectionHeading(
              'Resource listing charts',
              'Counts are synthetic institution listings, not confirmed or guaranteed availability.',
            ),
            const SizedBox(height: 14),
            _buildCharts(context, resources),
            const SizedBox(height: 28),
            _sectionHeading(
              'Synthetic resource listings',
              'Each quantity is a demo listing with its own status and last-updated time; confirm with the institution before relying on it.',
            ),
            const SizedBox(height: 14),
            _buildResourceTable(resources),
            const SizedBox(height: 28),
            _buildActivityAndNotifications(
              context,
              activity: activity,
              requests: requests,
            ),
            const SizedBox(height: 28),
            _buildInsights(pendingCount, resources),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Synthetic demonstration environment · No live hospital systems are connected',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _listedCount(
    List<DemoResourceListing> resources,
    DemoResourceCategory category,
  ) {
    return resources
        .where((resource) => resource.category == category)
        .fold(0, (sum, resource) => sum + resource.listedQuantity);
  }

  Widget _buildSyntheticNotice() {
    return GlassCard(
      glowAccent: GlowAccent.warning,
      padding: const EdgeInsets.all(14),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.science_outlined, color: AppColors.warning, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SYNTHETIC DEMONSTRATION DATA',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'No live hospital systems are connected. Listed counts are not guarantees of availability or allocation; verify directly through authorized institutional pathways.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Hospital coordination overview',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 23,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'A single view of synthetic network activity and resource listings.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        );
        final actions = Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            AppButton(
              label: 'AI Assistant',
              icon: Icons.auto_awesome_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: () => context.go(RouteNames.aiAssistant),
            ),
            AppButton(
              label: 'Notifications',
              icon: Icons.notifications_none_rounded,
              variant: AppButtonVariant.ghost,
              onPressed: () => context.go(RouteNames.notifications),
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
            const SizedBox(width: 16),
            actions,
          ],
        );
      },
    );
  }

  Widget _buildFilters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final search = TextField(
          key: const Key('dashboard-request-search'),
          onChanged: _updateSearch,
          decoration: InputDecoration(
            hintText: 'Search requests, hospitals, locations…',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: AppColors.bgInput,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
          ),
        );
        final selectors = Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [_dateRangeSelector(), _sortSelector()],
        );

        if (constraints.maxWidth < 640) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [search, const SizedBox(height: 10), selectors],
          );
        }
        return Row(
          children: [
            Expanded(child: search),
            const SizedBox(width: 12),
            selectors,
          ],
        );
      },
    );
  }

  Widget _dateRangeSelector() {
    return _SelectorFrame(
      icon: Icons.calendar_month_outlined,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_DashboardDateRange>(
          key: const Key('dashboard-date-filter'),
          value: _dateRange,
          isDense: true,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
          dropdownColor: AppColors.bgCard,
          items: const [
            DropdownMenuItem(
              value: _DashboardDateRange.last24Hours,
              child: Text('Last 24 hours'),
            ),
            DropdownMenuItem(
              value: _DashboardDateRange.last7Days,
              child: Text('Last 7 days'),
            ),
            DropdownMenuItem(
              value: _DashboardDateRange.last30Days,
              child: Text('Last 30 days'),
            ),
            DropdownMenuItem(
              value: _DashboardDateRange.custom,
              child: Text('Custom range…'),
            ),
          ],
          onChanged: _selectDateRange,
        ),
      ),
    );
  }

  Widget _sortSelector() {
    return _SelectorFrame(
      icon: Icons.sort_rounded,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_DashboardSort>(
          key: const Key('dashboard-sort-filter'),
          value: _sort,
          isDense: true,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
          dropdownColor: AppColors.bgCard,
          items: const [
            DropdownMenuItem(
              value: _DashboardSort.newest,
              child: Text('Newest first'),
            ),
            DropdownMenuItem(
              value: _DashboardSort.oldest,
              child: Text('Oldest first'),
            ),
            DropdownMenuItem(
              value: _DashboardSort.requestId,
              child: Text('Request ID'),
            ),
            DropdownMenuItem(
              value: _DashboardSort.status,
              child: Text('Status'),
            ),
          ],
          onChanged: _updateSort,
        ),
      ),
    );
  }

  Widget _buildStatCards(
    BuildContext context, {
    required int activeRequests,
    required int bloodCount,
    required int icuCount,
    required int equipmentCount,
  }) {
    final cards = [
      AppStatCard(
        title: 'Connected Hospitals',
        value: '${SyntheticDashboardData.hospitals.length}',
        subtitle: 'Synthetic demo nodes',
        icon: Icons.hub_outlined,
        accentColor: AppColors.accentPrimary,
        onTap: () => context.go(RouteNames.hospitals),
      ),
      AppStatCard(
        title: 'Active Coordination Requests',
        value: '$activeRequests',
        subtitle: 'Demo requests in range',
        icon: Icons.sync_alt_rounded,
        accentColor: AppColors.accentSecondary,
        onTap: () => context.go(RouteNames.notifications),
      ),
      AppStatCard(
        title: 'Blood Components Available',
        value: '$bloodCount listed',
        subtitle: 'Synthetic units · confirm first',
        icon: Icons.water_drop_outlined,
        accentColor: AppColors.bloodRed,
        onTap: () => context.go(RouteNames.bloodBank),
      ),
      AppStatCard(
        title: 'ICU Bed Indicators',
        value: '$icuCount listed',
        subtitle: 'Synthetic beds · confirm first',
        icon: Icons.bed_outlined,
        accentColor: AppColors.icuBlue,
        onTap: () => context.go(RouteNames.icuBeds),
      ),
      AppStatCard(
        title: 'Equipment Availability',
        value: '$equipmentCount listed',
        subtitle: 'Synthetic devices · confirm first',
        icon: Icons.medical_services_outlined,
        accentColor: AppColors.equipmentAmber,
        onTap: () => context.go(RouteNames.equipment),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1200
            ? 5
            : constraints.maxWidth >= 760
            ? 3
            : constraints.maxWidth >= 470
            ? 2
            : 1;
        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: columns == 1 ? 1.9 : 1.42,
          children: cards,
        );
      },
    );
  }

  AppTableRow _requestRow(DemoCoordinationRequest request) {
    return AppTableRow(
      cells: [
        Text(
          request.requestId,
          style: const TextStyle(
            color: AppColors.accentPrimary,
            fontFamily: 'monospace',
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          request.resourceCategory,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
        ),
        Text(
          request.requestingHospital,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          request.location,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        AppStatusBadge(
          label: request.status.label,
          variant: _requestStatusVariant(request.status),
        ),
        _verificationBadge(request.verification),
        Text(
          DateFormat('MMM d, HH:mm').format(request.lastUpdatedAt),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  StatusBadgeVariant _requestStatusVariant(DemoRequestStatus status) {
    return switch (status) {
      DemoRequestStatus.awaitingVerification => StatusBadgeVariant.warning,
      DemoRequestStatus.coordinating => StatusBadgeVariant.info,
      DemoRequestStatus.institutionConfirmed => StatusBadgeVariant.success,
      DemoRequestStatus.closed => StatusBadgeVariant.neutral,
    };
  }

  Widget _verificationBadge(DemoVerificationStatus status) {
    return AppStatusBadge(
      label: status == DemoVerificationStatus.institutionConfirmed
          ? 'Verified (synthetic)'
          : 'Awaiting confirmation',
      variant: status == DemoVerificationStatus.institutionConfirmed
          ? StatusBadgeVariant.info
          : StatusBadgeVariant.warning,
      showDot: false,
      icon: status == DemoVerificationStatus.institutionConfirmed
          ? Icons.verified_outlined
          : Icons.hourglass_bottom_rounded,
    );
  }

  Widget _buildCharts(
    BuildContext context,
    List<DemoResourceListing> resources,
  ) {
    final chartData = DemoResourceCategory.values.map((category) {
      final amount = _listedCount(resources, category);
      return ChartDataPoint(label: category.label, value: amount.toDouble());
    }).toList();
    final chart = resources.isEmpty
        ? _emptyPanel('No synthetic resource listings in this date range.')
        : TelemetryBarChart(
            title: 'Resource listings by category',
            subtitle: 'Synthetic listed counts · not live availability',
            data: chartData,
          );
    final verificationSummary = GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verification coverage',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Synthetic resource listings by confirmation state.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 18),
          ...DemoVerificationStatus.values.map((status) {
            final count = resources
                .where((item) => item.verification == status)
                .length;
            final color = status == DemoVerificationStatus.institutionConfirmed
                ? AppColors.accentSecondary
                : AppColors.warning;
            final fraction = resources.isEmpty ? 0.0 : count / resources.length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          status.label,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Text(
                        '$count',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 6,
                      color: color,
                      backgroundColor: AppColors.bgInput,
                    ),
                  ),
                ],
              ),
            );
          }),
          const Text(
            'A synthetic confirmation is not a real-world availability guarantee.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 860) {
          return Column(
            children: [chart, const SizedBox(height: 14), verificationSummary],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: chart),
            const SizedBox(width: 14),
            Expanded(flex: 2, child: verificationSummary),
          ],
        );
      },
    );
  }

  Widget _buildResourceTable(List<DemoResourceListing> resources) {
    return AppDataTable(
      columns: const [
        AppTableColumn(title: 'Resource', width: 220),
        AppTableColumn(title: 'Category', width: 170),
        AppTableColumn(title: 'Listed quantity', width: 135),
        AppTableColumn(title: 'Institution', width: 250),
        AppTableColumn(title: 'Verification', width: 180),
        AppTableColumn(title: 'Last updated', width: 150),
      ],
      rows: resources.map((resource) {
        final isConfirmed =
            resource.verification ==
            DemoVerificationStatus.institutionConfirmed;
        return AppTableRow(
          cells: [
            Text(
              resource.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
            Text(
              resource.category.label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            Text(
              '${resource.listedQuantity} ${resource.unit} listed',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              resource.hospitalName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
            AppStatusBadge(
              label: isConfirmed
                  ? 'Verified (synthetic)'
                  : 'Awaiting confirmation',
              variant: isConfirmed
                  ? StatusBadgeVariant.info
                  : StatusBadgeVariant.warning,
              showDot: false,
            ),
            Text(
              DateFormat('MMM d, HH:mm').format(resource.lastUpdatedAt),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        );
      }).toList(),
      emptyMessage: 'No synthetic resource listings in this date range.',
      totalRecords: resources.length,
    );
  }

  Widget _buildActivityAndNotifications(
    BuildContext context, {
    required List<DemoNetworkActivity> activity,
    required List<DemoCoordinationRequest> requests,
  }) {
    final recentRequests = requests.take(3).toList();
    final networkPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(
          'Hospital network activity',
          'Synthetic update events · no live connection',
        ),
        const SizedBox(height: 12),
        if (activity.isEmpty)
          _emptyPanel('No network events in this date range.')
        else
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: activity.take(5).map(_networkActivityRow).toList(),
            ),
          ),
      ],
    );
    final notificationPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _sectionHeading(
                'Recent notifications',
                'Synthetic events · timestamps are illustrative',
              ),
            ),
            IconButton(
              tooltip: 'Open notifications',
              onPressed: () => context.go(RouteNames.notifications),
              icon: const Icon(
                Icons.open_in_new_rounded,
                color: AppColors.accentPrimary,
                size: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recentRequests.isEmpty)
          _emptyPanel('No recent demo notifications.')
        else
          Column(
            children: recentRequests.map((request) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppNotificationCard(
                  title: 'Request ${request.requestId}',
                  message:
                      '${request.resourceCategory} · ${request.requestingHospital}. Synthetic record; confirm details directly with the institution.',
                  timeAgo: DateFormat('MMM d, HH:mm')
                      .format(request.lastUpdatedAt),
                  severity:
                      request.status == DemoRequestStatus.awaitingVerification
                      ? NotificationSeverity.urgent
                      : NotificationSeverity.info,
                  isUnread:
                      request.status == DemoRequestStatus.awaitingVerification,
                ),
              );
            }).toList(),
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            children: [
              networkPanel,
              const SizedBox(height: 24),
              notificationPanel,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: networkPanel),
            const SizedBox(width: 18),
            Expanded(child: notificationPanel),
          ],
        );
      },
    );
  }

  Widget _networkActivityRow(DemoNetworkActivity activity) {
    final isConfirmed =
        activity.verification == DemoVerificationStatus.institutionConfirmed;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.accentSecondary.withAlpha(20),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.hub_outlined,
              size: 17,
              color: AppColors.accentSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.hospitalName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${activity.title} · ${activity.detail}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 5,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AppStatusBadge(
                      label: isConfirmed
                          ? 'Verified (synthetic)'
                          : 'Awaiting confirmation',
                      variant: isConfirmed
                          ? StatusBadgeVariant.info
                          : StatusBadgeVariant.warning,
                      showDot: false,
                    ),
                    Text(
                      DateFormat('MMM d, HH:mm').format(activity.occurredAt),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsights(int pendingCount, List<DemoResourceListing> resources) {
    final pendingResources = resources
        .where(
          (resource) =>
              resource.verification ==
              DemoVerificationStatus.awaitingConfirmation,
        )
        .length;
    return GlassCard(
      glowAccent: GlowAccent.blue,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.aiPurple.withAlpha(22),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.aiPurple,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI-generated operational insights · demo',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                _insightLine(
                  '$pendingCount synthetic coordination request(s) in this range await institutional confirmation.',
                ),
                const SizedBox(height: 7),
                _insightLine(
                  '$pendingResources synthetic resource listing(s) are marked as awaiting confirmation.',
                ),
                const SizedBox(height: 7),
                _insightLine(
                  'No allocation or clinical action is recommended or initiated by these demo insights.',
                ),
                const SizedBox(height: 10),
                const Text(
                  'Illustrative only · not clinical advice · human review required',
                  style: TextStyle(
                    color: AppColors.aiPurple,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightLine(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 5),
          child: Icon(Icons.circle, color: AppColors.accentSecondary, size: 5),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeading(String title, String subtitle) {
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
        const SizedBox(height: 3),
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

  Widget _emptyPanel(String message) {
    return GlassCard(
      padding: const EdgeInsets.all(22),
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

class _SelectorFrame extends StatelessWidget {
  final IconData icon;
  final Widget child;

  const _SelectorFrame({required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 46),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.accentPrimary),
          const SizedBox(width: 7),
          child,
        ],
      ),
    );
  }
}
