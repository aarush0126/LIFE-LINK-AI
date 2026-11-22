import 'package:material_ui/material_ui.dart';

enum BadgeVariant {
  success,
  warning,
  danger,
  info,
  neutral,
}

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;
  final IconData? icon;
  final bool showDot;

  const StatusBadge({
    super.key,
    required this.label,
    this.variant = BadgeVariant.neutral,
    this.icon,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colors.foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            Icon(icon, size: 13, color: colors.foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: colors.foreground,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeColors _getColors(BuildContext context) {
    switch (variant) {
      case BadgeVariant.success:
        return const _BadgeColors(
          background: Color(0xFFE8F5E9),
          foreground: Color(0xFF2E7D32),
          border: Color(0xFFA5D6A7),
        );
      case BadgeVariant.warning:
        return const _BadgeColors(
          background: Color(0xFFFFF8E1),
          foreground: Color(0xFFF57F17),
          border: Color(0xFFFFE082),
        );
      case BadgeVariant.danger:
        return const _BadgeColors(
          background: Color(0xFFFFEBEE),
          foreground: Color(0xFFC62828),
          border: Color(0xFFEF9A9A),
        );
      case BadgeVariant.info:
        return const _BadgeColors(
          background: Color(0xFFE3F2FD),
          foreground: Color(0xFF1565C0),
          border: Color(0xFF90CAF9),
        );
      case BadgeVariant.neutral:
        return const _BadgeColors(
          background: Color(0xFFF1F5F9),
          foreground: Color(0xFF475569),
          border: Color(0xFFCBD5E1),
        );
    }
  }
}

class _BadgeColors {
  final Color background;
  final Color foreground;
  final Color border;

  const _BadgeColors({
    required this.background,
    required this.foreground,
    required this.border,
  });
}
