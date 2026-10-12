import 'dart:ffi';
import 'dart:io' show Platform;

typedef _BeepNative = Bool Function(Uint32, Uint32);
typedef _BeepDart   = bool Function(int, int);

_BeepDart? _loadBeep() {
  try {
    return DynamicLibrary.open('kernel32.dll')
        .lookupFunction<_BeepNative, _BeepDart>('Beep');
  } catch (_) {
    return null;
  }
}

class PosSoundService {
  PosSoundService._();

  static final _BeepDart? _fn = Platform.isWindows ? _loadBeep() : null;

  static void addItem()      => _fn?.call(1050, 70);
  static void scanSuccess()  => _fn?.call(1300, 90);
  static void undo()         => _fn?.call(680,  80);
  static void scanError()    { _fn?.call(260, 70); _fn?.call(210, 70); }
  static void orderSuccess() { _fn?.call(880, 100); _fn?.call(1100, 150); }
}
