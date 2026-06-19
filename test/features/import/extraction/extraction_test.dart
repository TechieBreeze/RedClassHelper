// test/features/import/extraction/extraction_test.dart
// ── 文本提取器单元测试 ──
// 使用 doc/example/ 中的真实样本文件验证提取逻辑。

import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/features/import/extraction/docx_extractor.dart';
import 'package:redclass/features/import/extraction/pdf_extractor.dart';
import 'package:redclass/features/import/extraction/text_extractor.dart';

/// 样本文件路径辅助函数
String _samplePath(String name) {
  final dir = Directory.current.path;
  return '$dir/doc/example/$name';
}

/// 检测 PDFium 是否可用（pdfrx 测试需要原生 DLL）
bool _pdfiumAvailable() {
  try {
    DynamicLibrary.open('pdfium.dll');
    return true;
  } catch (_) {
    return false;
  }
}

void main() {
  group('DocxExtractor', () {
    test('extracts text from real .docx sample', () async {
      final path = _samplePath(
        '习近平新时代中国特色社会主义思想概论题库（2026年春季学期）5月28日修订.docx',
      );

      if (!File(path).existsSync()) {
        throw TestFailure('Sample file not found: $path');
      }

      final text = await extractDocxText(path);
      expect(text, isNotEmpty);
      expect(text.length, greaterThan(500));
      // 应包含中文题目内容
      expect(text, contains('A'));
      expect(text, contains('B'));
      // 应至少有一个段落
      expect(text.split('\n').length, greaterThan(5));
    });

    test('throws FileSystemException for missing file', () async {
      expectLater(
        extractDocxText('nonexistent.docx'),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('throws for non-ZIP file disguised as .docx', () async {
      final tmpFile =
          File('${Directory.systemTemp.path}/test_not_zip.docx');
      await tmpFile.writeAsString('not a zip file');

      try {
        await extractDocxText(tmpFile.path);
        fail('Should have thrown');
      } catch (e) {
        // archive 可能抛出 ArchiveException 或其他格式错误
        expect(e, isA<Exception>());
      } finally {
        if (await tmpFile.exists()) {
          await tmpFile.delete();
        }
      }
    });
  });

  group('PdfExtractor', () {
    test('extracts text from real .pdf sample', () async {
      if (!_pdfiumAvailable()) {
        // PDFium 尚未构建，跳过——仅在 flutter build 后可用
        return;
      }

      final path = _samplePath(
        '《纲要》选择题（2026年5月最新修订版）.pdf',
      );

      if (!File(path).existsSync()) {
        throw TestFailure('Sample file not found: $path');
      }

      final text = await extractPdfText(path);
      expect(text, isNotEmpty);
      expect(text.length, greaterThan(500));
      expect(text, contains('A'));
    });

    test('throws FileSystemException for missing file', () async {
      expectLater(
        extractPdfText('nonexistent.pdf'),
        throwsA(isA<FileSystemException>()),
      );
    });
  });

  group('TextExtractor dispatcher', () {
    test('routes .docx to docx extractor', () async {
      final path = _samplePath(
        '习近平新时代中国特色社会主义思想概论题库（2026年春季学期）5月28日修订.docx',
      );

      if (!File(path).existsSync()) {
        throw TestFailure('Sample file not found: $path');
      }

      final text = await extractText(
        path,
        fileExtension: '.docx',
      );
      expect(text, isNotEmpty);
      expect(text, contains('A'));
    });

    test('routes .pdf to pdf extractor', () async {
      if (!_pdfiumAvailable()) {
        return; // PDFium not available in test env
      }

      final path = _samplePath(
        '《纲要》选择题（2026年5月最新修订版）.pdf',
      );

      if (!File(path).existsSync()) {
        throw TestFailure('Sample file not found: $path');
      }

      final text = await extractText(
        path,
        fileExtension: '.pdf',
      );
      expect(text, isNotEmpty);
    });

    test('throws UnsupportedFormatException for .txt', () async {
      final txtFile = File(
        '${Directory.systemTemp.path}/test.txt',
      );
      await txtFile.writeAsString('sample text');

      try {
        await extractText(txtFile.path, fileExtension: '.txt');
        fail('Should have thrown');
      } catch (e) {
        expect(e.toString(), contains('不支持的文件格式'));
      } finally {
        if (await txtFile.exists()) {
          await txtFile.delete();
        }
      }
    });

    test('.doc extension requires pandoc resolvers', () async {
      final docFile = File(
        '${Directory.systemTemp.path}/test.doc',
      );
      await docFile.writeAsString('dummy');

      try {
        await extractText(docFile.path, fileExtension: '.doc');
        fail('Should have thrown');
      } on ArgumentError catch (e) {
        expect(e.toString(), contains('pandocResolver'));
      } finally {
        if (await docFile.exists()) {
          await docFile.delete();
        }
      }
    });
  });
}
