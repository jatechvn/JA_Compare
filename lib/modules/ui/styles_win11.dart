import 'package:flutter/material.dart';

import 'styles.dart';

/// Windows 11 gets genuine native Acrylic composited by DWM (see
/// theme_win11.cpp), so panels use lower opacity and subtle borders to let
/// that fluid material bleed through cleanly (per themer skill §4.1).
const win11Palette = ThemePalette(
  dark: AppColors(
    bgPrimary: Color(0x9913151D),
    bgSecondary: Color(0x991B1D28),
    sidebarBg: Color(0x66181A24),
    cardBg: Color(0x8C1F2230),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    borderDefault: Color(0x33FFFFFF),
    accent: Color(0xFF4F8CFF),
    diffAdded: Color(0x3322C55E),
    diffRemoved: Color(0x33EF4444),
    diffModified: Color(0x33F59E0B),
    diffWordAdded: Color(0x8022C55E),
    diffWordRemoved: Color(0x80EF4444),
    diffWordModified: Color(0x80F59E0B),
    cardHoverBg: Color(0xBF262A3B),
    accentGlow: Color(0x404F8CFF),
  ),
  light: AppColors(
    bgPrimary: Color(0x99F5F7FB),
    bgSecondary: Color(0x99FFFFFF),
    sidebarBg: Color(0x66EEF2F6),
    cardBg: Color(0x8CFFFFFF),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    borderDefault: Color(0x26000000),
    accent: Color(0xFF2563EB),
    diffAdded: Color(0x2E22C55E),
    diffRemoved: Color(0x2EEF4444),
    diffModified: Color(0x2EF59E0B),
    diffWordAdded: Color(0x6622C55E),
    diffWordRemoved: Color(0x66EF4444),
    diffWordModified: Color(0x66F59E0B),
    cardHoverBg: Color(0xE6FFFFFF),
    accentGlow: Color(0x332563EB),
  ),
);
