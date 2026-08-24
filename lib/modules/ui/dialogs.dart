import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../modules/build_info.dart';
import '../constants.dart';
import '../services/settings_service.dart';
import 'language_scope.dart';
import 'styles.dart';

/// A frosted-glass modal shell — blur strength/opacity default to the
/// persisted `dialog_blur`/`dialog_opacity` settings but can be overridden
/// for a live preview while the user drags a slider.
class GlassDialog extends StatelessWidget {
  final Widget child;
  final String title;
  final double width;
  final double height;
  final double? blurSigma;
  final double? bgOpacity;

  const GlassDialog({
    super.key,
    required this.child,
    required this.title,
    this.width = 640,
    this.height = 480,
    this.blurSigma,
    this.bgOpacity,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final settings = SettingsService.loadSettings();
    final sigma = blurSigma ?? settings['dialog_blur']!;
    final opacity = bgOpacity ?? settings['dialog_opacity']!;
    final enableTransparency = Platform.isWindows;
    final bg = enableTransparency
        ? c.bgSecondary.withValues(alpha: opacity)
        : c.bgSecondary;
    final border = enableTransparency
        ? c.borderDefault.withValues(alpha: (opacity * 0.5).clamp(0.1, 0.8))
        : c.borderDefault;

    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: width,
            height: height,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DialogHeader(title: title),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  final String title;
  const _DialogHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.borderDefault)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: c.textSecondary, size: 18),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}

/// 3-tab settings dialog: Advanced (glassmorphism sliders), Guide, About —
/// per the blueprint's Settings/Glassmorphism/Dialog architecture.
class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late double _bgBlur;
  late double _bgOpacity;
  late double _dialogBlur;
  late double _dialogOpacity;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCurrent();
  }

  void _loadCurrent() {
    final s = SettingsService.loadSettings();
    _bgBlur = s['bg_blur']!;
    _bgOpacity = s['bg_opacity']!;
    _dialogBlur = s['dialog_blur']!;
    _dialogOpacity = s['dialog_opacity']!;
  }

  void _resetToDefaults() {
    setState(() {
      final defaults = SettingsService.defaultSettings;
      _bgBlur = defaults['bg_blur']!;
      _bgOpacity = defaults['bg_opacity']!;
      _dialogBlur = defaults['dialog_blur']!;
      _dialogOpacity = defaults['dialog_opacity']!;
    });
  }

  void _saveSettings() {
    SettingsService.saveSettings({
      'bg_blur': _bgBlur,
      'bg_opacity': _bgOpacity,
      'dialog_blur': _dialogBlur,
      'dialog_opacity': _dialogOpacity,
    });
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GlassDialog(
      title: context.tr('settings_title'),
      width: 560,
      height: 580,
      // Live preview: the dialog itself re-blurs as the sliders move.
      blurSigma: _dialogBlur,
      bgOpacity: _dialogOpacity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            controller: _tabController,
            labelColor: c.accent,
            unselectedLabelColor: c.textSecondary,
            indicatorColor: c.accent,
            tabs: [
              Tab(text: context.tr('tab_advanced')),
              Tab(text: context.tr('tab_about')),
              Tab(text: context.tr('tab_guide')),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAdvancedTab(c),
                _buildAboutTab(c),
                _buildGuideTab(c),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedTab(AppColors c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('glass_section_title'),
            style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: false,
              collapsedIconColor: c.textSecondary,
              iconColor: c.accent,
              title: Text(
                context.tr('glass_customize'),
                style: TextStyle(color: c.textPrimary, fontSize: 13),
              ),
              children: [
                _blurSlider(
                  c,
                  label: context.tr('bg_blur_label'),
                  value: _bgBlur,
                  max: 30,
                  onChanged: (v) => setState(() => _bgBlur = v),
                ),
                _blurSlider(
                  c,
                  label: context.tr('bg_opacity_label'),
                  value: _bgOpacity,
                  max: 1,
                  min: 0.1,
                  isPercent: true,
                  onChanged: (v) => setState(() => _bgOpacity = v),
                ),
                _blurSlider(
                  c,
                  label: context.tr('dialog_blur_label'),
                  value: _dialogBlur,
                  max: 30,
                  onChanged: (v) => setState(() => _dialogBlur = v),
                ),
                _blurSlider(
                  c,
                  label: context.tr('dialog_opacity_label'),
                  value: _dialogOpacity,
                  max: 1,
                  min: 0.1,
                  isPercent: true,
                  onChanged: (v) => setState(() => _dialogOpacity = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetToDefaults,
                  child: Text(context.tr('reset_defaults')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saveSettings,
                  child: Text(context.tr('save_settings')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _blurSlider(
    AppColors c, {
    required String label,
    required double value,
    required double max,
    double min = 0,
    bool isPercent = false,
    required ValueChanged<double> onChanged,
  }) {
    final display = isPercent
        ? '${(value * 100).round()}%'
        : value.toStringAsFixed(1);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(color: c.textSecondary, fontSize: 12),
              ),
              Text(
                display,
                style: TextStyle(color: c.textPrimary, fontSize: 12),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(activeTrackColor: c.accent),
            child: Slider(
              min: min,
              max: max,
              value: value,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideTab(AppColors c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Text(
        context.tr('guide_body'),
        style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.6),
      ),
    );
  }

  Widget _buildAboutTab(AppColors c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appName,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${context.tr('version_label')} $appVersion',
            style: TextStyle(color: c.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('about_description'),
            style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('developed_by'),
            style: TextStyle(color: c.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => launchUrl(Uri.parse(appWebsite)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.link, size: 14, color: c.accent),
                const SizedBox(width: 4),
                Text(
                  '${context.tr('website_label')}: ${appWebsite.replaceFirst('https://', '')}',
                  style: TextStyle(
                    color: c.accent,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => launchUrl(Uri.parse(appGithub)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.code, size: 14, color: c.accent),
                const SizedBox(width: 4),
                Text(
                  '${context.tr('github_label')}: ${appGithub.replaceFirst('https://', '')}',
                  style: TextStyle(
                    color: c.accent,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
          if (BuildInfo.isDebug) ...[
            const SizedBox(height: 12),
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
        ],
      ),
    );
  }
}
