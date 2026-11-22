import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_link_ai/core/theme/app_theme.dart';
import 'package:life_link_ai/core/widgets/app_button.dart';
import 'package:life_link_ai/core/widgets/app_stat_card.dart';
import 'package:life_link_ai/features/authentication/application/auth_controller.dart';
import 'package:life_link_ai/features/organ_coordination/presentation/organ_coordination_screen.dart';
import 'package:life_link_ai/shared/models/user_model.dart';
import 'package:material_ui/material_ui.dart';

Future<AuthController> _signedInCoordinator(WidgetTester tester) async {
  final controller = AuthController();
  final signingIn = controller.signInDemo(UserRole.transplantCoordinator);
  await tester.pump(const Duration(milliseconds: 300));
  await signingIn;
  return controller;
}

Widget _app(AuthController controller) {
  return ProviderScope(
    overrides: [authControllerProvider.overrideWithValue(controller)],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: const OrganCoordinationScreen(),
    ),
  );
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  testWidgets('safety disclaimer is prominent and cases are synthetic', (
    WidgetTester tester,
  ) async {
    _setViewport(tester, const Size(1440, 1000));
    final controller = AuthController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));
    await tester.pump();

    expect(
      find.text(
        'AI assistance only. Clinical and allocation decisions remain with authorized authorities and medical professionals.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Competition prototype · all cases and institutions are fictional',
      ),
      findsOneWidget,
    );
    expect(find.text('DEMO-OT-2401'), findsOneWidget);
    expect(find.textContaining('donor eligibility'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('creating a case updates the synthetic overview count', (
    WidgetTester tester,
  ) async {
    _setViewport(tester, const Size(1440, 1100));
    final controller = AuthController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));
    await tester.pump();

    final activeCard = find.ancestor(
      of: find.text('ACTIVE SIMULATED CASES'),
      matching: find.byType(AppStatCard),
    );
    expect(
      find.descendant(of: activeCard, matching: find.text('4')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('organ-view-createCase')));
    await tester.pump();
    await tester.ensureVisible(find.text('Create synthetic case'));
    await tester.tap(find.text('Create synthetic case'));
    await tester.pump();

    expect(find.textContaining('Case details · DEMO-OT-'), findsOneWidget);
    await tester.tap(find.byKey(const Key('organ-view-overview')));
    await tester.pump();
    expect(
      find.descendant(of: activeCard, matching: find.text('5')),
      findsOneWidget,
    );
  });

  testWidgets(
    'simulated routing stays human-gated and requires acknowledgement',
    (WidgetTester tester) async {
      _setViewport(tester, const Size(1440, 1100));
      final controller = await _signedInCoordinator(tester);
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(controller));
      await tester.pump();
      await tester.tap(find.byKey(const Key('organ-view-workflow')));
      await tester.pump();

      final routeAction = find.ancestor(
        of: find.text('Record simulated pathway step'),
        matching: find.byType(AppButton),
      );
      expect(tester.widget<AppButton>(routeAction).onPressed, isNull);

      await tester.ensureVisible(find.text('Record human review'));
      await tester.tap(find.text('Record human review'));
      await tester.pump();
      final reviewConfirmation = find.widgetWithText(
        FilledButton,
        'Record demo review',
      );
      expect(tester.widget<FilledButton>(reviewConfirmation).onPressed, isNull);
      await tester.tap(
        find.text('I understand this only updates local synthetic demo state.'),
      );
      await tester.pump();
      await tester.tap(reviewConfirmation);
      await tester.pump();

      await tester.ensureVisible(find.text('Record simulated pathway step'));
      await tester.tap(find.text('Record simulated pathway step'));
      await tester.pump();
      final routeConfirmation = find.widgetWithText(
        FilledButton,
        'Record demo pathway',
      );
      expect(tester.widget<FilledButton>(routeConfirmation).onPressed, isNull);
      await tester.tap(
        find.text('I understand this only updates local synthetic demo state.'),
      );
      await tester.pump();
      await tester.tap(routeConfirmation);
      await tester.pump();

      expect(
        find.text('DEMO PATHWAY REFERENCE RECORDED LOCALLY'),
        findsOneWidget,
      );
      expect(
        find.textContaining('No authority or institution was contacted'),
        findsOneWidget,
      );
    },
  );

  testWidgets('discovery filters directory capabilities without ranking', (
    WidgetTester tester,
  ) async {
    _setViewport(tester, const Size(1440, 1000));
    final controller = AuthController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));
    await tester.pump();
    await tester.tap(find.byKey(const Key('organ-view-discovery')));
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('organ-centre-search')),
      'ocular tissue',
    );
    await tester.pump();

    expect(
      find.text('Riverside Tissue Coordination Unit (Demo)'),
      findsOneWidget,
    );
    expect(find.text('Northstar Retrieval Institute (Demo)'), findsNothing);
    expect(find.textContaining('not ranked'), findsOneWidget);
  });

  testWidgets('organ coordination renders on mobile without overflow', (
    WidgetTester tester,
  ) async {
    _setViewport(tester, const Size(375, 812));
    final controller = AuthController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));
    await tester.pump();

    expect(find.text('Organ & Tissue Coordination'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
