// lib/features/import/extraction/doc_extractor.dart
// ── .doc 文本提取器 (pandoc 桥接) ──
// 使用 pandoc CLI 将 .doc (Word 97-2003) 转换为 .docx 后，
// 委托给 docx_extractor 提取纯文本。

import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../../../core/paths.dart';
import 'docx_extractor.dart';

/// 从 .doc 文件提取纯文本。
///
/// 工作流:
/// 1. 通过 PathResolver 检测 pandoc 可用性
/// 2. pandoc --from doc --to docx → 临时 .docx 文件
/// 3. 委托给 [extractDocxText] 提取文本
/// 4. 清理临时文件
Future<String> extractDocText(
  String filePath, {
  required Future<String> Function() pandocResolver,
  required Future<String> Function() tempImportDirResolver,
}) async {
  final file = File(filePath);
  if (!await file.exists()) {
    throw FileSystemException('文件不存在', filePath);
  }

  if (await file.length() == 0) {
    throw const FormatException('文件为空');
  }

  // 1. 解析 pandoc 路径
  final pandocPath = await pandocResolver();

  // 2. 准备临时输出路径
  final tempDir = await tempImportDirResolver();
  final baseName = p.basenameWithoutExtension(filePath);
  final tempDocxPath = p.join(tempDir, '${baseName}_pandoc_converted.docx');

  try {
    // 3. 运行 pandoc 转换
    final result = await Process.run(pandocPath, [
      filePath,
      '--from',
      'doc',
      '--to',
      'docx',
      '--output',
      tempDocxPath,
    ], runInShell: true);

    if (result.exitCode != 0) {
      final stderr = (result.stderr as String).trim();
      throw FormatException(
        '文件转换失败，请尝试将 .doc 另存为 .docx 后导入'
        '${stderr.isNotEmpty ? ' ($stderr)' : ''}',
      );
    }

    // 4. 验证输出文件
    if (!await File(tempDocxPath).exists()) {
      throw const FormatException(
        '文件转换失败，pandoc 未生成输出文件。'
        '请尝试将 .doc 另存为 .docx 后导入',
      );
    }

    // 5. 委托给 .docx 提取器
    final text = await extractDocxText(tempDocxPath);
    return text;
  } on PandocNotFoundException {
    rethrow;
  } finally {
    // 6. 清理临时文件
    try {
      final tempFile = File(tempDocxPath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (_) {
      // 清理失败不阻塞流程
    }
  }
}

/// 从字节缓冲区提取 .doc 文本（移动端 / 内存源）。
///
/// 工作流：写入临时 .doc → 委托给 pandoc 转 .docx → 委托给 [extractDocxText]。
Future<String> extractDocTextFromBytes(
  Uint8List bytes, {
  required String fileName,
  required Future<String> Function() pandocResolver,
  required Future<String> Function() tempImportDirResolver,
}) async {
  final tmpDir = Directory.systemTemp.createTempSync('redclass_doc_');
  final tmpDoc = File('${tmpDir.path}/$fileName');
  await tmpDoc.writeAsBytes(bytes);
  try {
    return await extractDocText(
      tmpDoc.path,
      pandocResolver: pandocResolver,
      tempImportDirResolver: tempImportDirResolver,
    );
  } finally {
    if (await tmpDoc.exists()) await tmpDoc.delete();
    if (await tmpDir.exists()) await tmpDir.delete(recursive: true);
  }
}
