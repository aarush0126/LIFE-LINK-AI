import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_link_ai/features/landing/presentation/landing_screen.dart';
import 'package:life_link_ai/main.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('LIFE-LINK AI smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const ProviderScope(child: LifeLinkApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(LandingScreen), findsOneWidget);
  });

  testWidgets('LIFE-LINK AI renders on a mobile viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const ProviderScope(child: LifeLinkApp()));
    await tester.pump();

    expect(find.byType(LandingScreen), findsOneWidget);
    expect(find.text('Explore Platform'), findsOneWidget);
  });

  testWidgets('Explore Platform scrolls to the solution modules', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const ProviderScope(child: LifeLinkApp()));
    await tester.pump();

    await tester.tap(find.text('Explore Platform'));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Four Modules.\nOne Unified Network.'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Four Modules.\nOne Unified Network.')).dy,
      lessThan(900),
    );

    await tester.tap(find.text('Home').last);
    await tester.pump();
    await tester.tap(find.text('How It Works'));
    await tester.pump();

    expect(find.text('Five Steps to Faster\nCoordination'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Five Steps to Faster\nCoordination')).dy,
      lessThan(900),
    );
  });
}
