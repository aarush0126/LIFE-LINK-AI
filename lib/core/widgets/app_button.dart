import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

enum AppButtonVariant {
  primary, // Neon cyan gradient fill
  secondary, // Glass outline with border
  danger, // Emergency crimson glow
  ghost, // Minimalist transparent
}

enum AppButtonSize { small, medium, large }

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool isFullWidth;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isHovered = false;

  EdgeInsets _getPadding() {
    switch (widget.size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 14, vertical: 8);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 18, vertical: 12);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  double _getFontSize() {
    switch (widget.size) {
      case AppButtonSize.small:
        return 12.0;
      case AppButtonSize.medium:
        return 13.0;
      case AppButtonSize.large:
        return 14.0;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case AppButtonSize.small:
        return 14.0;
      case AppButtonSize.medium:
        return 16.0;
      case AppButtonSize.large:
        return 18.0;
    }
  }

  BoxDecoration _getDecoration() {
    final borderRadius = BorderRadius.circular(10);

    switch (widget.variant) {
      case AppButtonVariant.primary:
        return BoxDecoration(
          borderRadius: borderRadius,
          gradient: LinearGradient(
            colors: _isHovered
                ? [AppColors.accentPrimaryLight, AppColors.accentPrimary]
                : [AppColors.accentPrimary, const Color(0xFF0EA594)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentPrimary.withAlpha(_isHovered ? 100 : 50),
              blurRadius: _isHovered ? 16 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        );

      case AppButtonVariant.secondary:
        return BoxDecoration(
          borderRadius: borderRadius,
          color: _isHovered ? AppColors.bgCardHover : AppColors.bgCard,
          border: Border.all(
            color: _isHovered
                ? AppColors.accentPrimary.withAlpha(120)
                : AppColors.borderLight,
            width: 1,
          ),
        );

      case AppButtonVariant.danger:
        return BoxDecoration(
          borderRadius: borderRadius,
          gradient: LinearGradient(
            colors: _isHovered
                ? [const Color(0xFFFF7A7A), AppColors.danger]
                : [AppColors.danger, const Color(0xFFC73636)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.danger.withAlpha(_isHovered ? 110 : 60),
              blurRadius: _isHovered ? 16 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        );

      case AppButtonVariant.ghost:
        return BoxDecoration(
          borderRadius: borderRadius,
          color: _isHovered ? AppColors.bgSecondary : Colors.transparent,
        );
    }
  }

  Color _getTextColor() {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return AppColors.bgPrimary;
      case AppButtonVariant.secondary:
        return _isHovered ? AppColors.accentPrimary : AppColors.textPrimary;
      case AppButtonVariant.danger:
        return Colors.white;
      case AppButtonVariant.ghost:
        return _isHovered ? AppColors.accentPrimary : AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _getTextColor();
    final padding = _getPadding();
    final fontSize = _getFontSize();
    final iconSize = _getIconSize();

    Widget buttonContent = Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: iconSize, color: textColor),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
        if (widget.trailingIcon != null && !widget.isLoading) ...[
          const SizedBox(width: 8),
          Icon(widget.trailingIcon, size: iconSize, color: textColor),
        ],
      ],
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: padding,
          decoration: _getDecoration(),
          child: buttonContent,
        ),
      ),
    );
  }
}
