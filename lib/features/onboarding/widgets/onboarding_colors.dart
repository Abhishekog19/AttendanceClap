import 'package:flutter/material.dart';

/// Onboarding color palette — exact Stitch Material-3 monochrome tokens.
/// Primary = #000000 (pure black), background = #F9F9F9.
class OnboardingColors {
  OnboardingColors._();

  // ── Backgrounds & Surfaces ───────────────────────────────────────────────
  static const Color background             = Color(0xFFF9F9F9);
  static const Color surface               = Color(0xFFF9F9F9);
  static const Color surfaceBright         = Color(0xFFF9F9F9);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow   = Color(0xFFF3F3F3);
  static const Color surfaceContainer      = Color(0xFFEEEEEE);
  static const Color surfaceContainerHigh  = Color(0xFFE8E8E8);
  static const Color surfaceContainerHighest = Color(0xFFE2E2E2);
  static const Color surfaceDim            = Color(0xFFDADADA);
  static const Color surfaceVariant        = Color(0xFFE2E2E2);

  // ── Primary ──────────────────────────────────────────────────────────────
  static const Color primary               = Color(0xFF000000);
  static const Color onPrimary             = Color(0xFFFFFFFF);
  static const Color primaryContainer      = Color(0xFF1B1B1B);
  static const Color onPrimaryContainer    = Color(0xFF848484);
  static const Color primaryFixed          = Color(0xFFE2E2E2);
  static const Color primaryFixedDim       = Color(0xFFC6C6C6);
  static const Color inversePrimary        = Color(0xFFC6C6C6);

  // ── Secondary ────────────────────────────────────────────────────────────
  static const Color secondary             = Color(0xFF5E5E5E);
  static const Color onSecondary           = Color(0xFFFFFFFF);
  static const Color secondaryContainer    = Color(0xFFE2E2E2);
  static const Color onSecondaryContainer  = Color(0xFF646464);

  // ── Tertiary ─────────────────────────────────────────────────────────────
  static const Color tertiary              = Color(0xFF000000);
  static const Color onTertiary            = Color(0xFFFFFFFF);
  static const Color tertiaryContainer     = Color(0xFF1B1B1B);
  static const Color onTertiaryContainer   = Color(0xFF848484);
  static const Color tertiaryFixed         = Color(0xFFE2E2E2);

  // ── On-surface ───────────────────────────────────────────────────────────
  static const Color onBackground          = Color(0xFF1B1B1B);
  static const Color onSurface            = Color(0xFF1B1B1B);
  static const Color onSurfaceVariant     = Color(0xFF4C4546);

  // ── Outline ──────────────────────────────────────────────────────────────
  static const Color outline              = Color(0xFF7E7576);
  static const Color outlineVariant       = Color(0xFFCFC4C5);

  // ── Inverse ──────────────────────────────────────────────────────────────
  static const Color inverseSurface       = Color(0xFF303030);
  static const Color inverseOnSurface     = Color(0xFFF1F1F1);

  // ── Error ────────────────────────────────────────────────────────────────
  static const Color error                = Color(0xFFBA1A1A);
  static const Color onError              = Color(0xFFFFFFFF);
  static const Color errorContainer       = Color(0xFFFFDAD6);
  static const Color onErrorContainer     = Color(0xFF93000A);

  // ── Legacy short-name aliases ─────────────────────────────────────────
  static const Color bg                   = background;
  static const Color surfaceCard          = surfaceContainerLowest;
  static const Color textPrimary          = onSurface;
  static const Color textSecondary        = onSurfaceVariant;
  static const Color textHint             = outline;
  static const Color divider              = outlineVariant;
  static const Color border               = outlineVariant;
  static const Color borderFocus          = primary;
  static const Color chipSelected         = primary;
  static const Color chipUnselected       = surfaceContainer;
  static const Color chipSelectedText     = onPrimary;
  static const Color chipUnselectedText   = onSurface;
  static const Color progressBg           = surfaceContainerHighest;
  static const Color progressFill         = primary;
  static const Color skipBtn              = onSurfaceVariant;
  static const Color primaryVariant       = Color(0xFF222222);
  static const Color success              = Color(0xFF15803D);
}
