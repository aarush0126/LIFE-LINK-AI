import 'package:material_ui/material_ui.dart';
import '../theme/app_colors.dart';
import 'app_button.dart';
import 'glass_card.dart';

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    this.icon = Icons.biotech_outlined,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: GlassCard(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.accentPrimary.withAlpha(25),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accentPrimary.withAlpha(70)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentPrimary.withAlpha(40),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 34,
                    color: AppColors.accentPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 22),
                  AppButton(
                    label: actionLabel!,
                    icon: Icons.add_rounded,
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.medium,
                    onPressed: onAction,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
