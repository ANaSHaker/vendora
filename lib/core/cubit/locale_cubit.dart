import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../storage/local_storage.dart';

class LocaleCubit extends Cubit<Locale> {
  final LocalStorage _storage;

  static const supportedLocales = [
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
    Locale('it'),
    Locale('de'),
  ];

  LocaleCubit(this._storage) : super(Locale(_storage.locale)) {
    Intl.defaultLocale = _storage.locale;
  }

  void setLocale(Locale locale) {
    _storage.saveLocale(locale.languageCode);
    Intl.defaultLocale = locale.languageCode;
    emit(locale);
  }

  void toggle() {
    final codes = supportedLocales.map((l) => l.languageCode).toList();
    final idx = codes.indexOf(state.languageCode);
    final next = codes[(idx + 1) % codes.length];
    setLocale(Locale(next));
  }
}
