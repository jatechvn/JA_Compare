import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

import '../build_info.dart';
import '../constants.dart';
import '../file_service.dart';
import '../logic.dart';
import '../services/export_service.dart';
import '../utils.dart';
import 'dialogs.dart';
import 'diff_view.dart';
import 'history_dialog.dart';
import 'language_scope.dart';
import 'styles.dart';

class MainWindow extends StatefulWidget {
  const MainWindow({super.key});

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> {
  final _controller = CompareController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: c.bgPrimary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(controller: _controller),
            Expanded(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  if (_controller.hasResult) {
                    return _ResultScreen(controller: _controller);
                  }
                  return _PickerScreen(controller: _controller);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final CompareController controller;
  const _Header({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: c.bgSecondary,
        border: Border(bottom: BorderSide(color: c.borderDefault)),
      ),
      child: Row(
        children: [
          Icon(Icons.difference_outlined, color: c.accent, size: 20),
          const SizedBox(width: 10),
          Text(
            appName,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (BuildInfo.isDebug) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
              ),
              child: Text(
                'DEBUG • v${BuildInfo.version} (${BuildInfo.debugTimestamp})',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ),
          ],
          const Spacer(),
          _LanguageButton(color: c.textSecondary),
          const SizedBox(width: 4),
          IconButton(
            tooltip: context.tr('theme_toggle_tooltip'),
            icon: Icon(
              context.themeProvider.isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              color: c.textSecondary,
              size: 18,
            ),
            onPressed: () => context.themeProvider.toggleTheme(),
          ),
          IconButton(
            tooltip: context.tr('history_tooltip'),
            icon: Icon(Icons.history, color: c.textSecondary, size: 18),
            onPressed: () => showDialog<void>(
              context: context,
              barrierColor: Colors.black26,
              builder: (_) => HistoryDialog(controller: controller),
            ),
          ),
          IconButton(
            tooltip: context.tr('settings_tooltip'),
            icon: Icon(
              Icons.settings_outlined,
              color: c.textSecondary,
              size: 18,
            ),
            onPressed: () => showDialog<void>(
              context: context,
              barrierColor: Colors.black26,
              builder: (_) => const SettingsDialog(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final Color color;
  const _LanguageButton({required this.color});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => context.languageProvider.cycle(),
      style: TextButton.styleFrom(foregroundColor: color),
      icon: const Icon(Icons.language, size: 16),
      label: Text(
        context.languageProvider.badge,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PickerScreen extends StatelessWidget {
  final CompareController controller;
  const _PickerScreen({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (controller.errorMessage != null) ...[
            _ErrorBanner(message: controller.errorMessage!),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _DocumentPickerPane(
                    title: context.tr('pane_left_title'),
                    document: controller.leftDocument,
                    onPick: () => controller.pickFile(ComparePaneSide.left),
                    onDropPath: (path) =>
                        controller.loadFile(ComparePaneSide.left, path),
                  ),
                ),
                const SizedBox(width: 16),
                _CompareButton(controller: controller),
                const SizedBox(width: 16),
                Expanded(
                  child: _DocumentPickerPane(
                    title: context.tr('pane_right_title'),
                    document: controller.rightDocument,
                    onPick: () => controller.pickFile(ComparePaneSide.right),
                    onDropPath: (path) =>
                        controller.loadFile(ComparePaneSide.right, path),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompareButton extends StatelessWidget {
  final CompareController controller;
  const _CompareButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Center(
        child: FilledButton.icon(
          onPressed: controller.canCompare ? controller.compare : null,
          icon: controller.isLoading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.compare_arrows, size: 18),
          label: Text(
            context.tr('compare_button'),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
          ),
        ),
      ),
    );
  }
}

class _DocumentPickerPane extends StatefulWidget {
  final String title;
  final LoadedDocument? document;
  final VoidCallback onPick;
  final ValueChanged<String> onDropPath;

  const _DocumentPickerPane({
    required this.title,
    required this.document,
    required this.onPick,
    required this.onDropPath,
  });

  @override
  State<_DocumentPickerPane> createState() => _DocumentPickerPaneState();
}

class _DocumentPickerPaneState extends State<_DocumentPickerPane> {
  bool _dragHover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final doc = widget.document;

    return DropTarget(
      onDragEntered: (_) => setState(() => _dragHover = true),
      onDragExited: (_) => setState(() => _dragHover = false),
      onDragDone: (details) {
        setState(() => _dragHover = false);
        if (details.files.isNotEmpty) {
          widget.onDropPath(details.files.first.path);
        }
      },
      child: InkWell(
        onTap: widget.onPick,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _dragHover ? c.accent : c.borderDefault,
              width: _dragHover ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Icon(
                doc == null
                    ? Icons.upload_file_outlined
                    : Icons.description_outlined,
                color: doc == null ? c.textSecondary : c.accent,
                size: 40,
              ),
              const SizedBox(height: 12),
              if (doc == null) ...[
                Text(
                  context.tr('pick_or_drop'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  supportedExtensions.map((e) => '.$e').join(' '),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.textSecondary, fontSize: 10),
                ),
              ] else ...[
                Text(
                  doc.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '.${doc.extension} · ${formatFileSize(doc.sizeBytes)} · '
                  '${doc.lines.length} ${context.tr('lines_suffix')}',
                  style: TextStyle(color: c.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: widget.onPick,
                  child: Text(context.tr('change_file')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultScreen extends StatelessWidget {
  final CompareController controller;
  const _ResultScreen({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.borderDefault)),
          ),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: controller.reset,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: Text(context.tr('compare_other_file')),
              ),
              const Spacer(),
              _ExportButton(controller: controller),
            ],
          ),
        ),
        Expanded(
          child: DiffView(
            result: controller.diffResult!,
            leftLabel: controller.leftDocument?.name ?? '',
            rightLabel: controller.rightDocument?.name ?? '',
          ),
        ),
      ],
    );
  }
}

class _ExportButton extends StatelessWidget {
  final CompareController controller;
  const _ExportButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return PopupMenuButton<_ExportFormat>(
      tooltip: context.tr('export_tooltip'),
      icon: Icon(Icons.ios_share, size: 16, color: c.textSecondary),
      onSelected: (format) => _export(context, format),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _ExportFormat.markdown,
          child: Text(context.tr('export_markdown_option')),
        ),
        PopupMenuItem(
          value: _ExportFormat.excel,
          child: Text(context.tr('export_excel_option')),
        ),
      ],
    );
  }

  Future<void> _export(BuildContext context, _ExportFormat format) async {
    final result = controller.diffResult;
    final left = controller.leftDocument;
    final right = controller.rightDocument;
    if (result == null || left == null || right == null) return;

    final language = context.languageProvider.language;
    final exportService = ExportService();
    // null = user cancelled the save dialog (stay silent), true/false = a
    // real outcome worth telling the user about.
    bool? saved;
    try {
      final didSave = format == _ExportFormat.markdown
          ? await exportService.exportMarkdown(
              result: result,
              leftName: left.name,
              rightName: right.name,
              language: language,
            )
          : await exportService.exportExcel(
              result: result,
              leftName: left.name,
              rightName: right.name,
              language: language,
            );
      saved = didSave ? true : null;
    } catch (_) {
      saved = false;
    }

    if (!context.mounted || saved == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved ? context.tr('export_success') : context.tr('export_failed'),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

enum _ExportFormat { markdown, excel }

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
