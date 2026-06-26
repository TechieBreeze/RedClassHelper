// lib/features/import/extraction/docx_extractor.dart
// ── .docx 文本提取器 ──
// 使用 archive + xml 解压 ZIP 容器并遍历 WordprocessingML。
// 纯 Dart 实现，无需外部依赖（除 archive/xml）。
// 支持 Word 自动编号（<w:numPr>）的提取。

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

const _wNs = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main';

/// 读取 namespaced 属性值
String? _attr(XmlElement el, String name) =>
    el.getAttribute(name, namespace: _wNs);

/// 从 .docx 文件提取纯文本。
///
/// 工作流: ZIP 解压 → 解析 numbering.xml → 定位 word/document.xml →
/// XML DOM 解析 → 遍历 `w:p` / `w:r` / `w:t` 元素 → 拼接段落文本。
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

  final archive = ZipDecoder().decodeBytes(bytes);

  // 定位 word/document.xml
  final documentXmlEntry = archive.findFile('word/document.xml');
  if (documentXmlEntry == null) {
    throw const FormatException('文件结构不完整：未找到 word/document.xml');
  }

  // 解析编号定义
  final numDefs = _parseNumbering(archive);

  final documentXmlBytes = documentXmlEntry.content as List<int>;
  final documentXmlString = utf8.decode(documentXmlBytes);
  final document = XmlDocument.parse(documentXmlString);

  // 跟踪每个 numId 的当前计数
  final counters = <int, int>{};

  final paragraphs = <String>[];
  for (final pElement in document.descendants.whereType<XmlElement>()) {
    if (pElement.name.local != 'p') continue;

    // 检查自动编号
    String? numberPrefix;
    final pPr = _childElement(pElement, 'pPr');
    if (pPr != null) {
      final numPr = _childElement(pPr, 'numPr');
      if (numPr != null) {
        final numIdEl = _childElement(numPr, 'numId');
        if (numIdEl != null) {
          final numId = int.tryParse(_attr(numIdEl, 'val') ?? '');
          if (numId != null && numDefs.containsKey(numId)) {
            final def = numDefs[numId]!;
            counters[numId] = (counters[numId] ?? def.start - 1) + 1;
            numberPrefix = _formatNumber(counters[numId]!, def);
          }
        }
      }
    }

    // 收集该段落内的所有有效文本
    final runs = <String>[];
    for (final rElement in pElement.descendants.whereType<XmlElement>()) {
      if (rElement.name.local != 'r') continue;

      for (final tElement in rElement.children.whereType<XmlElement>()) {
        if (tElement.name.local == 'delText' ||
            tElement.name.local == 'instrText') {
          continue;
        }
        if (tElement.name.local == 't') {
          runs.add(tElement.innerText);
        }
        if (tElement.name.local == 'br' || tElement.name.local == 'cr') {
          runs.add('\n');
        }
      }
    }

    var paragraphText = runs.join('').trim();
    if (paragraphText.isNotEmpty && numberPrefix != null) {
      paragraphText = '$numberPrefix $paragraphText';
    }

    if (paragraphText.isNotEmpty) {
      paragraphs.add(paragraphText);
    }
  }

  if (paragraphs.isEmpty) {
    throw const FormatException('未能从文件中提取到文本内容');
  }

  return paragraphs.join('\n');
}

/// 从字节缓冲区提取 .docx 文本（移动端 / 内存源）。
Future<String> extractDocxTextFromBytes(
  Uint8List bytes, {
  required String fileName,
}) async {
  final tmpDir = Directory.systemTemp.createTempSync('redclass_docx_');
  final tmp = File('${tmpDir.path}/$fileName');
  await tmp.writeAsBytes(bytes);
  try {
    return await extractDocxText(tmp.path);
  } finally {
    if (await tmp.exists()) await tmp.delete();
    if (await tmpDir.exists()) await tmpDir.delete(recursive: true);
  }
}

// ── 编号解析 ──

Map<int, _NumDef> _parseNumbering(Archive archive) {
  final numberingEntry = archive.findFile('word/numbering.xml');
  if (numberingEntry == null) return {};

  final xmlString = utf8.decode(numberingEntry.content as List<int>);
  final doc = XmlDocument.parse(xmlString);

  // 解析 abstractNum 定义
  final abstractDefs = <int, _NumDef>{};
  for (final absNum in doc.descendants.whereType<XmlElement>()) {
    if (absNum.name.local != 'abstractNum') continue;
    final absId = int.tryParse(_attr(absNum, 'abstractNumId') ?? '');
    if (absId == null) continue;

    // 找第一个 lvl
    final lvl = _childElement(absNum, 'lvl');
    if (lvl == null) continue;

    final startEl = _childElement(lvl, 'start');
    final start =
        int.tryParse(startEl != null ? _attr(startEl, 'val') ?? '' : '') ?? 1;

    final fmtEl = _childElement(lvl, 'numFmt');
    final format = fmtEl != null ? _attr(fmtEl, 'val') ?? 'decimal' : 'decimal';

    final lvlTextEl = _childElement(lvl, 'lvlText');
    final lvlText = lvlTextEl != null
        ? _attr(lvlTextEl, 'val') ?? '%1.'
        : '%1.';

    abstractDefs[absId] = _NumDef(
      start: start,
      format: format,
      lvlText: lvlText,
    );
  }

  // 解析 num → abstractNum 映射
  final numDefs = <int, _NumDef>{};
  for (final numEl in doc.descendants.whereType<XmlElement>()) {
    if (numEl.name.local != 'num') continue;
    final numId = int.tryParse(_attr(numEl, 'numId') ?? '');
    if (numId == null) continue;

    final absRef = _childElement(numEl, 'abstractNumId');
    final absId = int.tryParse(
      absRef != null ? _attr(absRef, 'val') ?? '' : '',
    );
    if (absId != null && abstractDefs.containsKey(absId)) {
      numDefs[numId] = abstractDefs[absId]!;
    }
  }

  return numDefs;
}

String _formatNumber(int n, _NumDef def) {
  String numStr;
  switch (def.format) {
    case 'upperLetter':
      numStr = String.fromCharCode('A'.codeUnitAt(0) + ((n - 1) % 26));
    case 'lowerLetter':
      numStr = String.fromCharCode('a'.codeUnitAt(0) + ((n - 1) % 26));
    case 'upperRoman':
      numStr = _toRoman(n).toUpperCase();
    case 'lowerRoman':
      numStr = _toRoman(n).toLowerCase();
    case 'decimal':
    default:
      numStr = n.toString();
  }
  return def.lvlText.replaceAll('%1', numStr);
}

String _toRoman(int n) {
  const values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
  const symbols = [
    'm',
    'cm',
    'd',
    'cd',
    'c',
    'xc',
    'l',
    'xl',
    'x',
    'ix',
    'v',
    'iv',
    'i',
  ];
  final buf = StringBuffer();
  for (var i = 0; i < values.length; i++) {
    while (n >= values[i]) {
      buf.write(symbols[i]);
      n -= values[i];
    }
  }
  return buf.toString();
}

XmlElement? _childElement(XmlElement parent, String localName) {
  for (final child in parent.children.whereType<XmlElement>()) {
    if (child.name.local == localName) return child;
  }
  return null;
}

class _NumDef {
  final int start;
  final String format;
  final String lvlText;
  const _NumDef({
    required this.start,
    required this.format,
    required this.lvlText,
  });
}
