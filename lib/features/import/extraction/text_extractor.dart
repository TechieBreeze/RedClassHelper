// lib/features/import/extraction/text_extractor.dart
// ── 文本提取调度器 ──
// 根据文件扩展名路由到正确的提取器。
// 统一异常包装，为上层提供一致的错误类型。

import 'dart:typed_data';

import 'doc_extractor.dart';
import 'docx_extractor.dart';
import 'pdf_extractor.dart';

/// 文件格式不支持时抛出
class UnsupportedFormatException implements Exception {
  UnsupportedFormatException(this.extension_)
    : message =
          '不支持的文件格式 "$extension_"，'
          '请选择 .doc/.docx/.pdf 文件';

  final String extension_;
  final String message;

  @override
  String toString() => message;
}

/// 根据文件扩展名分发到正确的文本提取器。
///
/// 支持的格式: .docx → [extractDocxText], .pdf → [extractPdfText],
/// .doc → [extractDocText] (需 pandoc)。
///
/// [pandocResolver] 和 [tempImportDirResolver] 仅在 .doc 提取时需要。
Future<String> extractText(
  String filePath, {
  required String fileExtension,
  Future<String> Function()? pandocResolver,
  Future<String> Function()? tempImportDirResolver,
}) async {
  final ext = fileExtension.toLowerCase().replaceAll('.', '');

  switch (ext) {
    case 'docx':
      return extractDocxText(filePath);
    case 'pdf':
      return extractPdfText(filePath);
    case 'doc':
      if (pandocResolver == null || tempImportDirResolver == null) {
        throw ArgumentError(
          'pandocResolver and tempImportDirResolver are required for .doc extraction',
        );
      }
      return extractDocText(
        filePath,
        pandocResolver: pandocResolver,
        tempImportDirResolver: tempImportDirResolver,
      );
    default:
      throw UnsupportedFormatException(ext);
  }
}

/// 基于字节流的文本提取（移动端 / 内存源）。
///
/// 与 [extractText] 行为一致，但接受 [Stream] 形式的字节而非文件路径。
/// 用于 [PickedBytesFile] 等无磁盘路径的来源。
Future<String> extractTextFromStream(
  Stream<Uint8List> bytes, {
  required String fileName,
  required String fileExtension,
  Future<String> Function()? pandocResolver,
  Future<String> Function()? tempImportDirResolver,
}) async {
  final ext = fileExtension.toLowerCase().replaceAll('.', '');
  final material = await _collectBytes(bytes);

  switch (ext) {
    case 'docx':
      return extractDocxTextFromBytes(material, fileName: fileName);
    case 'pdf':
      return extractPdfTextFromBytes(material, fileName: fileName);
    case 'doc':
      if (pandocResolver == null || tempImportDirResolver == null) {
        throw ArgumentError(
          'pandocResolver and tempImportDirResolver are required for .doc extraction',
        );
      }
      return extractDocTextFromBytes(
        material,
        fileName: fileName,
        pandocResolver: pandocResolver,
        tempImportDirResolver: tempImportDirResolver,
      );
    default:
      throw UnsupportedFormatException(ext);
  }
}

Future<Uint8List> _collectBytes(Stream<Uint8List> stream) async {
  final builder = BytesBuilder(copy: false);
  await for (final chunk in stream) {
    builder.add(chunk);
  }
  return builder.toBytes();
}
