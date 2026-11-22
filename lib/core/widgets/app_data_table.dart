import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import 'glass_card.dart';

class AppTableColumn {
  final String title;
  final double? width;
  final bool isNumeric;

  const AppTableColumn({
    required this.title,
    this.width,
    this.isNumeric = false,
  });
}

class AppTableRow {
  final List<Widget> cells;
  final VoidCallback? onTap;

  const AppTableRow({required this.cells, this.onTap});
}

class AppDataTable extends StatelessWidget {
  final List<AppTableColumn> columns;
  final List<AppTableRow> rows;
  final String? emptyMessage;
  final int currentPage;
  final int totalPages;
  final int totalRecords;
  final ValueChanged<int>? onPageChanged;

  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.emptyMessage = 'No telemetry records located.',
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalRecords = 0,
    this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final minimumTableWidth = columns.fold<double>(
      40,
      (width, column) => width + (column.width ?? 180),
    );

    return GlassCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = constraints.maxWidth > minimumTableWidth
              ? constraints.maxWidth
              : minimumTableWidth;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.bgSecondary,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(14),
                            topRight: Radius.circular(14),
                          ),
                          border: Border(
                            bottom: BorderSide(color: AppColors.borderSubtle),
                          ),
                        ),
                        child: Row(
                          children: columns.map((col) {
                            final cellWidget = Text(
                              col.title.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.6,
                              ),
                            );

                            if (col.width != null) {
                              return SizedBox(
                                width: col.width,
                                child: cellWidget,
                              );
                            }
                            return Expanded(child: cellWidget);
                          }).toList(),
                        ),
                      ),
                      if (rows.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              emptyMessage!,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: rows.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 1,
                            color: AppColors.borderSubtle,
                          ),
                          itemBuilder: (context, index) => _HoverableRow(
                            row: rows[index],
                            columns: columns,
                            isEven: index.isEven,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                  border: Border(
                    top: BorderSide(color: AppColors.borderSubtle),
                  ),
                ),
                child: constraints.maxWidth < 560
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Showing ${rows.length} of $totalRecords registered units',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildPagination(),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Showing ${rows.length} of $totalRecords registered units',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          _buildPagination(),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 20),
          color: currentPage > 1
              ? AppColors.textPrimary
              : AppColors.textDisabled,
          onPressed: currentPage > 1
              ? () => onPageChanged?.call(currentPage - 1)
              : null,
        ),
        Text(
          'Page $currentPage of $totalPages',
          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded, size: 20),
          color: currentPage < totalPages
              ? AppColors.textPrimary
              : AppColors.textDisabled,
          onPressed: currentPage < totalPages
              ? () => onPageChanged?.call(currentPage + 1)
              : null,
        ),
      ],
    );
  }
}

class _HoverableRow extends StatefulWidget {
  final AppTableRow row;
  final List<AppTableColumn> columns;
  final bool isEven;

  const _HoverableRow({
    required this.row,
    required this.columns,
    required this.isEven,
  });

  @override
  State<_HoverableRow> createState() => _HoverableRowState();
}

class _HoverableRowState extends State<_HoverableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.row.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.row.onTap,
        child: Container(
          color: _isHovered
              ? AppColors.bgCardHover
              : (widget.isEven
                    ? AppColors.bgCard
                    : AppColors.bgSecondary.withAlpha(120)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: List.generate(widget.row.cells.length, (i) {
              final cell = widget.row.cells[i];
              final col = i < widget.columns.length ? widget.columns[i] : null;

              if (col?.width != null) {
                return SizedBox(width: col!.width, child: cell);
              }
              return Expanded(child: cell);
            }),
          ),
        ),
      ),
    );
  }
}
