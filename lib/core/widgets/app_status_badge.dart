import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

enum StatusBadgeVariant {
  active, // Cyan / Teal pulsing
  critical, // Red emergency
  warning, // Amber urgent
  success, // Green operational
  info, // Electric blue
  neutral, // Muted slate
  ai, // Purple cognitive
}

class AppStatusBadge extends StatefulWidget {
  final String label;
  final StatusBadgeVariant variant;
  final IconData? icon;
  final bool isPulsing;
  final bool showDot;

  const AppStatusBadge({
    super.key,
    required this.label,
    this.variant = StatusBadgeVariant.neutral,
    this.icon,
    this.isPulsing = false,
    this.showDot = true,
  });

  @override
  State<AppStatusBadge> createState() => _AppStatusBadgeState();
}

class _AppStatusBadgeState extends State<AppStatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isPulsing ||
        widget.variant == StatusBadgeVariant.critical ||
        widget.variant == StatusBadgeVariant.active) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  _BadgeStyle _resolveStyle() {
    switch (widget.variant) {
      case StatusBadgeVariant.active:
        return const _BadgeStyle(
          bg: Color(0xFF0A2E2B),
          text: AppColors.accentPrimary,
          border: Color(0xFF136E64),
          dot: AppColors.accentPrimary,
        );
      case StatusBadgeVariant.critical:
        return const _BadgeStyle(
          bg: Color(0xFF331619),
          text: Color(0xFFFF7A7A),
          border: Color(0xFF802D34),
          dot: AppColors.danger,
        );
      case StatusBadgeVariant.warning:
        return const _BadgeStyle(
          bg: Color(0xFF332510),
          text: Color(0xFFFFC56E),
          border: Color(0xFF855A1A),
          dot: AppColors.warning,
        );
      case StatusBadgeVariant.success:
        return const _BadgeStyle(
          bg: Color(0xFF0F2E22),
          text: Color(0xFF45DFC3),
          border: Color(0xFF1B6B48),
          dot: AppColors.success,
        );
      case StatusBadgeVariant.info:
        return const _BadgeStyle(
          bg: Color(0xFF0F243B),
          text: Color(0xFF67B0F9),
          border: Color(0xFF1E4E7A),
          dot: AppColors.accentSecondary,
        );
      case StatusBadgeVariant.ai:
        return const _BadgeStyle(
          bg: Color(0xFF26123D),
          text: Color(0xFFC084FC),
          border: Color(0xFF5E2794),
          dot: AppColors.aiPurple,
        );
      case StatusBadgeVariant.neutral:
        return const _BadgeStyle(
          bg: AppColors.bgSecondary,
          text: AppColors.textSecondary,
          border: AppColors.borderSubtle,
          dot: AppColors.textMuted,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _resolveStyle();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: style.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.showDot) ...[
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final opacity =
                    (widget.isPulsing ||
                        widget.variant == StatusBadgeVariant.critical ||
                        widget.variant == StatusBadgeVariant.active)
                    ? _pulseAnimation.value
                    : 1.0;

                return Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: style.dot.withAlpha((opacity * 255).toInt()),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: style.dot.withAlpha((opacity * 140).toInt()),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 6),
          ] else if (widget.icon != null) ...[
            Icon(widget.icon, size: 12, color: style.text),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: style.text,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeStyle {
  final Color bg;
  final Color text;
  final Color border;
  final Color dot;

  const _BadgeStyle({
    required this.bg,
    required this.text,
    required this.border,
    required this.dot,
  });
}
