import 'package:flutter/material.dart';

import 'styles.dart';

/// Windows 10 has no native Acrylic — the Aero blur behind the window is a
/// flatter, lower-fidelity blur, so panels use higher-opacity solid
/// overlays here to keep content readable and block high-frequency desktop
/// noise from bleeding through (per themer skill §4.1).
const win10Palette = ThemePalette(
  dark: AppColors(
    bgPrimary: Color(0xCC0B0F19),
    bgSecondary: Color(0xD911141D),
    sidebarBg: Color(0xB2151922),
    cardBg: Color(0xD91A1E29),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    borderDefault: Color(0x26FFFFFF),
    accent: Color(0xFF4F8CFF),
    diffAdded: Color(0x4022C55E),
    diffRemoved: Color(0x40EF4444),
    diffModified: Color(0x40F59E0B),
    diffWordAdded: Color(0x8022C55E),
    diffWordRemoved: Color(0x80EF4444),
    diffWordModified: Color(0x80F59E0B),
    cardHoverBg: Color(0xF2222735),
    accentGlow: Color(0x404F8CFF),
  ),
  light: AppColors(
    bgPrimary: Color(0xCCF3F4F6),
    bgSecondary: Color(0xD9FAFAFB),
    sidebarBg: Color(0xB2E9EAF0),
    cardBg: Color(0xD9FFFFFF),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    borderDefault: Color(0x1F000000),
    accent: Color(0xFF2563EB),
    diffAdded: Color(0x3322C55E),
    diffRemoved: Color(0x33EF4444),
    diffModified: Color(0x33F59E0B),
    diffWordAdded: Color(0x7322C55E),
    diffWordRemoved: Color(0x73EF4444),
    diffWordModified: Color(0x73F59E0B),
    cardHoverBg: Color(0xFFFFFFFF),
    accentGlow: Color(0x332563EB),
  ),
);
