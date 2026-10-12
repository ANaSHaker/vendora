import 'package:flutter/material.dart';
import 'sf_theme_data.dart';

// ── Theme descriptor (light + dark pair) ─────────────────────────────────────

class SfTheme {
  final String   id;
  final String   nameEn;
  final String   nameAr;
  final Color    previewPrimary;
  final Color    previewBg;
  final SfThemeData light;
  final SfThemeData dark;

  const SfTheme({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.previewPrimary,
    required this.previewBg,
    required this.light,
    required this.dark,
  });
}

// ── Registry ──────────────────────────────────────────────────────────────────

abstract final class SfThemes {
  static const List<SfTheme> all = [
    luxe, breeze, forest, ember, noir, aurora,
    cobalt, sakura, dusk, slate, citrus, velvet,
  ];

  static SfTheme byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => breeze);

  // ── 1. Luxe ──────────────────────────────────────────────────────────────
  static const luxe = SfTheme(
    id: 'luxe', nameEn: 'Luxe', nameAr: 'فاخر',
    previewPrimary: Color(0xFFB8972D), previewBg: Color(0xFF0A0806),
    light: SfThemeData(
      background: Color(0xFFFAF7F2), surface: Color(0xFFF5F1EB),
      surfaceHigh: Color(0xFFEEE9E0), border: Color(0xFFD4C9B0),
      primary: Color(0xFF8B6914), primaryFg: Color(0xFFFFFFFF),
      accent: Color(0xFF5C4A1A),
      text: Color(0xFF1A1611), textMuted: Color(0xFF6B5D47), textSubtle: Color(0xFF9B8C78),
      radius: 2, cardStyle: SfCardStyle.flat, buttonShape: SfButtonShape.sharp,
      heroStyle: SfHeroStyle.fullscreen, navStyle: SfNavStyle.transparent,
      headingLetterSpacing: 2.0, headingWeight: FontWeight.w300, uppercaseLabels: true,
    ),
    dark: SfThemeData(
      background: Color(0xFF0A0806), surface: Color(0xFF14110D),
      surfaceHigh: Color(0xFF1E1A14), border: Color(0xFF3A3020),
      primary: Color(0xFFD4A843), primaryFg: Color(0xFF0A0806),
      accent: Color(0xFFE8C870),
      text: Color(0xFFF5EFE6), textMuted: Color(0xFFB8A88A), textSubtle: Color(0xFF7A6B55),
      radius: 2, cardStyle: SfCardStyle.flat, buttonShape: SfButtonShape.sharp,
      heroStyle: SfHeroStyle.fullscreen, navStyle: SfNavStyle.transparent,
      headingLetterSpacing: 2.0, headingWeight: FontWeight.w300, uppercaseLabels: true,
    ),
  );

  // ── 2. Breeze ─────────────────────────────────────────────────────────────
  static const breeze = SfTheme(
    id: 'breeze', nameEn: 'Breeze', nameAr: 'نسيم',
    previewPrimary: Color(0xFF2563EB), previewBg: Color(0xFFF8FAFC),
    light: SfThemeData(
      background: Color(0xFFF8FAFC), surface: Color(0xFFFFFFFF),
      surfaceHigh: Color(0xFFF1F5F9), border: Color(0xFFE2E8F0),
      primary: Color(0xFF2563EB), primaryFg: Color(0xFFFFFFFF),
      accent: Color(0xFF06B6D4),
      text: Color(0xFF0F172A), textMuted: Color(0xFF475569), textSubtle: Color(0xFF94A3B8),
      radius: 12, cardStyle: SfCardStyle.elevated, buttonShape: SfButtonShape.rounded,
      heroStyle: SfHeroStyle.centered, navStyle: SfNavStyle.solid,
    ),
    dark: SfThemeData(
      background: Color(0xFF0F172A), surface: Color(0xFF1E293B),
      surfaceHigh: Color(0xFF293548), border: Color(0xFF334155),
      primary: Color(0xFF60A5FA), primaryFg: Color(0xFF0F172A),
      accent: Color(0xFF22D3EE),
      text: Color(0xFFF8FAFC), textMuted: Color(0xFF94A3B8), textSubtle: Color(0xFF475569),
      radius: 12, cardStyle: SfCardStyle.elevated, buttonShape: SfButtonShape.rounded,
      heroStyle: SfHeroStyle.centered, navStyle: SfNavStyle.solid,
    ),
  );

  // ── 3. Forest ─────────────────────────────────────────────────────────────
  static const forest = SfTheme(
    id: 'forest', nameEn: 'Forest', nameAr: 'غابة',
    previewPrimary: Color(0xFF16A34A), previewBg: Color(0xFFF0FDF4),
    light: SfThemeData(
      background: Color(0xFFF0FDF4), surface: Color(0xFFFFFFFF),
      surfaceHigh: Color(0xFFDCFCE7), border: Color(0xFFBBF7D0),
      primary: Color(0xFF16A34A), primaryFg: Color(0xFFFFFFFF),
      accent: Color(0xFF65A30D),
      text: Color(0xFF052E16), textMuted: Color(0xFF166534), textSubtle: Color(0xFF4ADE80),
      radius: 20, cardStyle: SfCardStyle.outlined, buttonShape: SfButtonShape.pill,
      heroStyle: SfHeroStyle.split, navStyle: SfNavStyle.solid,
    ),
    dark: SfThemeData(
      background: Color(0xFF021A0A), surface: Color(0xFF052E16),
      surfaceHigh: Color(0xFF14532D), border: Color(0xFF166534),
      primary: Color(0xFF22C55E), primaryFg: Color(0xFF021A0A),
      accent: Color(0xFF84CC16),
      text: Color(0xFFDCFCE7), textMuted: Color(0xFF86EFAC), textSubtle: Color(0xFF4ADE80),
      radius: 20, cardStyle: SfCardStyle.outlined, buttonShape: SfButtonShape.pill,
      heroStyle: SfHeroStyle.split, navStyle: SfNavStyle.solid,
    ),
  );

  // ── 4. Ember ──────────────────────────────────────────────────────────────
  static const ember = SfTheme(
    id: 'ember', nameEn: 'Ember', nameAr: 'جمر',
    previewPrimary: Color(0xFFEA580C), previewBg: Color(0xFFFFFBF5),
    light: SfThemeData(
      background: Color(0xFFFFFBF5), surface: Color(0xFFFFFFFF),
      surfaceHigh: Color(0xFFFFF7ED), border: Color(0xFFFED7AA),
      primary: Color(0xFFEA580C), primaryFg: Color(0xFFFFFFFF),
      accent: Color(0xFFDC2626),
      text: Color(0xFF431407), textMuted: Color(0xFF9A3412), textSubtle: Color(0xFFC2410C),
      radius: 10, cardStyle: SfCardStyle.elevated, buttonShape: SfButtonShape.rounded,
      heroStyle: SfHeroStyle.fullscreen, navStyle: SfNavStyle.transparent,
    ),
    dark: SfThemeData(
      background: Color(0xFF110600), surface: Color(0xFF1C0A00),
      surfaceHigh: Color(0xFF2A1000), border: Color(0xFF431407),
      primary: Color(0xFFF97316), primaryFg: Color(0xFFFFFFFF),
      accent: Color(0xFFEF4444),
      text: Color(0xFFFFF7ED), textMuted: Color(0xFFFED7AA), textSubtle: Color(0xFFFC974A),
      radius: 10, cardStyle: SfCardStyle.elevated, buttonShape: SfButtonShape.rounded,
      heroStyle: SfHeroStyle.fullscreen, navStyle: SfNavStyle.transparent,
    ),
  );

  // ── 5. Noir ───────────────────────────────────────────────────────────────
  static const noir = SfTheme(
    id: 'noir', nameEn: 'Noir', nameAr: 'أسود',
    previewPrimary: Color(0xFF000000), previewBg: Color(0xFF000000),
    light: SfThemeData(
      background: Color(0xFFFFFFFF), surface: Color(0xFFF5F5F5),
      surfaceHigh: Color(0xFFEBEBEB), border: Color(0xFF000000),
      primary: Color(0xFF000000), primaryFg: Color(0xFFFFFFFF),
      accent: Color(0xFFFF3366),
      text: Color(0xFF000000), textMuted: Color(0xFF555555), textSubtle: Color(0xFF888888),
      radius: 0, cardStyle: SfCardStyle.outlined, buttonShape: SfButtonShape.sharp,
      heroStyle: SfHeroStyle.fullscreen, navStyle: SfNavStyle.solid,
      headingLetterSpacing: -1.0, headingWeight: FontWeight.w900, uppercaseLabels: true,
    ),
    dark: SfThemeData(
      background: Color(0xFF000000), surface: Color(0xFF111111),
      surfaceHigh: Color(0xFF1A1A1A), border: Color(0xFF333333),
      primary: Color(0xFFFFFFFF), primaryFg: Color(0xFF000000),
      accent: Color(0xFFFF3366),
      text: Color(0xFFFFFFFF), textMuted: Color(0xFFAAAAAA), textSubtle: Color(0xFF666666),
      radius: 0, cardStyle: SfCardStyle.outlined, buttonShape: SfButtonShape.sharp,
      heroStyle: SfHeroStyle.fullscreen, navStyle: SfNavStyle.solid,
      headingLetterSpacing: -1.0, headingWeight: FontWeight.w900, uppercaseLabels: true,
    ),
  );

  // ── 6. Aurora ─────────────────────────────────────────────────────────────
  static const aurora = SfTheme(
    id: 'aurora', nameEn: 'Aurora', nameAr: 'أورورا',
    previewPrimary: Color(0xFF7C3AED), previewBg: Color(0xFFFDF4FF),
    light: SfThemeData(
      background: Color(0xFFFDF4FF), surface: Color(0xFFFFFFFF),
      surfaceHigh: Color(0xFFF3E8FF), border: Color(0xFFDDD6FE),
      primary: Color(0xFF7C3AED), primaryFg: Color(0xFFFFFFFF),
      accent: Color(0xFFEC4899),
      text: Color(0xFF1A002E), textMuted: Color(0xFF6D28D9), textSubtle: Color(0xFFA78BFA),
      radius: 28, cardStyle: SfCardStyle.glass, buttonShape: SfButtonShape.pill,
      heroStyle: SfHeroStyle.centered, navStyle: SfNavStyle.floating,
      heroGradient: LinearGradient(
        colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      glassNav: true,
    ),
    dark: SfThemeData(
      background: Color(0xFF0D0017), surface: Color(0xFF1A0030),
      surfaceHigh: Color(0xFF250040), border: Color(0xFF4C0080),
      primary: Color(0xFFA855F7), primaryFg: Color(0xFFFFFFFF),
      accent: Color(0xFFF472B6),
      text: Color(0xFFF0E6FF), textMuted: Color(0xFFD8B4FE), textSubtle: Color(0xFF9F7AEA),
      radius: 28, cardStyle: SfCardStyle.glass, buttonShape: SfButtonShape.pill,
      heroStyle: SfHeroStyle.centered, navStyle: SfNavStyle.floating,
      heroGradient: LinearGradient(
        colors: [Color(0xFF6D28D9), Color(0xFFDB2777)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      glassNav: true,
    ),
  );

  // ── 7. Cobalt ─────────────────────────────────────────────────────────────
  static const cobalt = SfTheme(
    id: 'cobalt', nameEn: 'Cobalt', nameAr: 'كوبالت',
    previewPrimary: Color(0xFF1D4ED8), previewBg: Color(0xFFEFF6FF),
    light: SfThemeData(
      background: Color(0xFFEFF6FF), surface: Color(0xFFFFFFFF),
      surfaceHigh: Color(0xFFDEEBFF), border: Color(0xFFBFDBFE),
      primary: Color(0xFF1D4ED8), primaryFg: Color(0xFFFFFFFF),
      accent: Color(0xFF0EA5E9),
      text: Color(0xFF1E3A8A), textMuted: Color(0xFF3B82F6), textSubtle: Color(0xFF60A5FA),
      radius: 6, cardStyle: SfCardStyle.outlined, buttonShape: SfButtonShape.rounded,
      heroStyle: SfHeroStyle.split, navStyle: SfNavStyle.solid,
    ),
    dark: SfThemeData(
      background: Color(0xFF060D1F), surface: Color(0xFF0A1628),
      surfaceHigh: Color(0xFF0F1F3A), border: Color(0xFF1E3A8A),
      primary: Color(0xFF3B82F6), primaryFg: Color(0xFFFFFFFF),
      accent: Color(0xFF06B6D4),
      text: Color(0xFFEFF6FF), textMuted: Color(0xFF93C5FD), textSubtle: Color(0xFF60A5FA),
      radius: 6, cardStyle: SfCardStyle.outlined, buttonShape: SfButtonShape.rounded,
      heroStyle: SfHeroStyle.split, navStyle: SfNavStyle.solid,
    ),
  );

  // ── 8. Sakura ─────────────────────────────────────────────────────────────
  static const sakura = SfTheme(
    id: 'sakura', nameEn: 'Sakura', nameAr: 'ساكورا',
    previewPrimary: Color(0xFFE11D48), previewBg: Color(0xFFFFF1F5),
    light: SfThemeData(
      background: Color(0xFFFFF1F5), surface: Color(0xFFFFFFFF),
      surfaceHigh: Color(0xFFFFE4E6), border: Color(0xFFFCCDD5),
      primary: Color(0xFFE11D48), primaryFg: Color(0xFFFFFFFF),
      accent: Color(0xFFF472B6),
      text: Color(0xFF500724), textMuted: Color(0xFF9F1239), textSubtle: Color(0xFFFB7185),
      radius: 24, cardStyle: SfCardStyle.elevated, buttonShape: SfButtonShape.pill,
      heroStyle: SfHeroStyle.centered, navStyle: SfNavStyle.solid,
    ),
    dark: SfThemeData(
      background: Color(0xFF1C0010), surface: Color(0xFF2D0018),
      surfaceHigh: Color(0xFF3E0020), border: Color(0xFF881337),
      primary: Color(0xFFFB7185), primaryFg: Color(0xFF1C0010),
      accent: Color(0xFFF9A8D4),
      text: Color(0xFFFFE4E6), textMuted: Color(0xFFFDA4AF), textSubtle: Color(0xFFFB7185),
      radius: 24, cardStyle: SfCardStyle.elevated, buttonShape: SfButtonShape.pill,
      heroStyle: SfHeroStyle.centered, navStyle: SfNavStyle.solid,
    ),
  );

  // ── 9. Dusk ───────────────────────────────────────────────────────────────
  static const dusk = SfTheme(
    id: 'dusk', nameEn: 'Dusk', nameAr: 'غسق',
    previewPrimary: Color(0xFF4F46E5), previewBg: Color(0xFF0F0F1A),
    light: SfThemeData(
      background: Color(0xFFF8F7FF), surface: Color(0xFFFFFFFF),
      surfaceHigh: Color(0xFFEEECFF), border: Color(0xFFDDD8FF),
      primary: Color(0xFF4F46E5), primaryFg: Color(0xFFFFFFFF),
      accent: Color(0xFFF59E0B),
      text: Color(0xFF0F0F1A), textMuted: Color(0xFF4F48A8), textSubtle: Color(0xFF818CF8),
      radius: 12, cardStyle: SfCardStyle.flat, buttonShape: SfButtonShape.rounded,
      heroStyle: SfHeroStyle.fullscreen, navStyle: SfNavStyle.transparent,
      heroGradient: LinearGradient(
        colors: [Color(0xFF4F46E5), Color(0xFF0F0F1A)],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ),
    ),
    dark: SfThemeData(
      background: Color(0xFF0F0F1A), surface: Color(0xFF1A1B2E),
      surfaceHigh: Color(0xFF252640), border: Color(0xFF30315A),
      primary: Color(0xFF818CF8), primaryFg: Color(0xFF0F0F1A),
      accent: Color(0xFFFBBF24),
      text: Color(0xFFE2E2F8), textMuted: Color(0xFFA5B4FC), textSubtle: Color(0xFF818CF8),
      radius: 12, cardStyle: SfCardStyle.flat, buttonShape: SfButtonShape.rounded,
      heroStyle: SfHeroStyle.fullscreen, navStyle: SfNavStyle.transparent,
      heroGradient: LinearGradient(
        colors: [Color(0xFF4F46E5), Color(0xFF0F0F1A)],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ),
    ),
  );

  // ── 10. Slate ─────────────────────────────────────────────────────────────
  static const slate = SfTheme(
    id: 'slate', nameEn: 'Slate', nameAr: 'رصاصي',
    previewPrimary: Color(0xFF0F766E), previewBg: Color(0xFFF8FAFC),
    light: SfThemeData(
      background: Color(0xFFF8FAFC), surface: Color(0xFFFFFFFF),
      surfaceHigh: Color(0xFFF1F5F9), border: Color(0xFFCBD5E1),
      primary: Color(0xFF0F766E), primaryFg: Color(0xFFFFFFFF),
      accent: Color(0xFF0369A1),
      text: Color(0xFF1E293B), textMuted: Color(0xFF475569), textSubtle: Color(0xFF94A3B8),
      radius: 4, cardStyle: SfCardStyle.flat, buttonShape: SfButtonShape.sharp,
      heroStyle: SfHeroStyle.minimal, navStyle: SfNavStyle.solid,
      uppercaseLabels: true,
    ),
    dark: SfThemeData(
      background: Color(0xFF0F172A), surface: Color(0xFF1E293B),
      surfaceHigh: Color(0xFF293548), border: Color(0xFF334155),
      primary: Color(0xFF14B8A6), primaryFg: Color(0xFF0F172A),
      accent: Color(0xFF0EA5E9),
      text: Color(0xFFCBD5E1), textMuted: Color(0xFF64748B), textSubtle: Color(0xFF475569),
      radius: 4, cardStyle: SfCardStyle.flat, buttonShape: SfButtonShape.sharp,
      heroStyle: SfHeroStyle.minimal, navStyle: SfNavStyle.solid,
      uppercaseLabels: true,
    ),
  );

  // ── 11. Citrus ────────────────────────────────────────────────────────────
  static const citrus = SfTheme(
    id: 'citrus', nameEn: 'Citrus', nameAr: 'حمضيات',
    previewPrimary: Color(0xFFCA8A04), previewBg: Color(0xFFFEFCE8),
    light: SfThemeData(
      background: Color(0xFFFEFCE8), surface: Color(0xFFFFFFFF),
      surfaceHigh: Color(0xFFFEF9C3), border: Color(0xFFFEF08A),
      primary: Color(0xFFCA8A04), primaryFg: Color(0xFFFFFFFF),
      accent: Color(0xFF65A30D),
      text: Color(0xFF1A1A00), textMuted: Color(0xFF713F12), textSubtle: Color(0xFFA16207),
      radius: 16, cardStyle: SfCardStyle.elevated, buttonShape: SfButtonShape.pill,
      heroStyle: SfHeroStyle.fullscreen, navStyle: SfNavStyle.transparent,
    ),
    dark: SfThemeData(
      background: Color(0xFF12100A), surface: Color(0xFF1C1A0E),
      surfaceHigh: Color(0xFF252215), border: Color(0xFF45380A),
      primary: Color(0xFFFDE047), primaryFg: Color(0xFF1A1A00),
      accent: Color(0xFF84CC16),
      text: Color(0xFFFEF9C3), textMuted: Color(0xFFFDE047), textSubtle: Color(0xFFA16207),
      radius: 16, cardStyle: SfCardStyle.elevated, buttonShape: SfButtonShape.pill,
      heroStyle: SfHeroStyle.fullscreen, navStyle: SfNavStyle.transparent,
    ),
  );

  // ── 12. Velvet ────────────────────────────────────────────────────────────
  static const velvet = SfTheme(
    id: 'velvet', nameEn: 'Velvet', nameAr: 'مخمل',
    previewPrimary: Color(0xFF9F1239), previewBg: Color(0xFF0A0005),
    light: SfThemeData(
      background: Color(0xFFFFF1F8), surface: Color(0xFFFFFFFF),
      surfaceHigh: Color(0xFFFFE4F0), border: Color(0xFFFDA4C8),
      primary: Color(0xFF9F1239), primaryFg: Color(0xFFFFFFFF),
      accent: Color(0xFFD946EF),
      text: Color(0xFF4C0519), textMuted: Color(0xFF881337), textSubtle: Color(0xFFBE123C),
      radius: 10, cardStyle: SfCardStyle.glass, buttonShape: SfButtonShape.rounded,
      heroStyle: SfHeroStyle.fullscreen, navStyle: SfNavStyle.transparent,
      heroGradient: LinearGradient(
        colors: [Color(0xFF4C0519), Color(0xFF150010)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      glassNav: true,
    ),
    dark: SfThemeData(
      background: Color(0xFF0A0005), surface: Color(0xFF150010),
      surfaceHigh: Color(0xFF1F0018), border: Color(0xFF4C0519),
      primary: Color(0xFFBE123C), primaryFg: Color(0xFFFFFFFF),
      accent: Color(0xFFD946EF),
      text: Color(0xFFFDF2F8), textMuted: Color(0xFFFDA4C8), textSubtle: Color(0xFFBE185D),
      radius: 10, cardStyle: SfCardStyle.glass, buttonShape: SfButtonShape.rounded,
      heroStyle: SfHeroStyle.fullscreen, navStyle: SfNavStyle.transparent,
      heroGradient: LinearGradient(
        colors: [Color(0xFF4C0519), Color(0xFF0A0005)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      glassNav: true,
    ),
  );
}
