import 'package:flutter/material.dart';

import '../logic.dart';
import '../models/history_entry.dart';
import '../services/history_service.dart';
import 'dialogs.dart';
import 'language_scope.dart';
import 'styles.dart';

/// Lists past comparisons (most recent first). Tapping an entry re-loads
/// both files and re-runs the diff; the trash icon removes just that entry.
class HistoryDialog extends StatefulWidget {
  final CompareController controller;
  const HistoryDialog({super.key, required this.controller});

  @override
  State<HistoryDialog> createState() => _HistoryDialogState();
}

class _HistoryDialogState extends State<HistoryDialog> {
  late List<HistoryEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = HistoryService.load();
  }

  void _reload() => setState(() => _entries = HistoryService.load());

  Future<void> _open(HistoryEntry entry) async {
    final language = context.languageProvider.language;
    Navigator.of(context).pop();
    await widget.controller.reopenFromHistory(entry, language: language);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GlassDialog(
      title: context.tr('history_title'),
      width: 560,
      height: 520,
      child: _entries.isEmpty
          ? Center(
              child: Text(
                context.tr('history_empty'),
                style: TextStyle(color: c.textSecondary, fontSize: 13),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = _entries[index];
                      return _HistoryTile(
                        entry: entry,
                        onOpen: () => _open(entry),
                        onDelete: () {
                          HistoryService.remove(entry);
                          _reload();
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HistoryService.clear();
                      _reload();
                    },
                    icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                    label: Text(context.tr('history_clear')),
                  ),
                ),
              ],
            ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final HistoryEntry entry;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _HistoryTile({
    required this.entry,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.borderDefault),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.leftName}  ↔  ${entry.rightName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(entry.comparedAt),
                      style: TextStyle(color: c.textSecondary, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '+${entry.added}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '-${entry.removed}',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '~${entry.modified}',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: context.tr('history_delete_tooltip'),
                icon: Icon(Icons.close, size: 16, color: c.textSecondary),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${pad(dt.month)}-${pad(dt.day)} ${pad(dt.hour)}:${pad(dt.minute)}';
  }
}
