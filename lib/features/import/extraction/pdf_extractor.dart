// lib/features/import/extraction/pdf_extractor.dart
// ── .pdf 文本提取器 ──
// 使用 pdfrx (PDFium) 提取文本层 PDF 的纯文本。
// 检测扫描件和加密 PDF，抛出明确异常。

import 'dart:io';
import 'dart:typed_data';

import 'package:pdfrx/pdfrx.dart';

/// PDF 为扫描件时抛出
class ScannedPdfException implements Exception {
  ScannedPdfException() : message = '此 PDF 为扫描件，v1 暂不支持 OCR。请使用文字型 PDF';

  final String message;

  @override
  String toString() => message;
}

/// PDF 已加密时抛出
class EncryptedPdfException implements Exception {
  EncryptedPdfException() : message = 'PDF 已加密，请先解密后再导入';

  final String message;

  @override
  String toString() => message;
}

/// 从 .pdf 文件提取纯文本。
///
/// 使用 pdfrx (PDFium) 逐页提取文本，检测文本可访问性和加密。
Future<String> extractPdfText(String filePath) async {
  final file = File(filePath);
  if (!await file.exists()) {
    throw FileSystemException('文件不存在', filePath);
  }

  if (await file.length() == 0) {
    throw const FormatException('文件为空');
  }

  final document = await PdfDocument.openFile(filePath);

  try {
    // 检查加密
    if (document.isEncrypted) {
      throw EncryptedPdfException();
    }

    final pages = document.pages;
    if (pages.isEmpty) {
      throw const FormatException('PDF 文件无页面');
    }

    final allText = StringBuffer();
    var hasAnyText = false;

    for (final page in pages) {
      final pageText = await page.loadText();
      final text = (pageText?.fullText ?? '').trim();
      if (text.isNotEmpty) {
        hasAnyText = true;
        allText.writeln(text);
      }
    }

    if (!hasAnyText) {
      throw ScannedPdfException();
    }

    final result = allText.toString().trim();
    if (result.isEmpty) {
      throw const FormatException('未能从 PDF 中提取到文本内容');
    }

    return result;
  } finally {
    await document.dispose();
  }
}

/// 从字节缓冲区提取 PDF 文本（移动端 / 内存源）。
///
/// 通过临时文件桥接到 [extractPdfText]，提取完成后清理临时文件。
Future<String> extractPdfTextFromBytes(
  Uint8List bytes, {
  required String fileName,
}) async {
  final tmpDir = Directory.systemTemp.createTempSync('redclass_pdf_');
  final tmp = File('${tmpDir.path}/$fileName');
  await tmp.writeAsBytes(bytes);
  try {
    return await extractPdfText(tmp.path);
  } finally {
    if (await tmp.exists()) await tmp.delete();
    if (await tmpDir.exists()) await tmpDir.delete(recursive: true);
  }
}
