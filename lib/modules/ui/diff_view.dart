import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/diff_result.dart';
import '../utils.dart';
import 'language_scope.dart';
import 'styles.dart';

enum _PaneSide { left, right }

enum _ViewMode { split, unified }

/// Diff viewer supporting both Side-by-Side (Split) and Unified modes,
/// intra-line word/character highlighting, difference navigation (F7 / Shift+F7),
/// and synchronized scrolling.
class DiffView extends StatefulWidget {
  final DiffResult result;
  final String leftLabel;
  final String rightLabel;
  final String? leftPath;
  final String? rightPath;

  const DiffView({
    super.key,
    required this.result,
    required this.leftLabel,
    required this.rightLabel,
    this.leftPath,
    this.rightPath,
  });

  @override
  State<DiffView> createState() => _DiffViewState();
}

class _DiffViewState extends State<DiffView> {
  final _leftController = ScrollController();
  final _rightController = ScrollController();
  final _unifiedController = ScrollController();
  bool _syncing = false;
  _ViewMode _viewMode = _ViewMode.split;
  int _currentDiffNavIndex = -1;
  late final List<int> _diffLineIndices;

  @override
  void initState() {
    super.initState();
    _leftController.addListener(() => _sync(_leftController, _rightController));
    _rightController.addListener(
      () => _sync(_rightController, _leftController),
    );

    _diffLineIndices = [];
    for (var i = 0; i < widget.result.lines.length; i++) {
      if (widget.result.lines[i].type != DiffType.equal) {
        _diffLineIndices.add(i);
      }
    }
  }

  void _sync(ScrollController source, ScrollController target) {
    if (_syncing || !target.hasClients || !source.hasClients) return;
    final clamped = source.offset.clamp(0.0, target.position.maxScrollExtent);
    if (clamped == target.offset) return;
    _syncing = true;
    target.jumpTo(clamped);
    _syncing = false;
  }

  void _nextDiff() {
    if (_diffLineIndices.isEmpty) return;
    setState(() {
      _currentDiffNavIndex =
          (_currentDiffNavIndex + 1) % _diffLineIndices.length;
    });
    _scrollToLineIndex(_diffLineIndices[_currentDiffNavIndex]);
  }

  void _prevDiff() {
    if (_diffLineIndices.isEmpty) return;
    setState(() {
      _currentDiffNavIndex =
          (_currentDiffNavIndex - 1 + _diffLineIndices.length) %
          _diffLineIndices.length;
    });
    _scrollToLineIndex(_diffLineIndices[_currentDiffNavIndex]);
  }

  void _scrollToLineIndex(int lineIdx) {
    var rowOffset = 0.0;
    for (var i = 0; i < lineIdx; i++) {
      rowOffset += widget.result.lines[i].type == DiffType.modify ? 48 : 24;
    }
    final targetOffset = rowOffset - 80.0;
    final offset = targetOffset.clamp(0.0, double.infinity);

    if (_viewMode == _ViewMode.split) {
      if (_leftController.hasClients) {
        _leftController.animateTo(
          offset.clamp(0.0, _leftController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    } else {
      if (_unifiedController.hasClients) {
        _unifiedController.animateTo(
          offset.clamp(0.0, _unifiedController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  void dispose() {
    _leftController.dispose();
    _rightController.dispose();
    _unifiedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f7): _nextDiff,
        const SingleActivator(LogicalKeyboardKey.f7, shift: true): _prevDiff,
      },
      child: Focus(
        autofocus: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DiffStatsBar(
              stats: widget.result.stats,
              viewMode: _viewMode,
              diffCount: _diffLineIndices.length,
              currentDiffIdx: _currentDiffNavIndex,
              onNextDiff: _nextDiff,
              onPrevDiff: _prevDiff,
              onViewModeChanged: (mode) => setState(() => _viewMode = mode),
            ),
            Expanded(
              child: _viewMode == _ViewMode.split
                  ? Row(
                      children: [
                        Expanded(
                          child: _DiffPane(
                            controller: _leftController,
                            lines: widget.result.lines,
                            side: _PaneSide.left,
                            label: widget.leftLabel,
                            path: widget.leftPath,
                            highlightIndex:
                                _currentDiffNavIndex >= 0 &&
                                    _currentDiffNavIndex <
                                        _diffLineIndices.length
                                ? _diffLineIndices[_currentDiffNavIndex]
                                : -1,
                          ),
                        ),
                        VerticalDivider(width: 1, color: c.borderDefault),
                        Expanded(
                          child: _DiffPane(
                            controller: _rightController,
                            lines: widget.result.lines,
                            side: _PaneSide.right,
                            label: widget.rightLabel,
                            path: widget.rightPath,
                            highlightIndex:
                                _currentDiffNavIndex >= 0 &&
                                    _currentDiffNavIndex <
                                        _diffLineIndices.length
                                ? _diffLineIndices[_currentDiffNavIndex]
                                : -1,
                          ),
                        ),
                      ],
                    )
                  : _UnifiedDiffView(
                      controller: _unifiedController,
                      lines: widget.result.lines,
                      leftLabel: widget.leftLabel,
                      rightLabel: widget.rightLabel,
                      leftPath: widget.leftPath,
                      rightPath: widget.rightPath,
                      highlightIndex:
                          _currentDiffNavIndex >= 0 &&
                              _currentDiffNavIndex < _diffLineIndices.length
                          ? _diffLineIndices[_currentDiffNavIndex]
                          : -1,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiffStatsBar extends StatelessWidget {
  final DiffStats stats;
  final _ViewMode viewMode;
  final int diffCount;
  final int currentDiffIdx;
  final VoidCallback onNextDiff;
  final VoidCallback onPrevDiff;
  final ValueChanged<_ViewMode> onViewModeChanged;

  const _DiffStatsBar({
    required this.stats,
    required this.viewMode,
    required this.diffCount,
    required this.currentDiffIdx,
    required this.onNextDiff,
    required this.onPrevDiff,
    required this.onViewModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: c.sidebarBg,
        border: Border(bottom: BorderSide(color: c.borderDefault)),
      ),
      child: Row(
        children: [
          _StatChip(
            icon: Icons.add_rounded,
            label: '+${stats.added} ${context.tr('added_suffix')}',
            color: c.diffAdded,
            textColor: c.textPrimary,
          ),
          const SizedBox(width: 8),
          _StatChip(
            icon: Icons.remove_rounded,
            label: '-${stats.removed} ${context.tr('removed_suffix')}',
            color: c.diffRemoved,
            textColor: c.textPrimary,
          ),
          const SizedBox(width: 8),
          _StatChip(
            icon: Icons.edit_rounded,
            label: '${stats.modified} ${context.tr('modified_suffix')}',
            color: c.diffModified,
            textColor: c.textPrimary,
          ),
          const SizedBox(width: 16),

          // Diff Navigation Controls
          if (diffCount > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: c.bgPrimary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.borderDefault),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: context.tr('prev_diff_tooltip'),
                    child: InkWell(
                      onTap: onPrevDiff,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          size: 15,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      currentDiffIdx >= 0
                          ? '${currentDiffIdx + 1}/$diffCount'
                          : '$diffCount diffs',
                      style: TextStyle(
                        fontSize: 11,
                        color: c.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: context.tr('next_diff_tooltip'),
                    child: InkWell(
                      onTap: onNextDiff,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.arrow_downward_rounded,
                          size: 15,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Spacer(),

          // View Mode Switcher
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: c.bgPrimary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.borderDefault),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ViewModeButton(
                  icon: Icons.view_column_rounded,
                  label: context.tr('view_split'),
                  isSelected: viewMode == _ViewMode.split,
                  onTap: () => onViewModeChanged(_ViewMode.split),
                ),
                _ViewModeButton(
                  icon: Icons.view_stream_rounded,
                  label: context.tr('view_unified'),
                  isSelected: viewMode == _ViewMode.unified,
                  onTap: () => onViewModeChanged(_ViewMode.unified),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewModeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? c.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : c.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiffPane extends StatelessWidget {
  final ScrollController controller;
  final List<DiffLine> lines;
  final _PaneSide side;
  final String label;
  final String? path;
  final int highlightIndex;

  const _DiffPane({
    required this.controller,
    required this.lines,
    required this.side,
    required this.label,
    this.path,
    required this.highlightIndex,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final hasValidPath = path != null && path!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: c.bgSecondary,
            border: Border(bottom: BorderSide(color: c.borderDefault)),
          ),
          child: Row(
            children: [
              Icon(
                side == _PaneSide.left
                    ? Icons.history_rounded
                    : Icons.update_rounded,
                size: 14,
                color: c.accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (hasValidPath) ...[
                      const SizedBox(height: 2),
                      Tooltip(
                        message: '${context.tr('reveal_in_explorer')}\n$path',
                        child: InkWell(
                          onTap: () => revealInExplorer(path),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.folder_open_outlined,
                                  size: 11,
                                  color: c.accent.withValues(alpha: 0.8),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    path!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: c.accent.withValues(alpha: 0.9),
                                      fontSize: 10.5,
                                      fontFamily: 'Consolas',
                                      decoration: TextDecoration.underline,
                                      decorationStyle:
                                          TextDecorationStyle.dotted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (hasValidPath) ...[
                IconButton(
                  tooltip: context.tr('reveal_in_explorer'),
                  icon: Icon(
                    Icons.folder_open_rounded,
                    size: 14,
                    color: c.textSecondary,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  onPressed: () => revealInExplorer(path),
                ),
                IconButton(
                  tooltip: context.tr('copy_path'),
                  icon: Icon(
                    Icons.link_rounded,
                    size: 14,
                    color: c.textSecondary,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  onPressed: () => _copyPath(context, path!),
                ),
              ],
              IconButton(
                tooltip: context.tr('copy_all_tooltip'),
                icon: Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: c.textSecondary,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: lines.isEmpty ? null : () => _copyAll(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: lines.isEmpty
              ? Center(
                  child: Text(
                    context.tr('no_content'),
                    style: TextStyle(color: c.textSecondary, fontSize: 12),
                  ),
                )
              : SelectionArea(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: lines.length,
                    itemExtent: 24,
                    itemBuilder: (context, index) => _DiffRow(
                      line: lines[index],
                      side: side,
                      isCurrentNavTarget: index == highlightIndex,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  void _copyPath(BuildContext context, String path) {
    Clipboard.setData(ClipboardData(text: path));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('path_copied')),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _copyAll(BuildContext context) {
    final text = lines
        .map((l) => side == _PaneSide.left ? l.leftText : l.rightText)
        .where((t) => t != null)
        .join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('copied_toast')),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

class _DiffRow extends StatelessWidget {
  final DiffLine line;
  final _PaneSide side;
  final bool isCurrentNavTarget;

  const _DiffRow({
    required this.line,
    required this.side,
    this.isCurrentNavTarget = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final isLeft = side == _PaneSide.left;
    final text = isLeft ? line.leftText : line.rightText;
    final lineNo = isLeft ? line.leftLineNo : line.rightLineNo;
    final segments = isLeft ? line.leftSegments : line.rightSegments;

    Color? bg = switch (line.type) {
      DiffType.insert => isLeft ? null : c.diffAdded,
      DiffType.delete => isLeft ? c.diffRemoved : null,
      DiffType.modify => c.diffModified,
      DiffType.equal => null,
    };

    if (isCurrentNavTarget) {
      bg = c.accent.withValues(alpha: 0.35);
    }

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              lineNo?.toString() ?? '',
              style: TextStyle(
                color: c.textSecondary.withValues(alpha: 0.65),
                fontSize: 11,
                fontFamily: 'Consolas',
              ),
            ),
          ),
          Expanded(
            child:
                (line.type == DiffType.modify &&
                    segments != null &&
                    segments.isNotEmpty)
                ? _buildIntraLineHighlight(segments, c, isLeft)
                : Text(
                    text ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 12,
                      fontFamily: 'Consolas',
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntraLineHighlight(
    List<DiffSegment> segments,
    AppColors c,
    bool isLeft,
  ) {
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: segments.map((seg) {
          final isChanged = isLeft
              ? seg.type == DiffSegmentType.delete
              : seg.type == DiffSegmentType.insert;
          final highlightBg = isChanged
              ? (isLeft ? c.diffWordRemoved : c.diffWordAdded)
              : null;

          return TextSpan(
            text: seg.text,
            style: TextStyle(
              backgroundColor: highlightBg,
              color: isChanged ? Colors.white : c.textPrimary,
              fontWeight: isChanged ? FontWeight.w700 : FontWeight.w400,
              fontSize: 12,
              fontFamily: 'Consolas',
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _UnifiedDiffView extends StatelessWidget {
  final ScrollController controller;
  final List<DiffLine> lines;
  final String leftLabel;
  final String rightLabel;
  final String? leftPath;
  final String? rightPath;
  final int highlightIndex;

  const _UnifiedDiffView({
    required this.controller,
    required this.lines,
    required this.leftLabel,
    required this.rightLabel,
    this.leftPath,
    this.rightPath,
    required this.highlightIndex,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (leftPath != null || rightPath != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: c.bgSecondary,
              border: Border(bottom: BorderSide(color: c.borderDefault)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildPathChip(
                    context,
                    c,
                    leftLabel,
                    leftPath,
                    Icons.history_rounded,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.compare_arrows_rounded,
                    size: 14,
                    color: c.textSecondary,
                  ),
                ),
                Expanded(
                  child: _buildPathChip(
                    context,
                    c,
                    rightLabel,
                    rightPath,
                    Icons.update_rounded,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: SelectionArea(
            child: ListView.builder(
              controller: controller,
              itemCount: lines.length,
              itemBuilder: (context, index) => _UnifiedDiffRow(
                line: lines[index],
                colors: c,
                isCurrentNavTarget: index == highlightIndex,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPathChip(
    BuildContext context,
    AppColors c,
    String label,
    String? path,
    IconData icon,
  ) {
    final hasValidPath = path != null && path.trim().isNotEmpty;
    return Tooltip(
      message: hasValidPath
          ? '${context.tr('reveal_in_explorer')}\n$path'
          : label,
      child: InkWell(
        onTap: hasValidPath ? () => revealInExplorer(path) : null,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: c.accent),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  hasValidPath ? '$label ($path)' : label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: hasValidPath ? c.accent : c.textPrimary,
                    decoration: hasValidPath ? TextDecoration.underline : null,
                    decorationStyle: TextDecorationStyle.dotted,
                    fontFamily: 'Consolas',
                  ),
                ),
              ),
              if (hasValidPath) ...[
                const SizedBox(width: 4),
                Icon(Icons.open_in_new_rounded, size: 11, color: c.accent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UnifiedDiffRow extends StatelessWidget {
  final DiffLine line;
  final AppColors colors;
  final bool isCurrentNavTarget;

  const _UnifiedDiffRow({
    required this.line,
    required this.colors,
    required this.isCurrentNavTarget,
  });

  @override
  Widget build(BuildContext context) {
    if (line.type == DiffType.modify) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSideRow(
            text: line.leftText,
            lineNo: line.leftLineNo,
            prefix: '-',
            background: colors.diffRemoved,
            segments: line.leftSegments,
            isLeft: true,
          ),
          _buildSideRow(
            text: line.rightText,
            lineNo: line.rightLineNo,
            prefix: '+',
            background: colors.diffAdded,
            segments: line.rightSegments,
            isLeft: false,
          ),
        ],
      );
    }

    final isLeft = line.type == DiffType.delete;
    return _buildSideRow(
      text: isLeft ? line.leftText : line.rightText ?? line.leftText,
      lineNo: isLeft ? line.leftLineNo : line.rightLineNo,
      prefix: switch (line.type) {
        DiffType.insert => '+',
        DiffType.delete => '-',
        DiffType.equal => ' ',
        DiffType.modify => '~',
      },
      background: switch (line.type) {
        DiffType.insert => colors.diffAdded,
        DiffType.delete => colors.diffRemoved,
        DiffType.equal => null,
        DiffType.modify => colors.diffModified,
      },
      isLeft: isLeft,
    );
  }

  Widget _buildSideRow({
    required String? text,
    required int? lineNo,
    required String prefix,
    required Color? background,
    List<DiffSegment>? segments,
    required bool isLeft,
  }) {
    final rowBackground = isCurrentNavTarget
        ? colors.accent.withValues(alpha: 0.35)
        : background;
    final textWidget = segments != null && segments.isNotEmpty
        ? _buildSegments(segments, isLeft)
        : Text(
            text ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _textStyle(),
          );

    return Container(
      color: rowBackground,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      height: 24,
      child: Row(
        children: [
          _lineNumber(isLeft ? lineNo : null),
          _lineNumber(isLeft ? null : lineNo),
          SizedBox(
            width: 18,
            child: Text(
              prefix,
              style: TextStyle(
                color: prefix == '+'
                    ? Colors.green
                    : prefix == '-'
                    ? Colors.red
                    : colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'Consolas',
              ),
            ),
          ),
          Expanded(child: textWidget),
        ],
      ),
    );
  }

  Widget _lineNumber(int? lineNo) {
    return SizedBox(
      width: 36,
      child: Text(
        lineNo?.toString() ?? '',
        style: TextStyle(
          color: colors.textSecondary.withValues(alpha: 0.6),
          fontSize: 11,
          fontFamily: 'Consolas',
        ),
      ),
    );
  }

  RichText _buildSegments(List<DiffSegment> segments, bool isLeft) {
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: segments.map((segment) {
          final changed = isLeft
              ? segment.type == DiffSegmentType.delete
              : segment.type == DiffSegmentType.insert;
          return TextSpan(
            text: segment.text,
            style: _textStyle(
              backgroundColor: changed
                  ? (isLeft ? colors.diffWordRemoved : colors.diffWordAdded)
                  : null,
              color: changed ? Colors.white : colors.textPrimary,
              fontWeight: changed ? FontWeight.w700 : FontWeight.w400,
            ),
          );
        }).toList(),
      ),
    );
  }

  TextStyle _textStyle({
    Color? color,
    Color? backgroundColor,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return TextStyle(
      color: color ?? colors.textPrimary,
      backgroundColor: backgroundColor,
      fontSize: 12,
      fontWeight: fontWeight,
      fontFamily: 'Consolas',
    );
  }
}
