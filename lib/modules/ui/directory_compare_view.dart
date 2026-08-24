import 'package:flutter/material.dart';

import '../logic.dart';
import '../models/directory_diff_result.dart';
import '../utils.dart';
import 'diff_view.dart';
import 'language_scope.dart';
import 'styles.dart';

class DirectoryCompareView extends StatelessWidget {
  final CompareController controller;

  const DirectoryCompareView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.activeDrillDownPair != null) {
      return _DrillDownDiffPane(controller: controller);
    }
    return _DirectoryExplorerPane(controller: controller);
  }
}

class _DirectoryExplorerPane extends StatelessWidget {
  final CompareController controller;
  const _DirectoryExplorerPane({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final isDark = context.themeProvider.isDark;
    final res = controller.directoryResult;

    if (res == null) return const SizedBox.shrink();
    final stats = res.stats;
    final pairs = controller.filteredDirectoryPairs;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top HUD Summary Chips
          _buildSummaryBar(context, c, stats, isDark),
          const SizedBox(height: 12),

          // 2. Search Bar & Filter Tabs
          _buildFilterAndSearchBar(context, c, stats, isDark),
          const SizedBox(height: 12),

          // 3. Matched Pairs List
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: c.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.borderDefault),
              ),
              clipBehavior: Clip.antiAlias,
              child: pairs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 42,
                            color: c.textSecondary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr('no_matching_files'),
                            style: TextStyle(
                              color: c.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: pairs.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: c.borderDefault.withValues(alpha: 0.5),
                      ),
                      itemBuilder: (context, idx) {
                        final pair = pairs[idx];
                        return _FilePairRow(pair: pair, controller: controller);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(
    BuildContext context,
    AppColors c,
    DirectoryDiffStats stats,
    bool isDark,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _StatBadge(
            label: context.tr('dir_summary_total'),
            count: stats.totalFiles,
            color: c.accent,
            icon: Icons.folder_copy_rounded,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _StatBadge(
            label: context.tr('dir_summary_modified'),
            count: stats.modified,
            color: const Color(0xFFF59E0B),
            icon: Icons.edit_document,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _StatBadge(
            label: context.tr('dir_summary_similar'),
            count: stats.similarName,
            color: const Color(0xFF0284C7),
            icon: Icons.auto_fix_high_rounded,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _StatBadge(
            label: context.tr('dir_summary_added'),
            count: stats.rightOnly,
            color: const Color(0xFF22C55E),
            icon: Icons.add_circle_outline_rounded,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _StatBadge(
            label: context.tr('dir_summary_removed'),
            count: stats.leftOnly,
            color: const Color(0xFFEF4444),
            icon: Icons.remove_circle_outline_rounded,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _StatBadge(
            label: context.tr('dir_summary_identical'),
            count: stats.identical,
            color: const Color(0xFF64748B),
            icon: Icons.check_circle_outline_rounded,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndSearchBar(
    BuildContext context,
    AppColors c,
    DirectoryDiffStats stats,
    bool isDark,
  ) {
    final activeFilter = controller.directoryFilter;

    return Row(
      children: [
        // Filter Tabs
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterTab(
                  label: '${context.tr('filter_all')} (${stats.totalFiles})',
                  isActive: activeFilter == 'all',
                  onTap: () => controller.setDirectoryFilter('all'),
                ),
                const SizedBox(width: 6),
                _FilterTab(
                  label: '${context.tr('filter_modified')} (${stats.modified})',
                  isActive: activeFilter == 'modified',
                  onTap: () => controller.setDirectoryFilter('modified'),
                ),
                const SizedBox(width: 6),
                _FilterTab(
                  label:
                      '${context.tr('filter_similar')} (${stats.similarName})',
                  isActive: activeFilter == 'similar',
                  onTap: () => controller.setDirectoryFilter('similar'),
                ),
                const SizedBox(width: 6),
                _FilterTab(
                  label:
                      '${context.tr('filter_left_only')} (${stats.leftOnly})',
                  isActive: activeFilter == 'leftOnly',
                  onTap: () => controller.setDirectoryFilter('leftOnly'),
                ),
                const SizedBox(width: 6),
                _FilterTab(
                  label:
                      '${context.tr('filter_right_only')} (${stats.rightOnly})',
                  isActive: activeFilter == 'rightOnly',
                  onTap: () => controller.setDirectoryFilter('rightOnly'),
                ),
                const SizedBox(width: 6),
                _FilterTab(
                  label:
                      '${context.tr('filter_identical')} (${stats.identical})',
                  isActive: activeFilter == 'identical',
                  onTap: () => controller.setDirectoryFilter('identical'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Quick Search Field
        SizedBox(
          width: 260,
          height: 34,
          child: TextField(
            onChanged: (v) => controller.setDirectorySearchQuery(v),
            style: TextStyle(fontSize: 12, color: c.textPrimary),
            decoration: InputDecoration(
              hintText: context.tr('search_files_hint'),
              hintStyle: TextStyle(
                fontSize: 11,
                color: c.textSecondary.withValues(alpha: 0.6),
              ),
              prefixIcon: Icon(Icons.search, size: 16, color: c.textSecondary),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              filled: true,
              fillColor: c.cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: c.borderDefault),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: c.borderDefault),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: c.accent),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final bool isDark;

  const _StatBadge({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? c.accent : c.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? c.accent : c.borderDefault),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? Colors.white : c.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _FilePairRow extends StatelessWidget {
  final MatchedFilePair pair;
  final CompareController controller;

  const _FilePairRow({required this.pair, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final isDark = context.themeProvider.isDark;

    final leftRel = pair.leftRelativePath;
    final rightRel = pair.rightRelativePath;
    final status = pair.status;

    return InkWell(
      onTap: () => controller.selectDrillDownPair(pair),
      hoverColor: c.cardHoverBg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Format icon
            _buildFormatIcon(pair.fileExtension),
            const SizedBox(width: 12),

            // Left File Info
            Expanded(
              child: InkWell(
                onTap: pair.leftFullPath != null
                    ? () => revealInExplorer(pair.leftFullPath)
                    : null,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              leftRel ?? '(None)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: leftRel != null
                                    ? c.textPrimary
                                    : c.textSecondary.withValues(alpha: 0.4),
                                fontFamily: 'Consolas',
                                decoration: pair.leftFullPath != null
                                    ? TextDecoration.underline
                                    : null,
                                decorationStyle: TextDecorationStyle.dotted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (pair.leftFullPath != null) ...[
                            const SizedBox(width: 4),
                            Tooltip(
                              message:
                                  '${context.tr('reveal_in_explorer')}\n${pair.leftFullPath}',
                              child: Icon(
                                Icons.open_in_new_rounded,
                                size: 11,
                                color: c.accent.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (pair.leftSizeBytes != null)
                        Text(
                          _formatBytes(pair.leftSizeBytes!),
                          style: TextStyle(
                            fontSize: 10,
                            color: c.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Status Badge
            _buildStatusBadge(context, status, pair.similarityScore, isDark),

            const SizedBox(width: 12),

            // Right File Info
            Expanded(
              child: InkWell(
                onTap: pair.rightFullPath != null
                    ? () => revealInExplorer(pair.rightFullPath)
                    : null,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              rightRel ?? '(None)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: rightRel != null
                                    ? c.textPrimary
                                    : c.textSecondary.withValues(alpha: 0.4),
                                fontFamily: 'Consolas',
                                decoration: pair.rightFullPath != null
                                    ? TextDecoration.underline
                                    : null,
                                decorationStyle: TextDecorationStyle.dotted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (pair.rightFullPath != null) ...[
                            const SizedBox(width: 4),
                            Tooltip(
                              message:
                                  '${context.tr('reveal_in_explorer')}\n${pair.rightFullPath}',
                              child: Icon(
                                Icons.open_in_new_rounded,
                                size: 11,
                                color: c.accent.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (pair.rightSizeBytes != null)
                        Text(
                          _formatBytes(pair.rightSizeBytes!),
                          style: TextStyle(
                            fontSize: 10,
                            color: c.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Diff stats count
            if (pair.diffStats != null && pair.hasDifferences)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (pair.diffStats!.added > 0)
                    Text(
                      '+${pair.diffStats!.added} ',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF22C55E),
                        fontFamily: 'Consolas',
                      ),
                    ),
                  if (pair.diffStats!.removed > 0)
                    Text(
                      '-${pair.diffStats!.removed} ',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEF4444),
                        fontFamily: 'Consolas',
                      ),
                    ),
                ],
              ),

            const SizedBox(width: 10),

            // Action Button
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 13),
              tooltip: context.tr('view_diff_action'),
              color: c.accent,
              onPressed: () => controller.selectDrillDownPair(pair),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatIcon(String ext) {
    final color = switch (ext.toLowerCase()) {
      'json' => const Color(0xFFD97706),
      'dart' => const Color(0xFF0284C7),
      'docx' => const Color(0xFF2563EB),
      'xlsx' => const Color(0xFF16A34A),
      'pdf' => const Color(0xFFDC2626),
      'md' => const Color(0xFF7C3AED),
      _ => const Color(0xFF64748B),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        ext.toUpperCase().isEmpty ? 'FILE' : ext.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
          fontFamily: 'Consolas',
        ),
      ),
    );
  }

  Widget _buildStatusBadge(
    BuildContext context,
    FilePairStatus status,
    double score,
    bool isDark,
  ) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case FilePairStatus.identical:
        color = const Color(0xFF64748B);
        text = context.tr('status_identical');
        icon = Icons.check_circle_outline_rounded;
      case FilePairStatus.modified:
        color = const Color(0xFFF59E0B);
        text = context.tr('status_modified');
        icon = Icons.edit_note_rounded;
      case FilePairStatus.similarName:
        color = const Color(0xFF0284C7);
        final pct = (score * 100).round();
        text = '${context.tr('status_similar')} ($pct%)';
        icon = Icons.auto_fix_high_rounded;
      case FilePairStatus.leftOnly:
        color = const Color(0xFFEF4444);
        text = context.tr('status_left_only');
        icon = Icons.remove_circle_outline_rounded;
      case FilePairStatus.rightOnly:
        color = const Color(0xFF22C55E);
        text = context.tr('status_right_only');
        icon = Icons.add_circle_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _DrillDownDiffPane extends StatelessWidget {
  final CompareController controller;

  const _DrillDownDiffPane({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final pair = controller.activeDrillDownPair!;
    final diff = pair.diffResult;

    final leftName = pair.leftRelativePath ?? '(Empty)';
    final rightName = pair.rightRelativePath ?? '(Empty)';

    return Column(
      children: [
        // Breadcrumb & Next/Prev navigation Header
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: c.bgSecondary,
            border: Border(bottom: BorderSide(color: c.borderDefault)),
          ),
          child: Row(
            children: [
              // Back button
              OutlinedButton.icon(
                onPressed: () => controller.clearDrillDown(),
                icon: const Icon(Icons.arrow_back_rounded, size: 14),
                label: Text(
                  context.tr('back_to_folder_list'),
                  style: const TextStyle(fontSize: 11.5),
                ),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: c.borderDefault),
                  foregroundColor: c.textPrimary,
                ),
              ),
              const SizedBox(width: 14),

              // Breadcrumb path title
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.folder_open_rounded, size: 16, color: c.accent),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '$leftName  ⟷  $rightName',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                          fontFamily: 'Consolas',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // Prev / Next file buttons
              IconButton(
                icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                tooltip: context.tr('prev_file_pair'),
                onPressed: () => controller.prevDrillDownPair(),
                color: c.accent,
              ),
              IconButton(
                icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                tooltip: context.tr('next_file_pair'),
                onPressed: () => controller.nextDrillDownPair(),
                color: c.accent,
              ),
            ],
          ),
        ),

        // Diff View Body
        Expanded(
          child: diff == null
              ? Center(child: CircularProgressIndicator(color: c.accent))
              : DiffView(
                  result: diff,
                  leftLabel: leftName,
                  rightLabel: rightName,
                  leftPath: pair.leftFullPath,
                  rightPath: pair.rightFullPath,
                ),
        ),
      ],
    );
  }
}
