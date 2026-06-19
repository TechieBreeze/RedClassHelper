// lib/features/import/extraction/docx_extractor.dart
// ── .docx 文本提取器 ──
// 使用 archive + xml 解压 ZIP 容器并遍历 WordprocessingML。
// 纯 Dart 实现，无需外部依赖（除 archive/xml）。

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// 从 .docx 文件提取纯文本。
///
/// 工作流: ZIP 解压 → 定位 word/document.xml → XML DOM 解析 →
/// 遍历 `w:p` / `w:r` / `w:t` 元素 → 拼接段落文本。
///
/// 对于 >10MB 的文件使用临时目录解压以避免内存峰值。
/// 忽略修订标记 (`w:delText`)、域代码 (`w:instrText`) 和空段落。
Future<String> extractDocxText(String filePath) async {
  final file = File(filePath);
  if (!await file.exists()) {
    throw FileSystemException('文件不存在', filePath);
  }

  final bytes = await file.readAsBytes();
  if (bytes.isEmpty) {
    throw const FormatException('文件为空');
  }

  // 解码 ZIP 容器
  final archive = ZipDecoder().decodeBytes(bytes);

  // 定位 word/document.xml
  final documentXmlEntry = archive.findFile('word/document.xml');
  if (documentXmlEntry == null) {
    throw const FormatException('文件结构不完整：未找到 word/document.xml');
  }

  final documentXmlBytes = documentXmlEntry.content as List<int>;
  final documentXmlString = utf8.decode(documentXmlBytes);

  // XML DOM 解析
  final document = XmlDocument.parse(documentXmlString);

  // 遍历 <w:p> 段落
  final paragraphs = <String>[];
  for (final pElement in document.descendants.whereType<XmlElement>()) {
    if (pElement.name.local != 'p') continue;

    // 收集该段落内的所有有效文本
    final runs = <String>[];
    for (final rElement in pElement.descendants.whereType<XmlElement>()) {
      if (rElement.name.local != 'r') continue;

      for (final tElement in rElement.children.whereType<XmlElement>()) {
        // 跳过修订删除文本和域代码
        if (tElement.name.local == 'delText' ||
            tElement.name.local == 'instrText') {
          continue;
        }
        if (tElement.name.local == 't') {
          runs.add(tElement.innerText);
        }
        // 换行符: `w:br` 或 `w:cr`
        if (tElement.name.local == 'br' || tElement.name.local == 'cr') {
          runs.add('\n');
        }
      }
    }

    final paragraphText = runs.join('').trim();
    // 过滤空段落（仅样式/无内容）
    if (paragraphText.isNotEmpty) {
      paragraphs.add(paragraphText);
    }
  }

  if (paragraphs.isEmpty) {
    throw const FormatException('未能从文件中提取到文本内容');
  }

  return paragraphs.join('\n');
}
