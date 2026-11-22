import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import '../theme/app_colors.dart';
import '../utils/responsive_utils.dart';
import 'app_sidebar.dart';
import 'app_top_bar.dart';

class ResponsiveScaffold extends ConsumerStatefulWidget {
  final Widget body;
  final String currentRoute;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    required this.currentRoute,
  });

  @override
  ConsumerState<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends ConsumerState<ResponsiveScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bgPrimary,
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: AppColors.bgSecondary,
              child: AppSidebar(
                currentRoute: widget.currentRoute,
                isCollapsed: false,
              ),
            ),
      body: Row(
        children: [
          if (isDesktop)
            AppSidebar(
              currentRoute: widget.currentRoute,
              isCollapsed: _isCollapsed,
              onToggleCollapse: () => setState(() => _isCollapsed = !_isCollapsed),
            ),
          Expanded(
            child: Column(
              children: [
                AppTopBar(
                  currentRoute: widget.currentRoute,
                  onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                Expanded(
                  child: Container(
                    color: AppColors.bgPrimary,
                    child: widget.body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
