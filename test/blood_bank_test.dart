import 'package:flutter_test/flutter_test.dart';
import 'package:life_link_ai/core/theme/app_theme.dart';
import 'package:life_link_ai/core/widgets/app_data_table.dart';
import 'package:life_link_ai/features/blood_bank/presentation/blood_bank_screen.dart';
import 'package:material_ui/material_ui.dart';

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  testWidgets(
    'blood inventory is labeled synthetic and separates verification states',
    (WidgetTester tester) async {
      _setViewport(tester, const Size(1440, 1000));
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.darkTheme, home: const BloodBankScreen()),
      );
      await tester.pump();

      expect(
        find.text(
          'Blood compatibility, reservation, issue and transfusion decisions must remain with authorized blood-bank professionals.',
        ),
        findsOneWidget,
      );
      expect(find.text('SYNTHETIC INVENTORY · NO LIVE STOCK'), findsOneWidget);
      expect(find.text('Reported · unverified'), findsWidgets);
      expect(find.text('Demo-confirmed only'), findsWidgets);
      expect(find.textContaining('not confirmed or guaranteed'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('blood group filter narrows inventory and hospital summaries', (
    WidgetTester tester,
  ) async {
    _setViewport(tester, const Size(1440, 1000));
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.darkTheme, home: const BloodBankScreen()),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('blood-group-filter')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('O-').last);
    await tester.pump();

    final inventoryTable = find.byType(AppDataTable).first;
    expect(
      find.descendant(of: inventoryTable, matching: find.text('O-')),
      findsNWidgets(4),
    );
    expect(
      find.descendant(of: inventoryTable, matching: find.text('A+')),
      findsNothing,
    );
    expect(find.textContaining('No hospitals match'), findsNothing);
  });

  testWidgets('valid request adds a tracked enquiry and local notification', (
    WidgetTester tester,
  ) async {
    _setViewport(tester, const Size(1440, 1100));
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.darkTheme, home: const BloodBankScreen()),
    );
    await tester.pump();

    await tester.ensureVisible(
      find.byKey(const Key('blood-request-coordinator')),
    );
    await tester.enterText(
      find.byKey(const Key('blood-request-coordinator')),
      'Jordan Coordinator',
    );
    await tester.tap(find.byKey(const Key('blood-submit-request')));
    await tester.pump();

    expect(find.text('Jordan Coordinator'), findsOneWidget);
    expect(find.text('Enquiry logged · demo'), findsOneWidget);
    expect(find.text('Simulated blood enquiry received'), findsOneWidget);
    expect(find.textContaining('No external message was sent'), findsWidgets);
    expect(find.text('Showing 4 of 4 registered units'), findsNWidgets(2));
  });

  testWidgets(
    'invalid request quantity is rejected without creating a request',
    (WidgetTester tester) async {
      _setViewport(tester, const Size(1440, 1100));
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.darkTheme, home: const BloodBankScreen()),
      );
      await tester.pump();

      await tester.ensureVisible(
        find.byKey(const Key('blood-request-quantity')),
      );
      await tester.enterText(
        find.byKey(const Key('blood-request-quantity')),
        '0',
      );
      await tester.enterText(
        find.byKey(const Key('blood-request-coordinator')),
        'Jordan Coordinator',
      );
      await tester.tap(find.byKey(const Key('blood-submit-request')));
      await tester.pump();

      expect(
        find.text('Enter a whole number greater than zero'),
        findsOneWidget,
      );
      expect(find.text('Showing 3 of 3 registered units'), findsOneWidget);
      expect(find.text('Simulated blood enquiry received'), findsNothing);
    },
  );

  testWidgets('blood bank dashboard renders on mobile without overflow', (
    WidgetTester tester,
  ) async {
    _setViewport(tester, const Size(375, 812));
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.darkTheme, home: const BloodBankScreen()),
    );
    await tester.pump();

    expect(find.text('Blood Bank Network'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
