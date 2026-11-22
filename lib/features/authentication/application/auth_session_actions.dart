import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_names.dart';
import '../data/auth_api_service.dart';
import 'auth_controller.dart';

Future<void> signOutAndNavigate(BuildContext context, WidgetRef ref) async {
  final warning = await terminateApiSession(
    service: ref.read(authApiServiceProvider),
    controller: ref.read(authControllerProvider),
  );
  if (!context.mounted) return;
  context.go(RouteNames.login);
  if (warning != null) {
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(warning)));
  }
}
