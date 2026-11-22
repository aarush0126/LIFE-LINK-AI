import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_link_ai/features/admin/application/admin_demo_controller.dart';
import 'package:life_link_ai/features/admin/presentation/admin_screen.dart';
import 'package:life_link_ai/features/authentication/application/auth_controller.dart';
import 'package:life_link_ai/features/dashboard/presentation/dashboard_support_screens.dart';
import 'package:life_link_ai/features/notifications/application/notification_controller.dart';
import 'package:life_link_ai/features/notifications/presentation/notifications_screen.dart';
import 'package:life_link_ai/shared/models/user_model.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('Synthetic notifications', () {
    test('role scope excludes unrelated and organ workflow notifications', () {
      final controller = DemoNotificationsController();

      final bloodEvents = controller.forRole(UserRole.bloodBankOfficer);
      expect(
        bloodEvents.every(
          (event) =>
              event.scope == DemoNotificationScope.blood ||
              event.scope == DemoNotificationScope.general,
        ),
        isTrue,
      );
      expect(
        controller
            .forRole(UserRole.transplantCoordinator)
            .any((event) => event.scope == DemoNotificationScope.blood),
        isFalse,
      );
      expect(
        controller
            .forRole(UserRole.auditorComplianceOfficer)
            .every((event) => event.scope == DemoNotificationScope.general),
        isTrue,
      );
    });

    test('read state and mark-all-read only update matching role events', () {
      final controller = DemoNotificationsController();
      final initial = controller.forRole(UserRole.bloodBankOfficer);
      expect(initial.any((event) => event.isUnread), isTrue);

      controller.markAllRead(UserRole.bloodBankOfficer);

      expect(
        controller
            .forRole(UserRole.bloodBankOfficer)
            .every((event) => !event.isUnread),
        isTrue,
      );
      expect(
        controller
            .forRole(UserRole.transplantCoordinator)
            .firstWhere((event) => event.id == 'DEMO-NOTIF-05')
            .isUnread,
        isTrue,
      );
    });
  });

  group('Admin demo controls', () {
    test('rejects unauthorized actions and privileged role escalation', () {
      final controller = AdminDemoController();

      expect(
        () => controller.updateVerification(
          actorRole: UserRole.bloodBankOfficer,
          actorId: 'DEMO-bloodBankOfficer',
          institutionId: controller.institutions.first.id,
          verified: true,
        ),
        throwsStateError,
      );
      expect(
        () => controller.updateUserRole(
          actorRole: UserRole.networkAdministrator,
          actorId: 'DEMO-networkAdministrator',
          userId: 'DEMO-bloodBankOfficer',
          newRole: UserRole.networkAdministrator,
        ),
        throwsStateError,
      );
      expect(
        () => controller.updateUserRole(
          actorRole: UserRole.networkAdministrator,
          actorId: 'DEMO-networkAdministrator',
          userId: 'DEMO-networkAdministrator',
          newRole: UserRole.equipmentCoordinator,
        ),
        throwsStateError,
      );
    });

    test('records allowed demo changes and reset as audit events', () {
      final controller = AdminDemoController();
      final initialAuditCount = controller.auditEntries.length;
      final pending = controller.institutions.firstWhere(
        (institution) => institution.verification != 'Demo-verified',
      );

      controller.updateVerification(
        actorRole: UserRole.networkAdministrator,
        actorId: 'DEMO-networkAdministrator',
        institutionId: pending.id,
        verified: true,
      );
      controller.updateUserRole(
        actorRole: UserRole.networkAdministrator,
        actorId: 'DEMO-networkAdministrator',
        userId: 'DEMO-bloodBankOfficer',
        newRole: UserRole.equipmentCoordinator,
      );
      controller.resetDemoWorkspace(
        actorRole: UserRole.networkAdministrator,
        actorId: 'DEMO-networkAdministrator',
      );

      expect(controller.auditEntries.length, initialAuditCount + 3);
      expect(
        controller.users
            .firstWhere((user) => user.id == 'DEMO-bloodBankOfficer')
            .role,
        UserRole.bloodBankOfficer,
      );
      expect(
        controller.institutions
            .firstWhere((institution) => institution.id == pending.id)
            .verification,
        isNot('Demo-verified'),
      );
    });
  });

  testWidgets('notification page supports category filtering and read status', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.runAsync(
      () => container
          .read(authControllerProvider)
          .signInDemo(UserRole.bloodBankOfficer),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: NotificationsScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('New resource enquiry'), findsOneWidget);
    expect(find.text('Coordination workflow updated'), findsNothing);
    await tester.ensureVisible(find.text('Mark as read').first);
    await tester.pump();
    await tester.tap(find.text('Mark as read').first);
    await tester.pump();
    expect(find.text('Mark as unread').first, findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('notifications-search')),
      'not-a-real-notification',
    );
    await tester.pump();
    expect(find.text('No notifications match these filters.'), findsOneWidget);
  });

  testWidgets('reports identify synthetic data and show role-scoped reports', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.runAsync(
      () => container
          .read(authControllerProvider)
          .signInDemo(UserRole.bloodBankOfficer),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: ThemeData.dark(), home: ReportsScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Blood bank status summary'), findsOneWidget);
    expect(find.text('ICU capacity trend'), findsNothing);
    expect(
      find.textContaining('Synthetic demonstration data only.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'administration workspace exposes controls only to network admins',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.runAsync(
        () => container
            .read(authControllerProvider)
            .signInDemo(UserRole.networkAdministrator),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const AdminScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Administration'), findsOneWidget);
      expect(find.text('Users'), findsOneWidget);
      expect(find.text('Audit log'), findsOneWidget);
      expect(find.textContaining('DEMO ADMINISTRATION ONLY.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
