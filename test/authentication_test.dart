import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_link_ai/core/routing/app_router.dart';
import 'package:life_link_ai/core/routing/route_names.dart';
import 'package:life_link_ai/features/authentication/application/auth_controller.dart';
import 'package:life_link_ai/features/authentication/domain/role_access_policy.dart';
import 'package:life_link_ai/main.dart';
import 'package:life_link_ai/shared/models/user_model.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('Demo authentication', () {
    test('demo sign-in creates a verified fictional role session', () async {
      final controller = AuthController();
      addTearDown(controller.dispose);

      await controller.signInDemo(UserRole.transplantCoordinator);

      expect(controller.currentUser?.role, UserRole.transplantCoordinator);
      expect(controller.currentUser?.email, endsWith('@lifelink.example'));
      expect(controller.currentUser?.isVerified, isTrue);
      expect(controller.currentUser?.isProfileComplete, isTrue);
      expect(controller.currentUser?.toJson(), isNot(contains('password')));
    });

    test('registration requires demo verification and profile setup', () async {
      final controller = AuthController();
      addTearDown(controller.dispose);

      await controller.registerDemo(
        fullName: 'Demo Coordinator',
        email: 'coordinator@example.test',
      );
      expect(controller.currentUser, isNull);
      expect(controller.pendingRegistration?.isVerified, isFalse);

      await controller.verifyEmailDemo();
      expect(controller.currentUser?.isVerified, isTrue);
      expect(controller.currentUser?.isProfileComplete, isFalse);

      await controller.completeDemoProfile(
        role: UserRole.bloodBankOfficer,
        hospitalName: 'Example Hospital',
        department: 'Blood Services',
        hprId: 'DEMO-HPR-9001',
      );
      expect(controller.currentUser?.role, UserRole.bloodBankOfficer);
      expect(controller.currentUser?.isProfileComplete, isTrue);
    });

    test('self-service profile setup cannot assign privileged roles', () async {
      final controller = AuthController();
      addTearDown(controller.dispose);
      await controller.registerDemo(
        fullName: 'Fictional Applicant',
        email: 'applicant@example.test',
      );
      await controller.verifyEmailDemo();

      await expectLater(
        controller.completeDemoProfile(
          role: UserRole.networkAdministrator,
          hospitalName: 'Demo Hospital',
          department: 'Demo Department',
          hprId: 'DEMO-HPR-9002',
        ),
        throwsA(isA<AuthFlowException>()),
      );
      expect(controller.currentUser?.role, UserRole.hospitalAdministrator);
      expect(controller.currentUser?.isProfileComplete, isFalse);
    });
  });

  test('role access policy denies modules outside the assigned role', () {
    expect(
      RoleAccessPolicy.canAccess(
        UserRole.auditorComplianceOfficer,
        RouteNames.bloodBank,
      ),
      isFalse,
    );
    expect(
      RoleAccessPolicy.canAccess(
        UserRole.networkAdministrator,
        RouteNames.admin,
      ),
      isTrue,
    );
    expect(
      RoleAccessPolicy.canAccess(
        UserRole.hospitalAdministrator,
        RouteNames.admin,
      ),
      isFalse,
    );
    expect(
      RoleAccessPolicy.canAccess(
        UserRole.auditorComplianceOfficer,
        RouteNames.admin,
      ),
      isFalse,
    );
    expect(
      RoleAccessPolicy.canAccess(
        UserRole.auditorComplianceOfficer,
        RouteNames.adminAudit,
      ),
      isTrue,
    );
  });

  testWidgets('demo login routes into an authenticated dashboard', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LifeLinkApp(),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Login').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Welcome back'), findsOneWidget);

    await tester.tap(find.text('Continue with Demo Account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(container.read(authControllerProvider).currentUser, isNotNull);
    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      RouteNames.dashboard,
    );
    await tester.pumpAndSettle();

    final router = container.read(routerProvider);
    await tester.tap(find.byTooltip('Recent synthetic notifications'));
    await tester.pumpAndSettle();
    expect(find.text('RECENT SYNTHETIC EVENTS'), findsOneWidget);
    await tester.tap(find.text('View notifications'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      router.routeInformationProvider.value.uri.path,
      RouteNames.notifications,
    );

    await tester.tap(find.byTooltip('User profile menu'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out'), findsOneWidget);
    await tester.tap(find.text('Settings').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(router.routeInformationProvider.value.uri.path, RouteNames.settings);
    expect(
      find.textContaining(
        'Production sign-in targets this environment’s configured API URL.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Production authentication is not configured.'),
      findsNothing,
    );

    router.go(RouteNames.admin);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      router.routeInformationProvider.value.uri.path,
      RouteNames.dashboard,
    );

    router.go(RouteNames.reports);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(router.routeInformationProvider.value.uri.path, RouteNames.reports);

    router.go(RouteNames.settings);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(router.routeInformationProvider.value.uri.path, RouteNames.settings);
  });
}
