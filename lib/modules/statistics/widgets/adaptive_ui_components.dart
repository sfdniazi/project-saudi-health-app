import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';
import '../utils/responsive_layout_utils.dart';

/// Collapsible section widget with responsive behavior
class CollapsibleSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final bool isCollapsed;
  final VoidCallback onToggle;
  final IconData? leadingIcon;
  final Widget? trailing;
  final bool showToggleButton;
  final EdgeInsets padding;

  const CollapsibleSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    required this.isCollapsed,
    required this.onToggle,
    this.leadingIcon,
    this.trailing,
    this.showToggleButton = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: context.responsivePadding(const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: showToggleButton ? onToggle : null,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Container(
                padding: context.responsivePadding(padding),
                child: Row(
                  children: [
                    if (leadingIcon != null) ...[
                      Icon(
                        leadingIcon,
                        color: AppTheme.primaryGreen,
                        size: context.responsiveFontSize(20),
                      ),
                      SizedBox(width: context.responsivePadding().left * 0.5),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              fontSize: context.responsiveFontSize(18),
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                                fontSize: context.responsiveFontSize(14),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      SizedBox(width: context.responsivePadding().left * 0.5),
                      trailing!,
                    ],
                    if (showToggleButton) ...[
                      SizedBox(width: context.responsivePadding().left * 0.5),
                      AnimatedRotation(
                        turns: isCollapsed ? 0 : 0.5,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: AppTheme.textSecondary,
                          size: context.responsiveFontSize(24),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          
          // Content with animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: isCollapsed ? 0 : null,
            child: AnimatedOpacity(
              opacity: isCollapsed ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              child: isCollapsed 
                ? const SizedBox.shrink()
                : child,
            ),
          ),
        ],
      ),
    );
  }
}

/// View mode selector widget
class ViewModeSelector extends StatelessWidget {
  final ViewMode currentMode;
  final Function(ViewMode) onModeChanged;
  final bool showLabels;

  const ViewModeSelector({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: context.responsivePadding(const EdgeInsets.all(4)),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ViewMode.values.map((mode) {
          final isSelected = mode == currentMode;
          return GestureDetector(
            onTap: () => onModeChanged(mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: context.responsivePadding(
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getIconForMode(mode),
                    size: context.responsiveFontSize(16),
                    color: isSelected ? Colors.white : AppTheme.primaryGreen,
                  ),
                  if (showLabels && context.isTabletOrLarger) ...[
                    const SizedBox(width: 6),
                    Text(
                      _getLabelForMode(mode),
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: context.responsiveFontSize(12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getIconForMode(ViewMode mode) {
    switch (mode) {
      case ViewMode.detailed:
        return Icons.view_list;
      case ViewMode.compact:
        return Icons.view_agenda;
      case ViewMode.minimal:
        return Icons.view_headline;
    }
  }

  String _getLabelForMode(ViewMode mode) {
    switch (mode) {
      case ViewMode.detailed:
        return 'Detailed';
      case ViewMode.compact:
        return 'Compact';
      case ViewMode.minimal:
        return 'Minimal';
    }
  }
}

/// Chart display mode selector
class ChartDisplayModeSelector extends StatelessWidget {
  final ChartDisplayMode currentMode;
  final Function(ChartDisplayMode) onModeChanged;

  const ChartDisplayModeSelector({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ChartDisplayMode.values.map((mode) {
          final isSelected = mode == currentMode;
          return GestureDetector(
            onTap: () => onModeChanged(mode),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ] : null,
              ),
              child: Icon(
                _getIconForChartMode(mode),
                size: 14,
                color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getIconForChartMode(ChartDisplayMode mode) {
    switch (mode) {
      case ChartDisplayMode.full:
        return Icons.fullscreen;
      case ChartDisplayMode.compressed:
        return Icons.compress;
      case ChartDisplayMode.overview:
        return Icons.dashboard;
    }
  }
}

/// Responsive data table with delete functionality
class ResponsiveDataTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final bool sortAscending;
  final int? sortColumnIndex;
  final Function(int, bool)? onSort;
  final double? columnSpacing;
  final EdgeInsets? padding;
  final bool showDeleteColumn;
  final Function(int)? onDelete;
  final Set<int> deletingRows;
  final bool isCompactMode;

  const ResponsiveDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.sortAscending = true,
    this.sortColumnIndex,
    this.onSort,
    this.columnSpacing,
    this.padding,
    this.showDeleteColumn = false,
    this.onDelete,
    this.deletingRows = const {},
    this.isCompactMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveColumnSpacing = columnSpacing ?? 
      (context.isMobile ? 12 : 24);
    
    final effectiveColumns = List<DataColumn>.from(columns);
    final effectiveRows = List<DataRow>.from(rows);

    // Add delete column if needed
    if (showDeleteColumn && onDelete != null) {
      effectiveColumns.add(
        DataColumn(
          label: Icon(
            Icons.delete_outline,
            size: context.responsiveFontSize(16),
            color: Colors.grey.shade600,
          ),
        ),
      );

      // Add delete buttons to rows
      for (int i = 0; i < effectiveRows.length; i++) {
        final row = effectiveRows[i];
        final isDeleting = deletingRows.contains(i);
        
        effectiveRows[i] = DataRow(
          cells: [
            ...row.cells,
            DataCell(
              isDeleting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.red.shade400,
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      Icons.delete,
                      color: Colors.red.shade400,
                      size: context.responsiveFontSize(16),
                    ),
                    onPressed: isDeleting ? null : () => onDelete!(i),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
            ),
          ],
          selected: row.selected,
          onSelectChanged: row.onSelectChanged,
        );
      }
    }

    if (context.isMobile && isCompactMode) {
      // Use ListView for mobile compact mode
      return _buildMobileCompactView(context, effectiveRows);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width - 32,
        ),
        child: DataTable(
          columns: effectiveColumns,
          rows: effectiveRows,
          sortAscending: sortAscending,
          sortColumnIndex: sortColumnIndex,
          columnSpacing: responsiveColumnSpacing,
          horizontalMargin: context.responsivePadding().left,
          headingRowHeight: ResponsiveLayoutUtils.calculateTableRowHeight(
            context: context,
            isCompactMode: isCompactMode,
          ),
          dataRowHeight: ResponsiveLayoutUtils.calculateTableRowHeight(
            context: context,
            isCompactMode: isCompactMode,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCompactView(BuildContext context, List<DataRow> rows) {
    return Column(
      children: rows.asMap().entries.map((entry) {
        final index = entry.key;
        final row = entry.value;
        final isDeleting = deletingRows.contains(index);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < row.cells.length - (showDeleteColumn ? 1 : 0); i++)
                      if (i < columns.length)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _getColumnLabel(columns[i].label),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: row.cells[i].child,
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
              if (showDeleteColumn && onDelete != null) ...[
                const SizedBox(width: 8),
                isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: Colors.red.shade400,
                        size: 20,
                      ),
                      onPressed: () => onDelete!(index),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getColumnLabel(Widget label) {
    if (label is Text) {
      return label.data ?? '';
    }
    return '';
  }
}

/// Pagination controls widget
class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final bool hasMoreData;
  final int itemsPerPage;
  final int totalItems;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.hasMoreData,
    required this.itemsPerPage,
    required this.totalItems,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: context.responsivePadding(const EdgeInsets.all(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Items info
          Text(
            'Showing ${(currentPage * itemsPerPage) + 1}-${((currentPage + 1) * itemsPerPage).clamp(1, totalItems)} of $totalItems',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: context.responsiveFontSize(12),
            ),
          ),
          
          // Page controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
                icon: const Icon(Icons.chevron_left),
                color: AppTheme.primaryGreen,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${currentPage + 1} / $totalPages',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: context.responsiveFontSize(12),
                  ),
                ),
              ),
              IconButton(
                onPressed: (currentPage < totalPages - 1) ? () => onPageChanged(currentPage + 1) : null,
                icon: const Icon(Icons.chevron_right),
                color: AppTheme.primaryGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Delete confirmation dialog
class DeleteConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool showUndoOption;

  const DeleteConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
    required this.onCancel,
    this.showUndoOption = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.delete_outline,
            color: Colors.red.shade400,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: context.responsiveFontSize(18),
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: context.responsiveFontSize(14),
            ),
          ),
          if (showUndoOption) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can undo this action within 10 seconds',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade600,
                        fontSize: context.responsiveFontSize(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text(
            'Cancel',
            style: TextStyle(fontSize: context.responsiveFontSize(14)),
          ),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade400,
            foregroundColor: Colors.white,
          ),
          child: Text(
            'Delete',
            style: TextStyle(fontSize: context.responsiveFontSize(14)),
          ),
        ),
      ],
    );
  }
}
