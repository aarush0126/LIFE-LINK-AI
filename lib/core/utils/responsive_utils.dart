import 'package:material_ui/material_ui.dart';
import '../constants/app_constants.dart';

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  bool get isMobile => screenWidth < AppConstants.mobileBreakpoint;
  bool get isTablet =>
      screenWidth >= AppConstants.mobileBreakpoint && screenWidth < AppConstants.tabletBreakpoint;
  bool get isDesktop => screenWidth >= AppConstants.tabletBreakpoint;
  bool get isLargeDesktop => screenWidth >= AppConstants.desktopBreakpoint;
}

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppConstants.tabletBreakpoint) {
          return desktop;
        } else if (constraints.maxWidth >= AppConstants.mobileBreakpoint) {
          return tablet ?? desktop;
        } else {
          return mobile;
        }
      },
    );
  }
}
