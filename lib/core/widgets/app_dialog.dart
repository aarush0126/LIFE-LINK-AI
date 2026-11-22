import 'package:material_ui/material_ui.dart';
import '../theme/app_colors.dart';
import 'app_button.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color iconColor;
  final Widget content;
  final String? confirmLabel;
  final VoidCallback? onConfirm;
  final String cancelLabel;
  final VoidCallback? onCancel;
  final bool isDestructive;
  final double maxWidth;

  const AppDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor = AppColors.accentPrimary,
    required this.content,
    this.confirmLabel,
    this.onConfirm,
    this.cancelLabel = 'Cancel',
    this.onCancel,
    this.isDestructive = false,
    this.maxWidth = 520,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    IconData? icon,
    Color iconColor = AppColors.accentPrimary,
    required Widget content,
    String? confirmLabel,
    VoidCallback? onConfirm,
    String cancelLabel = 'Cancel',
    VoidCallback? onCancel,
    bool isDestructive = false,
    double maxWidth = 520,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => AppDialog(
        title: title,
        subtitle: subtitle,
        icon: icon,
        iconColor: iconColor,
        content: content,
        confirmLabel: confirmLabel,
        onConfirm: onConfirm,
        cancelLabel: cancelLabel,
        onCancel: onCancel,
        isDestructive: isDestructive,
        maxWidth: maxWidth,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDestructive
                  ? AppColors.danger.withAlpha(100)
                  : AppColors.borderLight,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDestructive ? AppColors.danger : AppColors.accentPrimary)
                    .withAlpha(40),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dialog Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isDestructive ? AppColors.danger : iconColor).withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: (isDestructive ? AppColors.danger : iconColor).withAlpha(80),
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: isDestructive ? AppColors.danger : iconColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              subtitle!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                      onPressed: onCancel ?? () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.borderSubtle),

              // Dialog Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: content,
                ),
              ),

              const Divider(height: 1, color: AppColors.borderSubtle),

              // Action Buttons Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                      label: cancelLabel,
                      variant: AppButtonVariant.ghost,
                      size: AppButtonSize.medium,
                      onPressed: onCancel ?? () => Navigator.of(context).pop(),
                    ),
                    if (confirmLabel != null) ...[
                      const SizedBox(width: 12),
                      AppButton(
                        label: confirmLabel!,
                        variant: isDestructive
                            ? AppButtonVariant.danger
                            : AppButtonVariant.primary,
                        size: AppButtonSize.medium,
                        onPressed: onConfirm,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
