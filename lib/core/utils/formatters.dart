import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import '../storage/local_storage.dart';

abstract final class AppFormatters {
  static const _arabicCurrencySymbols = {
    'EGP': 'ج.م',
    'SAR': 'ر.س',
    'AED': 'د.إ',
    'KWD': 'د.ك',
    'BHD': 'د.ب',
    'OMR': 'ر.ع',
    'QAR': 'ر.ق',
    'JOD': 'د.أ',
    'LBP': 'ل.ل',
    'IQD': 'د.ع',
    'SDG': 'ج.س',
    'DZD': 'د.ج',
    'MAD': 'د.م',
    'TND': 'د.ت',
    'LYD': 'د.ل',
    'MRU': 'أ.م',
    'SYP': 'ل.س',
    'YER': 'ر.ي',
  };

  static String _storeCurrencySymbol() {
    try {
      final storage = GetIt.I<LocalStorage>();
      final code = storage.currencyCode;
      if (storage.locale == 'ar') {
        final arabicSymbol = _arabicCurrencySymbols[code.toUpperCase()];
        if (arabicSymbol != null) return arabicSymbol;
      }
      return NumberFormat.simpleCurrency(name: code).currencySymbol;
    } catch (_) {
      return '\$';
    }
  }

  // ─── Currency ─────────────────────────────────────────────────────────────
  static String currency(
    double amount, {
    String? symbol,
    int decimalDigits = 2,
  }) {
    final s = symbol ?? _storeCurrencySymbol();
    final formatter = NumberFormat.currency(
      symbol: s,
      decimalDigits: decimalDigits,
    );
    return formatter.format(amount);
  }

  static String compact(double amount, {String? symbol}) {
    final s = symbol ?? _storeCurrencySymbol();
    if (amount >= 1000000) {
      return '$s${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '$s${(amount / 1000).toStringAsFixed(1)}K';
    }
    return currency(amount, symbol: s);
  }

  // ─── Numbers ──────────────────────────────────────────────────────────────
  static String number(num value) =>
      NumberFormat('#,##0').format(value);

  static String decimal(double value, {int digits = 2}) =>
      NumberFormat('#,##0.${'0' * digits}').format(value);

  static String percent(double value, {int digits = 1}) =>
      '${value.toStringAsFixed(digits)}%';

  // ─── Dates ────────────────────────────────────────────────────────────────
  static String date(DateTime dt) =>
      DateFormat('MMM d, y').format(dt);

  static String dateShort(DateTime dt) =>
      DateFormat('MMM d').format(dt);

  static String dateTime(DateTime dt) =>
      DateFormat('MMM d, y • h:mm a').format(dt);

  static String timeOnly(DateTime dt) =>
      DateFormat('h:mm a').format(dt);

  static String dateTimeShort(DateTime dt) =>
      DateFormat('d/M/y h:mm a').format(dt);

  static String relative(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60)  return 'just now';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)    return '${diff.inHours}h ago';
    if (diff.inDays < 7)      return '${diff.inDays}d ago';
    return date(dt);
  }

  // ─── Text ─────────────────────────────────────────────────────────────────
  static String truncate(String text, {int maxLength = 30}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}…';
  }

  static String initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}
