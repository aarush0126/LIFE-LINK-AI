import 'package:material_ui/material_ui.dart';
import '../theme/app_colors.dart';

class AppSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final List<String> activeFilters;
  final ValueChanged<String>? onFilterRemoved;

  const AppSearchBar({
    super.key,
    this.hintText = 'Search telemetry, donor organs, hospitals, ICU codes (Ctrl + K)...',
    this.onChanged,
    this.onFilterTap,
    this.activeFilters = const [],
    this.onFilterRemoved,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.bgInput,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle, width: 1),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: (val) {
                    setState(() => _hasText = val.isNotEmpty);
                    widget.onChanged?.call(val);
                  },
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (_hasText)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
                  onPressed: () {
                    _controller.clear();
                    setState(() => _hasText = false);
                    widget.onChanged?.call('');
                  },
                ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: const Text(
                  'Ctrl K',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (widget.onFilterTap != null) ...[
                Container(
                  width: 1,
                  height: 24,
                  color: AppColors.borderSubtle,
                ),
                IconButton(
                  icon: const Icon(Icons.tune_rounded, size: 18, color: AppColors.accentPrimary),
                  tooltip: 'Filter Registry',
                  onPressed: widget.onFilterTap,
                ),
              ],
            ],
          ),
        ),
        if (widget.activeFilters.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: widget.activeFilters.map((filter) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accentPrimary.withAlpha(80)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      filter,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.accentPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => widget.onFilterRemoved?.call(filter),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: AppColors.accentPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
