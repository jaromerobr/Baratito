/// Brightness-aware semantic colors (light/dark) exposed as a ThemeExtension.
///
/// Brand colors (primary/accent/etc.) stay in AppColors. The *neutral* tokens
/// that must flip between light and dark live here and are read via
/// `context.palette` so every screen reacts to the active theme.
library;

import 'package:flutter/material.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color background; // scaffold background
  final Color surface; // cards, sheets, inputs over background
  final Color textPrimary; // titles / main text
  final Color textSecondary; // subtitles / muted text
  final Color textHint; // placeholders / faint icons
  final Color divider; // borders / separators
  final Color inputFill; // filled inputs / chips bg

  const AppPalette({
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.divider,
    required this.inputFill,
  });

  static const light = AppPalette(
    background: Color(0xFFF7F5F0),
    surface: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF2D2D3A),
    textSecondary: Color(0xFF6B6B7B),
    textHint: Color(0xFF9E9EAE),
    divider: Color(0xFFE0DDD6),
    inputFill: Color(0xFFF2F0EC),
  );

  static const dark = AppPalette(
    background: Color(0xFF14141C),
    surface: Color(0xFF1F1F2B),
    textPrimary: Color(0xFFECECF1),
    textSecondary: Color(0xFFA6A6B6),
    textHint: Color(0xFF6E6E80),
    divider: Color(0xFF2E2E3C),
    inputFill: Color(0xFF27273A),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? divider,
    Color? inputFill,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      divider: divider ?? this.divider,
      inputFill: inputFill ?? this.inputFill,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
    );
  }
}

/// Access the palette anywhere: `context.palette.surface`.
extension PaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
