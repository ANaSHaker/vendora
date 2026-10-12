import 'package:flutter/material.dart';

enum AppColorPreset {
  navy, blue, green, orange, purple, red, black, white;

  Color get primary => switch (this) {
    AppColorPreset.navy   => const Color(0xFF0C2461),
    AppColorPreset.blue   => const Color(0xFF2563EB),
    AppColorPreset.green  => const Color(0xFF16A34A),
    AppColorPreset.orange => const Color(0xFFEA580C),
    AppColorPreset.purple => const Color(0xFF7C3AED),
    AppColorPreset.red    => const Color(0xFFDC2626),
    AppColorPreset.black  => const Color(0xFF0F172A),
    AppColorPreset.white  => const Color(0xFF64748B),
  };

  Color get swatch => switch (this) {
    AppColorPreset.white => const Color(0xFFF1F5F9),
    _ => primary,
  };

  String get nameAr => switch (this) {
    AppColorPreset.navy   => 'كحلي',
    AppColorPreset.blue   => 'أزرق',
    AppColorPreset.green  => 'أخضر',
    AppColorPreset.orange => 'برتقالي',
    AppColorPreset.purple => 'بنفسجي',
    AppColorPreset.red    => 'أحمر',
    AppColorPreset.black  => 'أسود',
    AppColorPreset.white  => 'أبيض',
  };

  String get nameEn => switch (this) {
    AppColorPreset.navy   => 'Navy',
    AppColorPreset.blue   => 'Blue',
    AppColorPreset.green  => 'Green',
    AppColorPreset.orange => 'Orange',
    AppColorPreset.purple => 'Purple',
    AppColorPreset.red    => 'Red',
    AppColorPreset.black  => 'Black',
    AppColorPreset.white  => 'White',
  };

  static AppColorPreset fromKey(String key) => AppColorPreset.values.firstWhere(
    (e) => e.name == key,
    orElse: () => AppColorPreset.navy,
  );
}
