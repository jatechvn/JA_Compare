import 'dart:ui' as ui;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../build_info.dart';
import '../file_service.dart';
import '../i18n/language_provider.dart';
import '../logic.dart';
import '../sample_presets.dart';
import '../services/export_service.dart';
import '../services/settings_service.dart';
import '../utils.dart';
import 'dialogs.dart';
import 'diff_view.dart';
import 'directory_compare_view.dart';
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
  late double _backgroundBlur;
  late double _backgroundOpacity;

  @override
  void initState() {
    super.initState();
    _loadVisualSettings();
  }

  void _loadVisualSettings() {
    final settings = SettingsService.loadSettings();
    _backgroundBlur = settings['bg_blur']!;
    _backgroundOpacity = settings['bg_opacity']!;
  }

  void _refreshVisualSettings() {
    if (!mounted) return;
    setState(_loadVisualSettings);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final isDark = context.themeProvider.isDark;
    final opacity = _backgroundOpacity.clamp(0.1, 1.0);
    final blur = opacity < 0.999 && _backgroundBlur < 6 ? 6.0 : _backgroundBlur;
    final gradientAccent =
        (isDark
                ? Color.lerp(c.bgPrimary, c.accent, 0.10)!
                : Color.lerp(c.bgPrimary, c.accent, 0.04)!)
            .withValues(alpha: opacity);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): () {
          if (_controller.canCompare) _controller.compare();
        },
        const SingleActivator(LogicalKeyboardKey.keyO, control: true): () {
          _controller.pickFile(ComparePaneSide.left);
        },
        const SingleActivator(
          LogicalKeyboardKey.keyO,
          control: true,
          shift: true,
        ): () {
          _controller.pickFile(ComparePaneSide.right);
        },
        const SingleActivator(
          LogicalKeyboardKey.keyS,
          control: true,
          shift: true,
        ): () {
          _controller.swap();
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_controller.hasResult) _controller.reset();
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: DropTarget(
            onDragDone: (details) {
              if (details.files.length >= 2) {
                _controller.loadDroppedPair(
                  details.files.map((file) => file.path),
                );
              }
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                    child: const SizedBox.expand(),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.bgPrimary.withValues(alpha: opacity),
                      gradient: RadialGradient(
                        center: const Alignment(0.7, -0.6),
                        radius: 1.2,
                        colors: [
                          gradientAccent,
                          c.bgPrimary.withValues(alpha: opacity),
                        ],
                      ),
                    ),
                    child: ListenableBuilder(
                      listenable: _controller,
                      builder: (context, _) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Header(
                              controller: _controller,
                              onSettingsSaved: _refreshVisualSettings,
                            ),
                            Expanded(
                              child: _controller.hasResult
                                  ? _ResultScreen(controller: _controller)
                                  : _PickerScreen(controller: _controller),
                            ),
                            _FooterStatusBar(controller: _controller),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final CompareController controller;
  final VoidCallback? onSettingsSaved;

  const _Header({required this.controller, this.onSettingsSaved});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: c.bgSecondary,
        border: Border(bottom: BorderSide(color: c.borderDefault)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(Icons.difference_rounded, color: c.accent, size: 17),
          ),
          const SizedBox(width: 8),
          Text(
            'JA Compare',
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: Center(
              child: controller.hasResult
                  ? FilledButton.tonalIcon(
                      onPressed: controller.reset,
                      icon: const Icon(Icons.arrow_back_rounded, size: 14),
                      label: Text(
                        controller.mode == CompareMode.folders
                            ? context.tr('compare_other_folder')
                            : context.tr('compare_other_file'),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                  : _ModeSegmentedControl(controller: controller),
            ),
          ),
          if (controller.hasResult &&
              controller.mode != CompareMode.folders) ...[
            _ExportButton(controller: controller),
            const SizedBox(width: 4),
          ],
          if (BuildInfo.isDebug) ...[
            const _DebugStamp(),
            const SizedBox(width: 4),
          ],
          _LanguageButton(color: c.textSecondary),
          IconButton(
            tooltip: context.tr('theme_toggle_tooltip'),
            icon: Icon(
              context.themeProvider.isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              color: c.textSecondary,
              size: 17,
            ),
            visualDensity: VisualDensity.compact,
            onPressed: () => context.themeProvider.toggleTheme(),
          ),
          IconButton(
            tooltip: context.tr('history_tooltip'),
            icon: Icon(Icons.history_rounded, color: c.textSecondary, size: 17),
            visualDensity: VisualDensity.compact,
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
              size: 17,
            ),
            visualDensity: VisualDensity.compact,
            onPressed: () async {
              final saved = await showDialog<bool>(
                context: context,
                barrierColor: Colors.black26,
                builder: (_) => const SettingsDialog(),
              );
              if (saved == true && context.mounted) onSettingsSaved?.call();
            },
          ),
        ],
      ),
    );
  }
}

class _ModeSegmentedControl extends StatelessWidget {
  final CompareController controller;
  const _ModeSegmentedControl({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final isDark = context.themeProvider.isDark;
    final mode = controller.mode;

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.3)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.borderDefault),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ModeTabItem(
              icon: Icons.insert_drive_file_rounded,
              label: context.tr('tab_files'),
              isSelected: mode == CompareMode.files,
              onTap: () => controller.setMode(CompareMode.files),
            ),
            const SizedBox(width: 2),
            _ModeTabItem(
              icon: Icons.folder_copy_rounded,
              label: context.tr('tab_folders'),
              isSelected: mode == CompareMode.folders,
              onTap: () => controller.setMode(CompareMode.folders),
            ),
            const SizedBox(width: 2),
            _ModeTabItem(
              icon: Icons.edit_note_rounded,
              label: context.tr('tab_direct_text'),
              isSelected: mode == CompareMode.directText,
              onTap: () => controller.setMode(CompareMode.directText),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeTabItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isSelected ? c.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: c.accent.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ]
                : null,
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
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : c.textSecondary,
                ),
              ),
            ],
          ),
        ),
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
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      icon: const Icon(Icons.language, size: 16),
      label: Text(
        context.languageProvider.badge,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _DebugStamp extends StatelessWidget {
  const _DebugStamp();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Debug build timestamp: ${BuildInfo.debugTimestamp}',
      child: Container(
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
    );
  }
}

class _PickerScreen extends StatelessWidget {
  final CompareController controller;
  const _PickerScreen({required this.controller});

  @override
  Widget build(BuildContext context) {
    final mode = controller.mode;

    Widget buildLeftPane() {
      switch (mode) {
        case CompareMode.files:
          return _DocumentPickerPane(
            side: ComparePaneSide.left,
            title: context.tr('pane_left_title'),
            document: controller.leftDocument,
            controller: controller,
          );
        case CompareMode.folders:
          return _FolderPickerPane(
            side: ComparePaneSide.left,
            title: context.tr('pane_left_folder_title'),
            folderPath: controller.leftDirectoryPath,
            controller: controller,
          );
        case CompareMode.directText:
          return _DirectTextInputPane(
            side: ComparePaneSide.left,
            title: context.tr('pane_left_title'),
            hintText: context.tr('direct_text_hint_left'),
            textController: controller.leftTextController,
            controller: controller,
          );
      }
    }

    Widget buildRightPane() {
      switch (mode) {
        case CompareMode.files:
          return _DocumentPickerPane(
            side: ComparePaneSide.right,
            title: context.tr('pane_right_title'),
            document: controller.rightDocument,
            controller: controller,
          );
        case CompareMode.folders:
          return _FolderPickerPane(
            side: ComparePaneSide.right,
            title: context.tr('pane_right_folder_title'),
            folderPath: controller.rightDirectoryPath,
            controller: controller,
          );
        case CompareMode.directText:
          return _DirectTextInputPane(
            side: ComparePaneSide.right,
            title: context.tr('pane_right_title'),
            hintText: context.tr('direct_text_hint_right'),
            textController: controller.rightTextController,
            controller: controller,
          );
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (controller.errorMessage != null) ...[
            _ErrorBanner(message: controller.errorMessage!),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: buildLeftPane()),
                const SizedBox(width: 16),
                _CentralActionHub(controller: controller),
                const SizedBox(width: 16),
                Expanded(child: buildRightPane()),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _BottomOptionsBar(controller: controller),
        ],
      ),
    );
  }
}

class _CentralActionHub extends StatelessWidget {
  final CompareController controller;
  const _CentralActionHub({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final canCompare = controller.canCompare;

    return SizedBox(
      width: 140,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Tooltip(
            message: context.tr('swap_tooltip'),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: controller.hasAnyContent ? controller.swap : null,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: c.cardBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.borderDefault),
                  ),
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    color: controller.hasAnyContent
                        ? c.accent
                        : c.textSecondary.withValues(alpha: 0.4),
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: canCompare
                  ? [
                      BoxShadow(
                        color: c.accent.withValues(alpha: 0.45),
                        blurRadius: 16,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: ElevatedButton(
              onPressed: canCompare ? controller.compare : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canCompare ? c.accent : c.cardBg,
                foregroundColor: canCompare ? Colors.white : c.textSecondary,
                disabledBackgroundColor: c.cardBg.withValues(alpha: 0.5),
                disabledForegroundColor: c.textSecondary.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: canCompare
                        ? c.accent
                        : c.borderDefault.withValues(alpha: 0.5),
                  ),
                ),
                elevation: 0,
              ),
              child: controller.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.compare_arrows_rounded,
                          size: 19,
                          color: canCompare ? Colors.white : c.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            context.tr('compare_button'),
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          if (controller.hasAnyContent)
            Tooltip(
              message: context.tr('clear_all_tooltip'),
              child: TextButton.icon(
                onPressed: controller.clearBoth,
                style: TextButton.styleFrom(
                  foregroundColor: c.textSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.close_rounded, size: 14),
                label: Text(
                  context.tr('clear_side_tooltip'),
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FolderPickerPane extends StatefulWidget {
  final ComparePaneSide side;
  final String title;
  final String? folderPath;
  final CompareController controller;

  const _FolderPickerPane({
    required this.side,
    required this.title,
    required this.folderPath,
    required this.controller,
  });

  @override
  State<_FolderPickerPane> createState() => _FolderPickerPaneState();
}

class _FolderPickerPaneState extends State<_FolderPickerPane> {
  bool _dragHover = false;
  bool _mouseHover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final isDark = context.themeProvider.isDark;
    final folder = widget.folderPath;

    return DropTarget(
      onDragEntered: (_) => setState(() => _dragHover = true),
      onDragExited: (_) => setState(() => _dragHover = false),
      onDragDone: (detail) {
        setState(() => _dragHover = false);
        if (detail.files.length == 1) {
          final path = detail.files.first.path;
          widget.controller.loadDirectory(widget.side, path);
        }
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _mouseHover = true),
        onExit: (_) => setState(() => _mouseHover = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _mouseHover ? c.cardHoverBg : c.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _dragHover
                  ? c.accent
                  : _mouseHover
                  ? c.accent.withValues(alpha: 0.5)
                  : c.borderDefault,
              width: _dragHover ? 2 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.4),
                    border: Border(bottom: BorderSide(color: c.borderDefault)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.folder_rounded, size: 16, color: c.accent),
                      const SizedBox(width: 8),
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (folder != null)
                        Tooltip(
                          message: context.tr('clear_side_tooltip'),
                          child: InkWell(
                            onTap: () =>
                                widget.controller.clearSide(widget.side),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Body
                Expanded(
                  child: folder != null
                      ? _buildLoadedState(context, c, folder, isDark)
                      : _buildEmptyState(context, c),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppColors c) {
    return InkWell(
      onTap: () => widget.controller.pickDirectory(widget.side),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _dragHover
                      ? c.accent.withValues(alpha: 0.2)
                      : c.accent.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _dragHover
                        ? c.accent
                        : c.accent.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  _dragHover
                      ? Icons.folder_copy_rounded
                      : Icons.create_new_folder_rounded,
                  color: c.accent,
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _dragHover
                    ? context.tr('drop_here_prompt')
                    : context.tr('pick_or_drop_folder'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _dragHover ? c.accent : c.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: c.accent.withValues(alpha: 0.2)),
                ),
                child: Text(
                  'Auto-matches similar file names',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: c.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadedState(
    BuildContext context,
    AppColors c,
    String folderPath,
    bool isDark,
  ) {
    final folderName = folderPath.split(RegExp(r'[/\\]')).last;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: c.accent.withValues(alpha: 0.3)),
            ),
            child: Icon(
              Icons.folder_special_rounded,
              size: 40,
              color: c.accent,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            folderName.isEmpty ? folderPath : folderName,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            folderPath,
            style: TextStyle(
              fontSize: 11,
              color: c.textSecondary,
              fontFamily: 'Consolas',
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => widget.controller.pickDirectory(widget.side),
            icon: const Icon(Icons.folder_open_rounded, size: 14),
            label: Text(context.tr('change_file')),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              side: BorderSide(color: c.borderDefault),
              foregroundColor: c.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentPickerPane extends StatefulWidget {
  final ComparePaneSide side;
  final String title;
  final LoadedDocument? document;
  final CompareController controller;

  const _DocumentPickerPane({
    required this.side,
    required this.title,
    required this.document,
    required this.controller,
  });

  @override
  State<_DocumentPickerPane> createState() => _DocumentPickerPaneState();
}

class _DocumentPickerPaneState extends State<_DocumentPickerPane> {
  bool _dragHover = false;
  bool _mouseHover = false;

  Color _getBadgeColor(String ext) {
    return switch (ext.toLowerCase()) {
      'json' => const Color(0xFFEAB308),
      'dart' => const Color(0xFF0284C7),
      'docx' => const Color(0xFF2563EB),
      'xlsx' => const Color(0xFF16A34A),
      'pdf' => const Color(0xFFDC2626),
      'xml' || 'html' || 'htm' => const Color(0xFFF97316),
      'yaml' || 'yml' => const Color(0xFF8B5CF6),
      'csv' => const Color(0xFF0D9488),
      _ => const Color(0xFF64748B),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final doc = widget.document;
    final isDark = context.themeProvider.isDark;

    return DropTarget(
      onDragEntered: (_) => setState(() => _dragHover = true),
      onDragExited: (_) => setState(() => _dragHover = false),
      onDragDone: (details) {
        setState(() => _dragHover = false);
        if (details.files.length == 1) {
          widget.controller.loadFile(widget.side, details.files.first.path);
        }
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _mouseHover = true),
        onExit: (_) => setState(() => _mouseHover = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            color: _mouseHover ? c.cardHoverBg : c.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _dragHover
                  ? c.accent
                  : _mouseHover
                  ? c.accent.withValues(alpha: 0.5)
                  : c.borderDefault,
              width: _dragHover ? 2 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: _dragHover
                    ? c.accent.withValues(alpha: 0.25)
                    : isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: _dragHover ? 20 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.4),
                    border: Border(bottom: BorderSide(color: c.borderDefault)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.side == ComparePaneSide.left
                            ? Icons.article_rounded
                            : Icons.difference_rounded,
                        size: 15,
                        color: c.accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Tooltip(
                        message: context.tr('paste_tooltip'),
                        child: InkWell(
                          onTap: () =>
                              widget.controller.pasteFromClipboard(widget.side),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.paste_rounded,
                                  size: 13,
                                  color: c.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  context.tr('paste_clipboard'),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: c.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (doc != null) ...[
                        const SizedBox(width: 4),
                        Tooltip(
                          message: context.tr('clear_side_tooltip'),
                          child: InkWell(
                            onTap: () =>
                                widget.controller.clearSide(widget.side),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: doc == null
                      ? _buildEmptyState(context, c)
                      : _buildLoadedState(context, c, doc),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppColors c) {
    final isDark = context.themeProvider.isDark;
    return InkWell(
      onTap: () => widget.controller.pickFile(widget.side),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _dragHover
                      ? c.accent.withValues(alpha: 0.2)
                      : c.accent.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _dragHover
                        ? c.accent
                        : c.accent.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  _dragHover
                      ? Icons.file_download_rounded
                      : Icons.upload_file_rounded,
                  color: c.accent,
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _dragHover
                    ? context.tr('drop_here_prompt')
                    : context.tr('pick_or_drop'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _dragHover ? c.accent : c.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 5,
                runSpacing: 5,
                children:
                    const [
                      ('txt', Color(0xFF64748B)),
                      ('json', Color(0xFFD97706)),
                      ('dart', Color(0xFF0284C7)),
                      ('docx', Color(0xFF2563EB)),
                      ('xlsx', Color(0xFF16A34A)),
                      ('pdf', Color(0xFFDC2626)),
                      ('md', Color(0xFF7C3AED)),
                      ('log', Color(0xFF475569)),
                    ].map((item) {
                      final ext = item.$1;
                      final color = item.$2;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? color.withValues(alpha: 0.15)
                              : color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: isDark
                                ? color.withValues(alpha: 0.35)
                                : color.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '.$ext',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: isDark
                                ? color.withValues(alpha: 0.95)
                                : color,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Consolas',
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadedState(
    BuildContext context,
    AppColors c,
    LoadedDocument doc,
  ) {
    final badgeColor = _getBadgeColor(doc.extension);
    final previewLines = doc.lines.take(4).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  doc.extension.toUpperCase(),
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${formatFileSize(doc.sizeBytes)} · ${doc.lines.length} ${context.tr('lines_suffix')}',
                      style: TextStyle(color: c.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => widget.controller.pickFile(widget.side),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  context.tr('change_file'),
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.borderDefault),
              ),
              child: previewLines.isEmpty
                  ? Center(
                      child: Text(
                        context.tr('no_content'),
                        style: TextStyle(color: c.textSecondary, fontSize: 11),
                      ),
                    )
                  : ListView.builder(
                      itemCount: previewLines.length,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, idx) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 24,
                                child: Text(
                                  '${idx + 1}',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontFamily: 'Consolas',
                                    color: c.textSecondary.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  previewLines[idx],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'Consolas',
                                    color: c.textPrimary.withValues(
                                      alpha: 0.85,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectTextInputPane extends StatelessWidget {
  final ComparePaneSide side;
  final String title;
  final String hintText;
  final TextEditingController textController;
  final CompareController controller;

  const _DirectTextInputPane({
    required this.side,
    required this.title,
    required this.hintText,
    required this.textController,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final isDark = context.themeProvider.isDark;
    final text = textController.text;
    final linesCount = text.isEmpty ? 0 : text.split('\n').length;
    final charsCount = text.length;

    return Container(
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.borderDefault, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.4),
                border: Border(bottom: BorderSide(color: c.borderDefault)),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_note_rounded, size: 16, color: c.accent),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (text.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: c.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '$linesCount ${context.tr('lines_suffix')} · $charsCount ${context.tr('chars_suffix')}',
                        style: TextStyle(
                          color: c.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Tooltip(
                    message: context.tr('paste_tooltip'),
                    child: TextButton.icon(
                      onPressed: () => controller.pasteFromClipboard(side),
                      style: TextButton.styleFrom(
                        foregroundColor: c.textSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.paste_rounded, size: 13),
                      label: Text(
                        context.tr('paste_clipboard'),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                  if (text.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Tooltip(
                      message: context.tr('clear_side_tooltip'),
                      child: InkWell(
                        onTap: () => controller.clearSide(side),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: c.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: textController,
                  maxLines: null,
                  expands: true,
                  style: TextStyle(
                    fontFamily: 'Consolas',
                    fontSize: 12.5,
                    color: c.textPrimary,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      fontFamily: 'Consolas',
                      color: c.textSecondary.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomOptionsBar extends StatelessWidget {
  final CompareController controller;
  const _BottomOptionsBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final isDark = context.themeProvider.isDark;
    final isFolders = controller.mode == CompareMode.folders;
    final opts = controller.diffOptions;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: c.bgSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.borderDefault),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: isFolders
              ? [
                  _OptionCheckbox(
                    label: context.tr('opt_fuzzy_matching'),
                    value: controller.enableFuzzyMatching,
                    onChanged: (v) => controller.toggleFuzzyMatching(v ?? true),
                  ),
                  const SizedBox(width: 16),
                  Container(height: 14, width: 1, color: c.borderDefault),
                  const SizedBox(width: 14),
                  Icon(Icons.info_outline_rounded, size: 14, color: c.accent),
                  const SizedBox(width: 6),
                  Text(
                    'Automatically groups files with similar names (e.g. v1 / v2) across directories',
                    style: TextStyle(
                      fontSize: 11,
                      color: c.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ]
              : [
                  _OptionCheckbox(
                    label: context.tr('opt_ignore_whitespace'),
                    value: opts.ignoreWhitespace,
                    onChanged: (v) => controller.updateDiffOptions(
                      opts.copyWith(ignoreWhitespace: v ?? false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _OptionCheckbox(
                    label: context.tr('opt_ignore_case'),
                    value: opts.ignoreCase,
                    onChanged: (v) => controller.updateDiffOptions(
                      opts.copyWith(ignoreCase: v ?? false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _OptionCheckbox(
                    label: context.tr('opt_ignore_empty_lines'),
                    value: opts.ignoreEmptyLines,
                    onChanged: (v) => controller.updateDiffOptions(
                      opts.copyWith(ignoreEmptyLines: v ?? false),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(height: 14, width: 1, color: c.borderDefault),
                  const SizedBox(width: 14),
                  Text(
                    context.tr('sample_presets_label'),
                    style: TextStyle(
                      fontSize: 11,
                      color: c.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  ...SamplePresets.all.map((p) {
                    final lang = context.languageProvider.language;
                    final title = switch (lang) {
                      AppLanguage.vi => p.titleVi,
                      AppLanguage.zh => p.titleZh,
                      AppLanguage.en => p.titleEn,
                    };
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: ActionChip(
                        label: Text(title),
                        labelStyle: TextStyle(
                          fontSize: 10.5,
                          color: c.accent,
                          fontWeight: FontWeight.w600,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: c.accent.withValues(
                          alpha: isDark ? 0.15 : 0.08,
                        ),
                        side: BorderSide(
                          color: c.accent.withValues(alpha: 0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onPressed: () => controller.loadPreset(p),
                      ),
                    );
                  }),
                ],
        ),
      ),
    );
  }
}

class _OptionCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _OptionCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                activeColor: c.accent,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: value ? c.textPrimary : c.textSecondary,
                fontWeight: value ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterStatusBar extends StatelessWidget {
  final CompareController controller;
  const _FooterStatusBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: c.bgSecondary,
        border: Border(top: BorderSide(color: c.borderDefault)),
      ),
      child: Row(
        children: [
          Icon(
            controller.hasResult
                ? Icons.check_circle_outline_rounded
                : Icons.bolt_rounded,
            size: 13,
            color: controller.hasResult ? Colors.green : c.accent,
          ),
          const SizedBox(width: 6),
          Text(
            controller.hasResult
                ? '${context.tr('diff_done_hud')} ${controller.lastDiffDurationMs}ms ⚡'
                : context.tr('shortcuts_hint'),
            style: TextStyle(
              fontSize: 11,
              color: c.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            'JA Compare • v${BuildInfo.version}',
            style: TextStyle(
              fontSize: 10,
              color: c.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultScreen extends StatelessWidget {
  final CompareController controller;
  const _ResultScreen({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.mode == CompareMode.folders) {
      return DirectoryCompareView(controller: controller);
    }

    final leftName = controller.mode == CompareMode.files
        ? (controller.leftDocument?.name ?? '')
        : 'Direct Text (Left)';
    final rightName = controller.mode == CompareMode.files
        ? (controller.rightDocument?.name ?? '')
        : 'Direct Text (Right)';

    return DiffView(
      result: controller.diffResult!,
      leftLabel: leftName,
      rightLabel: rightName,
      leftPath: controller.mode == CompareMode.files
          ? controller.leftDocument?.path
          : null,
      rightPath: controller.mode == CompareMode.files
          ? controller.rightDocument?.path
          : null,
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
      icon: Icon(Icons.ios_share_rounded, size: 16, color: c.textSecondary),
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
    final leftName = controller.mode == CompareMode.files
        ? (controller.leftDocument?.name ?? 'Left')
        : 'Direct_Text_Left';
    final rightName = controller.mode == CompareMode.files
        ? (controller.rightDocument?.name ?? 'Right')
        : 'Direct_Text_Right';
    if (result == null) return;

    final language = context.languageProvider.language;
    final exportService = ExportService();
    bool? saved;
    try {
      final didSave = format == _ExportFormat.markdown
          ? await exportService.exportMarkdown(
              result: result,
              leftName: leftName,
              rightName: rightName,
              language: language,
            )
          : await exportService.exportExcel(
              result: result,
              leftName: leftName,
              rightName: rightName,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
