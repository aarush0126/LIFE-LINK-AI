import 'package:flutter_test/flutter_test.dart';
import 'package:life_link_ai/core/theme/app_theme.dart';
import 'package:life_link_ai/features/dashboard/presentation/dashboard_screen.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('dashboard labels synthetic data and filters requests', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.darkTheme, home: const DashboardScreen()),
    );
    await tester.pump();

    expect(find.text('SYNTHETIC DEMONSTRATION DATA'), findsOneWidget);
    expect(find.text('CONNECTED HOSPITALS'), findsOneWidget);
    expect(find.text('BLOOD COMPONENTS AVAILABLE'), findsOneWidget);
    expect(find.text('Recent coordination requests'), findsOneWidget);
    expect(find.text('DEMO-REQ-101'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('dashboard-request-search')),
      'DEMO-REQ-106',
    );
    await tester.pump();

    expect(find.text('DEMO-REQ-106').last, findsOneWidget);
    expect(find.text('DEMO-REQ-101'), findsNothing);
  });

  testWidgets('dashboard renders without overflow on a mobile viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.darkTheme, home: const DashboardScreen()),
    );
    await tester.pump();

    expect(find.text('SYNTHETIC DEMONSTRATION DATA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('date range, sorting, and pagination update request rows', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.darkTheme, home: const DashboardScreen()),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('dashboard-date-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Last 30 days').last);
    await tester.pump();
    expect(find.text('Showing 5 of 8 registered units'), findsOneWidget);

    await tester.tap(find.byKey(const Key('dashboard-sort-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oldest first').last);
    await tester.pump();
    expect(find.text('DEMO-REQ-108'), findsOneWidget);

    await tester.ensureVisible(find.text('Page 1 of 2').first);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.chevron_right_rounded).first);
    await tester.pump();
    expect(find.text('Page 2 of 2'), findsOneWidget);
  });
}
