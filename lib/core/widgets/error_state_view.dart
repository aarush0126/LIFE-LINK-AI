import 'package:material_ui/material_ui.dart';
import '../theme/app_colors.dart';
import 'app_button.dart';
import 'glass_card.dart';

class ErrorStateView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final bool showTechnicalDetails;
  final dynamic technicalDetails;

  const ErrorStateView({
    super.key,
    this.title = 'National Telemetry Disruption',
    required this.message,
    this.onRetry,
    this.retryLabel = 'Re-establish Telemetry Gateway',
    this.showTechnicalDetails = false,
    this.technicalDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: GlassCard(
            glowAccent: GlowAccent.danger,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withAlpha(25),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.danger.withAlpha(80)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.danger.withAlpha(50),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    size: 34,
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (showTechnicalDetails && technicalDetails != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.bgInput,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Text(
                      technicalDetails.toString(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
                if (onRetry != null) ...[
                  const SizedBox(height: 24),
                  AppButton(
                    label: retryLabel,
                    icon: Icons.refresh_rounded,
                    variant: AppButtonVariant.danger,
                    size: AppButtonSize.medium,
                    onPressed: onRetry,
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
