import 'package:flutter/material.dart';

import 'styles.dart';

/// Windows 11 gets genuine native Acrylic composited by DWM (see
/// theme_win11.cpp), so panels use lower opacity and subtle borders to let
/// that fluid material bleed through cleanly (per themer skill §4.1).
const win11Palette = ThemePalette(
  dark: AppColors(
    bgPrimary: Color(0x991A1A22),
    bgSecondary: Color(0x99202028),
    sidebarBg: Color(0x66202028),
    cardBg: Color(0x8C24242E),
    textPrimary: Colors.white,
    textSecondary: Colors.white70,
    borderDefault: Colors.white10,
    accent: Color(0xFF4F8CFF),
    diffAdded: Color(0x3322C55E),
    diffRemoved: Color(0x33EF4444),
    diffModified: Color(0x33F59E0B),
  ),
  light: AppColors(
    bgPrimary: Color(0x99F5F5F7),
    bgSecondary: Color(0x99FAFAFB),
    sidebarBg: Color(0x66FFFFFF),
    cardBg: Color(0x8CFFFFFF),
    textPrimary: Colors.black87,
    textSecondary: Colors.black54,
    borderDefault: Colors.black12,
    accent: Color(0xFF2563EB),
    diffAdded: Color(0x3322C55E),
    diffRemoved: Color(0x33EF4444),
    diffModified: Color(0x33F59E0B),
  ),
);
