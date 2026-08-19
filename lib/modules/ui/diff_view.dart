import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import '../models/diff_result.dart';
import 'language_scope.dart';
import 'styles.dart';

enum _PaneSide { left, right }

/// Side-by-side diff renderer: two [ListView]s sharing one row list
/// (`result.lines` — every row already carries both sides' content, so
/// index N in the left pane always lines up with index N on the right)
/// with manually synchronized scroll offsets.
class DiffView extends StatefulWidget {
  final DiffResult result;
  final String leftLabel;
  final String rightLabel;

  const DiffView({
    super.key,
    required this.result,
    required this.leftLabel,
    required this.rightLabel,
  });

  @override
  State<DiffView> createState() => _DiffViewState();
}

class _DiffViewState extends State<DiffView> {
  final _leftController = ScrollController();
  final _rightController = ScrollController();
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _leftController.addListener(() => _sync(_leftController, _rightController));
    _rightController.addListener(
      () => _sync(_rightController, _leftController),
    );
  }

  void _sync(ScrollController source, ScrollController target) {
    if (_syncing || !target.hasClients || !source.hasClients) return;
    final clamped = source.offset.clamp(0.0, target.position.maxScrollExtent);
    if (clamped == target.offset) return;
    _syncing = true;
    target.jumpTo(clamped);
    _syncing = false;
  }

  @override
  void dispose() {
    _leftController.dispose();
    _rightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DiffStatsBar(stats: widget.result.stats),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _DiffPane(
                  controller: _leftController,
                  lines: widget.result.lines,
                  side: _PaneSide.left,
                  label: widget.leftLabel,
                ),
              ),
              VerticalDivider(width: 1, color: c.borderDefault),
              Expanded(
                child: _DiffPane(
                  controller: _rightController,
                  lines: widget.result.lines,
                  side: _PaneSide.right,
                  label: widget.rightLabel,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DiffPane extends StatelessWidget {
  final ScrollController controller;
  final List<DiffLine> lines;
  final _PaneSide side;
  final String label;

  const _DiffPane({
    required this.controller,
    required this.lines,
    required this.side,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.borderDefault)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: context.tr('copy_all_tooltip'),
                icon: Icon(
                  Icons.copy_outlined,
                  size: 15,
                  color: c.textSecondary,
                ),
                visualDensity: VisualDensity.compact,
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
                    itemExtent: 22,
                    itemBuilder: (context, index) =>
                        _DiffRow(line: lines[index], side: side),
                  ),
                ),
        ),
      ],
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

  const _DiffRow({required this.line, required this.side});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final isLeft = side == _PaneSide.left;
    final text = isLeft ? line.leftText : line.rightText;
    final lineNo = isLeft ? line.leftLineNo : line.rightLineNo;

    final Color? bg = switch (line.type) {
      DiffType.insert => isLeft ? null : c.diffAdded,
      DiffType.delete => isLeft ? c.diffRemoved : null,
      DiffType.modify => c.diffModified,
      DiffType.equal => null,
    };

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
                color: c.textSecondary,
                fontSize: 11,
                fontFamily: 'Consolas',
              ),
            ),
          ),
          Expanded(
            child: Text(
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
}

class _DiffStatsBar extends StatelessWidget {
  final DiffStats stats;
  const _DiffStatsBar({required this.stats});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: c.sidebarBg,
        border: Border(bottom: BorderSide(color: c.borderDefault)),
      ),
      child: Row(
        children: [
          _StatChip(
            label: '+${stats.added} ${context.tr('added_suffix')}',
            color: c.diffAdded,
            textColor: c.textPrimary,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: '-${stats.removed} ${context.tr('removed_suffix')}',
            color: c.diffRemoved,
            textColor: c.textPrimary,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: '${stats.modified} ${context.tr('modified_suffix')}',
            color: c.diffModified,
            textColor: c.textPrimary,
          ),
          const Spacer(),
          Text(
            stats.hasDifferences
                ? '${stats.totalChanges} ${context.tr('differences_suffix')}'
                : context.tr('identical_label'),
            style: TextStyle(color: c.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _StatChip({
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
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
