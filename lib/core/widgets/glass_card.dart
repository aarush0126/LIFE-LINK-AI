import 'package:material_ui/material_ui.dart';
import '../theme/app_colors.dart';

enum GlowAccent {
  none,
  cyan,
  blue,
  danger,
  warning,
  success,
}

class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final GlowAccent glowAccent;
  final VoidCallback? onTap;
  final bool enableHoverEffect;
  final Color? backgroundColor;
  final Border? border;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 14.0,
    this.glowAccent = GlowAccent.none,
    this.onTap,
    this.enableHoverEffect = true,
    this.backgroundColor,
    this.border,
    this.width,
    this.height,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _isHovered = false;

  Color _getGlowColor() {
    switch (widget.glowAccent) {
      case GlowAccent.cyan:
        return AppColors.accentPrimary.withAlpha(45);
      case GlowAccent.blue:
        return AppColors.accentSecondary.withAlpha(45);
      case GlowAccent.danger:
        return AppColors.danger.withAlpha(45);
      case GlowAccent.warning:
        return AppColors.warning.withAlpha(45);
      case GlowAccent.success:
        return AppColors.success.withAlpha(45);
      case GlowAccent.none:
        return Colors.black.withAlpha(50);
    }
  }

  Color _getBorderColor() {
    if (_isHovered && widget.enableHoverEffect) {
      switch (widget.glowAccent) {
        case GlowAccent.cyan:
          return AppColors.accentPrimary.withAlpha(120);
        case GlowAccent.blue:
          return AppColors.accentSecondary.withAlpha(120);
        case GlowAccent.danger:
          return AppColors.danger.withAlpha(120);
        default:
          return AppColors.borderLight;
      }
    }
    return AppColors.borderSubtle;
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = _getGlowColor();
    final borderColor = _getBorderColor();

    return MouseRegion(
      onEnter: (_) {
        if (widget.enableHoverEffect) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (widget.enableHoverEffect) setState(() => _isHovered = false);
      },
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: widget.width,
          height: widget.height,
          transform: _isHovered && widget.enableHoverEffect
              ? Matrix4.translationValues(0.0, -3.0, 0.0)
              : Matrix4.identity(),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.backgroundColor ??
                (_isHovered && widget.enableHoverEffect
                    ? AppColors.bgCardHover
                    : AppColors.bgCard),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: widget.border ?? Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: glowColor,
                blurRadius: _isHovered ? 24 : 12,
                offset: Offset(0, _isHovered ? 8 : 4),
                spreadRadius: _isHovered ? 1 : 0,
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
