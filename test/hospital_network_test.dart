import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_link_ai/features/hospitals/presentation/hospitals_screen.dart';
import 'package:material_ui/material_ui.dart';

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

class _TransparentTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return MemoryImage(
      Uint8List.fromList(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGMQUDD4DwACBAFgjby7cQAAAABJRU5ErkJggg==',
        ),
      ),
    );
  }
}

Widget _app() => MaterialApp(
  theme: ThemeData.dark(),
  home: HospitalsScreen(tileProvider: _TransparentTileProvider()),
);

void main() {
  testWidgets('hospital network shows an interactive demo map and profiles', (
    WidgetTester tester,
  ) async {
    _setViewport(tester, const Size(1600, 1200));
    await tester.pumpWidget(_app());
    await tester.pump();

    expect(find.text('Hospital Network'), findsOneWidget);
    expect(find.byKey(const Key('hospital-network-map')), findsOneWidget);
    expect(find.byKey(const Key('hospital-details-panel')), findsOneWidget);
    expect(find.text('DEMO-HN-1001'), findsOneWidget);
    expect(find.text('Contact coordination desk'), findsOneWidget);
    expect(
      find.textContaining('coordinates are illustrative city-level points'),
      findsOneWidget,
    );
    expect(find.textContaining('Contact'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('state and city filters narrow the map and result list', (
    WidgetTester tester,
  ) async {
    _setViewport(tester, const Size(1600, 1200));
    await tester.pumpWidget(_app());
    await tester.pump();

    await tester.tap(find.byKey(const Key('hospital-state-filter')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Punjab').last);
    await tester.pump();
    expect(find.text('1 MATCHING INSTITUTIONS'), findsOneWidget);
    expect(
      find.text('Riverside Emergency & Blood Services (Demo)'),
      findsNWidgets(2),
    );
    expect(
      find.text('Northstar Institute of Connected Care (Demo)'),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('hospital-city-filter')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Ludhiana').last);
    await tester.pump();
    expect(find.text('Ludhiana, Punjab'), findsOneWidget);
  });

  testWidgets('hospital search supports resource type and city queries', (
    WidgetTester tester,
  ) async {
    _setViewport(tester, const Size(1600, 1200));
    await tester.pumpWidget(_app());
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('hospital-network-search')),
      'dialysis',
    );
    await tester.pump();
    expect(
      find.text('Cedar Valley Regional Medical Centre (Demo)'),
      findsNWidgets(2),
    );
    expect(find.text('Highland Specialty Care Centre (Demo)'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('hospital-network-search')),
      'Kochi',
    );
    await tester.pump();
    expect(find.text('Coastal Care Network Hospital (Demo)'), findsNWidgets(2));
    expect(find.text('1 MATCHING INSTITUTIONS'), findsOneWidget);
  });

  testWidgets('contact action withholds private details and stays local', (
    WidgetTester tester,
  ) async {
    _setViewport(tester, const Size(1600, 1200));
    await tester.pumpWidget(_app());
    await tester.pump();

    await tester.tap(find.byKey(const Key('hospital-contact-coordinator')));
    await tester.pump();
    expect(
      find.textContaining('Coordinator contact details are not public'),
      findsOneWidget,
    );
    expect(find.text('Prepare demo enquiry'), findsOneWidget);
    await tester.tap(find.text('Prepare demo enquiry'));
    await tester.pump();
    expect(find.textContaining('No contact was made'), findsOneWidget);
  });

  testWidgets('hospital map and details panel fit mobile viewport', (
    WidgetTester tester,
  ) async {
    _setViewport(tester, const Size(375, 812));
    await tester.pumpWidget(_app());
    await tester.pump();

    expect(find.byKey(const Key('hospital-network-map')), findsOneWidget);
    expect(find.text('Hospital Network'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
