import 'package:flutter/material.dart';

abstract final class AppRadius {
  static const double none = 0;
  static const double xs   = 4;
  static const double sm   = 6;
  static const double md   = 8;
  static const double base = 10;
  static const double lg   = 12;
  static const double xl   = 14;
  static const double xl2  = 18;
  static const double xl3  = 22;
  static const double xl4  = 28;
  static const double full = 9999;

  // BorderRadius shortcuts
  static const BorderRadius brNone = BorderRadius.zero;

  static const BorderRadius brXs   = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius brSm   = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brMd   = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brBase = BorderRadius.all(Radius.circular(base));
  static const BorderRadius brLg   = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius brXl   = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius brXl2  = BorderRadius.all(Radius.circular(xl2));
  static const BorderRadius brXl3  = BorderRadius.all(Radius.circular(xl3));
  static const BorderRadius brFull = BorderRadius.all(Radius.circular(full));
}
