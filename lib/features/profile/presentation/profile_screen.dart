import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../features/authentication/application/auth_controller.dart';
import '../../../features/authentication/application/auth_session_actions.dart';
import '../../../shared/models/user_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = context.isDesktop;
    final user = ref.watch(authControllerProvider).currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Center(
          child: Text(
            'No active session. Sign in to view your profile.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    final initials = user.fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: GlassCard(
              glowAccent: GlowAccent.cyan,
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.accentPrimary,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.accentPrimary.withAlpha(35),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 26,
                          color: AppColors.accentPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.role.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppStatusBadge(
                    label: user.isVerified
                        ? 'EMAIL VERIFIED (DEMO)'
                        : 'EMAIL NOT VERIFIED',
                    variant: user.isVerified
                        ? StatusBadgeVariant.success
                        : StatusBadgeVariant.warning,
                    showDot: true,
                  ),
                  const SizedBox(height: 28),
                  const Divider(color: AppColors.borderSubtle),
                  const SizedBox(height: 16),

                  _ProfileDetailRow(
                    icon: Icons.badge_outlined,
                    label: 'Demo HPR identifier',
                    value: user.hprId,
                  ),
                  _ProfileDetailRow(
                    icon: Icons.local_hospital_outlined,
                    label: 'Demo institution',
                    value: user.affiliatedHospitalName,
                  ),
                  _ProfileDetailRow(
                    icon: Icons.email_outlined,
                    label: 'Official Institutional Email',
                    value: user.email,
                  ),
                  _ProfileDetailRow(
                    icon: Icons.account_tree_outlined,
                    label: 'Department',
                    value: user.department,
                  ),

                  const SizedBox(height: 28),
                  AppButton(
                    label: 'Sign Out of Command Session',
                    icon: Icons.logout_rounded,
                    variant: AppButtonVariant.danger,
                    isFullWidth: true,
                    onPressed: () async {
                      await signOutAndNavigate(context, ref);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
