import 'package:flutter_test/flutter_test.dart';
import 'package:life_link_ai/core/theme/app_theme.dart';
import 'package:life_link_ai/core/widgets/app_data_table.dart';
import 'package:life_link_ai/features/equipment/presentation/equipment_screen.dart';
import 'package:life_link_ai/features/icu_beds/presentation/icu_beds_screen.dart';
import 'package:material_ui/material_ui.dart';

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _app(Widget child) =>
    MaterialApp(theme: AppTheme.darkTheme, home: child);

void main() {
  testWidgets('bed indicators stay synthetic and distinguish verification', (
    WidgetTester tester,
  ) async {
    _setViewport(tester, const Size(1440, 1000));
    await tester.pumpWidget(_app(const IcuBedsScreen()));
    await tester.pump();

    expect(
      find.text(
        'A displayed bed or equipment item is an indication for enquiry, not a confirmed admission or guaranteed transfer.',
      ),
      findsOneWidget,
    );
    expect(find.text('ICU BED INDICATORS'), findsOneWidget);
    expect(find.text('GENERAL BED INDICATORS'), findsOneWidget);
    expect(find.text('EMERGENCY BED INDICATORS'), findsOneWidget);
    expect(find.text('Reported · unverified'), findsWidgets);
    expect(find.text('Demo-confirmed only'), findsWidgets);
    expect(find.byKey(const Key('bed-resource-search')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bed location filter narrows listings and capacity summaries', (
    WidgetTester tester,
  ) async {
    _setViewport(tester, const Size(1440, 1000));
    await tester.pumpWidget(_app(const IcuBedsScreen()));
    await tester.pump();

    await tester.tap(find.byKey(const Key('resource-location-filter')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('East District · Demo State').last);
    await tester.pump();

    final bedsTable = find.byType(AppDataTable).first;
    expect(
      find.descendant(
        of: bedsTable,
        matching: find.text('Riverside Regional Hospital (Demo)'),
      ),
      findsNWidgets(3),
    );
    expect(
      find.descendant(
        of: bedsTable,
        matching: find.text('Northstar Teaching Hospital (Demo)'),
      ),
      findsNothing,
    );
  });

  testWidgets('bed enquiry creates a tracked local notification', (
    WidgetTester tester,
  ) async {
    _setViewport(tester, const Size(1440, 1100));
    await tester.pumpWidget(_app(const IcuBedsScreen()));
    await tester.pump();

    await tester.ensureVisible(
      find.byKey(const Key('bed-request-coordinator')),
    );
    await tester.enterText(
      find.byKey(const Key('bed-request-coordinator')),
      'Demo Bed Coordinator',
    );
    await tester.tap(find.byKey(const Key('bed-submit-enquiry')));
    await tester.pump();

    expect(find.text('Demo Bed Coordinator'), findsOneWidget);
    expect(find.text('Enquiry logged · demo'), findsOneWidget);
    expect(find.textContaining('DEMO-TRANSFER-'), findsNWidgets(2));
    expect(
      find.textContaining(
        'Synthetic ICU enquiry received in the local demo inbox',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('No hospital was contacted'), findsOneWidget);
  });

  testWidgets('equipment listings include required statuses and categories', (
    WidgetTester tester,
  ) async {
    _setViewport(tester, const Size(1440, 1000));
    await tester.pumpWidget(_app(const EquipmentScreen()));
    await tester.pump();

    expect(find.text('Ventilators'), findsWidgets);
    expect(find.text('Dialysis machines'), findsWidgets);
    expect(find.text('Oxygen delivery equipment'), findsWidgets);
    expect(find.text('Patient monitors'), findsWidgets);
    expect(find.text('Other critical equipment'), findsWidgets);
    expect(find.text('Available'), findsWidgets);
    expect(find.text('In Use'), findsWidgets);
    expect(find.text('Under Maintenance'), findsWidgets);
    expect(find.text('Requires Confirmation'), findsWidgets);
    expect(find.text('Verification pending'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('equipment filters refine discovery results', (
    WidgetTester tester,
  ) async {
    _setViewport(tester, const Size(1440, 1000));
    await tester.pumpWidget(_app(const EquipmentScreen()));
    await tester.pump();

    await tester.tap(find.byKey(const Key('equipment-status-filter')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Under Maintenance').last);
    await tester.pump();

    final equipmentTable = find.byType(AppDataTable).first;
    expect(
      find.descendant(
        of: equipmentTable,
        matching: find.text('Under Maintenance'),
      ),
      findsNWidgets(5),
    );
    expect(
      find.descendant(of: equipmentTable, matching: find.text('Available')),
      findsNothing,
    );
  });

  testWidgets('equipment enquiry creates status and simulated notifications', (
    WidgetTester tester,
  ) async {
    _setViewport(tester, const Size(1440, 1100));
    await tester.pumpWidget(_app(const EquipmentScreen()));
    await tester.pump();

    await tester.ensureVisible(
      find.byKey(const Key('equipment-request-coordinator')),
    );
    await tester.enterText(
      find.byKey(const Key('equipment-request-coordinator')),
      'Demo Equipment Coordinator',
    );
    await tester.tap(find.byKey(const Key('equipment-submit-enquiry')));
    await tester.pump();

    expect(find.text('Demo Equipment Coordinator'), findsOneWidget);
    expect(find.text('Enquiry logged · demo'), findsOneWidget);
    expect(
      find.textContaining(
        'Synthetic ventilators enquiry received in the local demo inbox',
      ),
      findsWidgets,
    );
    expect(find.textContaining('No hospital was contacted'), findsOneWidget);
  });

  testWidgets('resource modules render responsively on mobile', (
    WidgetTester tester,
  ) async {
    _setViewport(tester, const Size(375, 812));
    await tester.pumpWidget(_app(const IcuBedsScreen()));
    await tester.pump();
    expect(find.text('ICU & Emergency Beds'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(_app(const EquipmentScreen()));
    await tester.pump();
    expect(find.text('Medical Equipment Network'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
