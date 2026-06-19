// lib/features/models/services/gguf_validator.dart
// ── GGUF file format validator ──
// Validates .gguf files using magic number check: 0x47 0x47 0x55 0x46 = "GGUF"

import 'dart:io';

class GgufValidator {
  static const _ggufMagic = [0x47, 0x47, 0x55, 0x46]; // "GGUF"

  /// Returns true if the file at [filePath] is a valid GGUF model file.
  static Future<bool> isGgufFile(String filePath) async {
    if (!filePath.toLowerCase().endsWith('.gguf')) return false;
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;
      final bytes = await file.openRead(0, 4).first;
      return bytes.length == 4 &&
          bytes[0] == _ggufMagic[0] &&
          bytes[1] == _ggufMagic[1] &&
          bytes[2] == _ggufMagic[2] &&
          bytes[3] == _ggufMagic[3];
    } on FileSystemException {
      return false;
    }
  }

  /// Validates a GGUF file and returns a result message.
  /// Returns null if valid, or an error string if invalid.
  static Future<String?> validateGgufFile(String filePath) async {
    if (!filePath.toLowerCase().endsWith('.gguf')) {
      return '仅支持 .gguf 文件';
    }
    final isValid = await isGgufFile(filePath);
    if (!isValid) {
      return '文件格式无效，无法识别为 GGUF 模型';
    }
    return null; // Valid
  }
}
