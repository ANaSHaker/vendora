import 'package:flutter/material.dart';

enum SfCardStyle  { elevated, flat, outlined, glass }
enum SfButtonShape { sharp, rounded, pill }
enum SfHeroStyle  { fullscreen, centered, split, minimal }
enum SfNavStyle   { solid, transparent, floating }

class SfThemeData {
  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color border;
  final Color primary;
  final Color primaryFg;
  final Color accent;
  final Color text;
  final Color textMuted;
  final Color textSubtle;

  final double radius;
  final SfCardStyle  cardStyle;
  final SfButtonShape buttonShape;
  final SfHeroStyle  heroStyle;
  final SfNavStyle   navStyle;

  final double       headingLetterSpacing;
  final FontWeight   headingWeight;
  final bool         uppercaseLabels;
  final double       sectionPadding;
  final Gradient?    heroGradient;
  final bool         glassNav;

  const SfThemeData({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.border,
    required this.primary,
    required this.primaryFg,
    required this.accent,
    required this.text,
    required this.textMuted,
    required this.textSubtle,
    required this.radius,
    required this.cardStyle,
    required this.buttonShape,
    required this.heroStyle,
    required this.navStyle,
    this.headingLetterSpacing = -0.5,
    this.headingWeight        = FontWeight.w700,
    this.uppercaseLabels      = false,
    this.sectionPadding       = 80,
    this.heroGradient,
    this.glassNav             = false,
  });

  double get buttonRadius => switch (buttonShape) {
    SfButtonShape.sharp   => 0,
    SfButtonShape.rounded => radius,
    SfButtonShape.pill    => 999,
  };

  SfThemeData withPrimaryOverride(Color? color) =>
      color == null ? this : _copyWithPrimary(color);

  SfThemeData _copyWithPrimary(Color c) => SfThemeData(
    background: background, surface: surface, surfaceHigh: surfaceHigh,
    border: border, primary: c, primaryFg: primaryFg, accent: accent,
    text: text, textMuted: textMuted, textSubtle: textSubtle,
    radius: radius, cardStyle: cardStyle, buttonShape: buttonShape,
    heroStyle: heroStyle, navStyle: navStyle,
    headingLetterSpacing: headingLetterSpacing, headingWeight: headingWeight,
    uppercaseLabels: uppercaseLabels, sectionPadding: sectionPadding,
    heroGradient: heroGradient, glassNav: glassNav,
  );
}
