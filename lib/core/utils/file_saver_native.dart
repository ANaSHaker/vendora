import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint;

Future<String?> saveExportFile(List<int> bytes, String filename) async {
  if (bytes.isEmpty) return null;
  try {
    final dir = _resolveDir();
    await dir.create(recursive: true);
    final file = File('${dir.path}${Platform.pathSeparator}$filename');
    final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    await file.writeAsBytes(data, flush: true);
    return file.path;
  } catch (e) {
    debugPrint('[Export] _saveFile failed: $e');
    return null;
  }
}

Directory _resolveDir() {
  if (Platform.isWindows) {
    final profile = Platform.environment['USERPROFILE'];
    if (profile != null) {
      final dl = Directory('$profile\\Downloads');
      if (dl.existsSync()) return dl;
      final docs = Directory('$profile\\Documents');
      if (docs.existsSync()) return docs;
    }
    return Directory(
        Platform.environment['TEMP'] ?? Platform.environment['TMP'] ?? 'C:\\Temp');
  }
  return Directory.systemTemp;
}
