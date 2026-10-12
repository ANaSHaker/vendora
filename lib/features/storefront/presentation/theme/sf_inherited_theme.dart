import 'package:flutter/material.dart';
import 'sf_theme_data.dart';

class StorefrontTheme extends InheritedWidget {
  final SfThemeData data;

  const StorefrontTheme({super.key, required this.data, required super.child});

  static SfThemeData of(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<StorefrontTheme>();
    assert(w != null, 'No StorefrontTheme found in widget tree');
    return w!.data;
  }

  @override
  bool updateShouldNotify(StorefrontTheme old) => old.data != data;
}
