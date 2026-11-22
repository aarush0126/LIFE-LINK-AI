import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_screen.dart';
import '../../features/ai_assistant/presentation/ai_assistant_screen.dart';
import '../../features/authentication/application/auth_controller.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/authentication/presentation/auth_flow_screens.dart';
import '../../features/blood_bank/presentation/blood_bank_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/dashboard/presentation/dashboard_support_screens.dart';
import '../../features/equipment/presentation/equipment_screen.dart';
import '../../features/hospitals/presentation/hospitals_screen.dart';
import '../../features/icu_beds/presentation/icu_beds_screen.dart';
import '../../features/landing/presentation/landing_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/organ_coordination/presentation/organ_coordination_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/authentication/domain/role_access_policy.dart';
import '../widgets/error_state_view.dart';
import '../widgets/responsive_scaffold.dart';
import 'route_names.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNav');
  final shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shellNav');

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RouteNames.landing,
    refreshListenable: auth,
    redirect: (context, state) {
      final location = state.uri.path;
      final user = auth.currentUser;
      final publicRoutes = {
        RouteNames.landing,
        RouteNames.login,
        RouteNames.register,
        RouteNames.forgotPassword,
      };

      if (location == RouteNames.emailVerification &&
          auth.pendingRegistration == null &&
          user == null) {
        return RouteNames.register;
      }

      if (location == RouteNames.profileSetup) {
        if (user == null) return RouteNames.login;
        if (user.isProfileComplete) return RouteNames.dashboard;
        return null;
      }

      if (user == null) {
        if (publicRoutes.contains(location) ||
            location == RouteNames.emailVerification) {
          return null;
        }
        return RouteNames.login;
      }

      if (!user.isProfileComplete) {
        if (location == RouteNames.landing) return null;
        return RouteNames.profileSetup;
      }

      if (location == RouteNames.landing) return null;
      if (publicRoutes.contains(location) ||
          location == RouteNames.emailVerification) {
        return RouteNames.dashboard;
      }

      if (!RoleAccessPolicy.canAccess(user.role, location)) {
        return RouteNames.dashboard;
      }
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Route Not Found')),
      body: ErrorStateView(
        title: '404 - Page Not Found',
        message:
            'The requested route "${state.uri.toString()}" does not exist in the National Grid.',
        onRetry: () => context.go(RouteNames.dashboard),
        retryLabel: 'Return to Command Dashboard',
      ),
    ),
    routes: [
      GoRoute(
        path: RouteNames.landing,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LandingScreen()),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) => const RegistrationScreen(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.emailVerification,
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: RouteNames.profileSetup,
        builder: (context, state) => const UserProfileSetupScreen(),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return ResponsiveScaffold(
            currentRoute: state.uri.toString(),
            body: child,
          );
        },
        routes: [
          GoRoute(
            path: RouteNames.dashboard,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: RouteNames.reports,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ReportsScreen()),
          ),
          GoRoute(
            path: RouteNames.settings,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
          GoRoute(
            path: RouteNames.hospitals,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HospitalsScreen()),
          ),
          GoRoute(
            path: RouteNames.organCoordination,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: OrganCoordinationScreen()),
          ),
          GoRoute(
            path: RouteNames.bloodBank,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BloodBankScreen()),
          ),
          GoRoute(
            path: RouteNames.icuBeds,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: IcuBedsScreen()),
          ),
          GoRoute(
            path: RouteNames.equipment,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: EquipmentScreen()),
          ),
          GoRoute(
            path: RouteNames.aiAssistant,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AiAssistantScreen()),
          ),
          GoRoute(
            path: RouteNames.notifications,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: NotificationsScreen()),
          ),
          GoRoute(
            path: RouteNames.profile,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
          GoRoute(
            path: RouteNames.admin,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AdminScreen()),
          ),
          GoRoute(
            path: RouteNames.adminAudit,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AdminScreen(auditOnly: true)),
          ),
        ],
      ),
    ],
  );
});
