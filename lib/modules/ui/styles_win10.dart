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
    textPrimary: Colors.white,
    textSecondary: Colors.white70,
    borderDefault: Colors.white10,
    accent: Color(0xFF4F8CFF),
    diffAdded: Color(0x4022C55E),
    diffRemoved: Color(0x40EF4444),
    diffModified: Color(0x40F59E0B),
  ),
  light: AppColors(
    bgPrimary: Color(0xCCF3F4F6),
    bgSecondary: Color(0xD9FAFAFB),
    sidebarBg: Color(0xB2E9EAF0),
    cardBg: Color(0xD9FFFFFF),
    textPrimary: Colors.black87,
    textSecondary: Colors.black54,
    borderDefault: Colors.black12,
    accent: Color(0xFF2563EB),
    diffAdded: Color(0x4022C55E),
    diffRemoved: Color(0x40EF4444),
    diffModified: Color(0x40F59E0B),
  ),
);
