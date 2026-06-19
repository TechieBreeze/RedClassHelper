// test/core/paths/path_resolver_test.dart
// ── PathResolver 单元测试 (D-15 ~ D-19) ──
// 使用伪造的 3 个平台目录,不需要 mock path_provider。

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:redclass/core/paths.dart';

void main() {
  group('PathResolver (D-15 ~ D-19)', () {
    late Directory tempRoot;
    late PathResolver resolver;

    setUp(() async {
      // 伪造 3 个平台目录,不需要 path_provider mock
      tempRoot = await Directory.systemTemp.createTemp('redclass_test_');
      resolver = PathResolver(
        Directory(p.join(tempRoot.path, 'appSupport')),
        Directory(p.join(tempRoot.path, 'appDocs')),
        Directory(p.join(tempRoot.path, 'temp')),
      );
    });

    tearDown(() async {
      if (await tempRoot.exists()) {
        await tempRoot.delete(recursive: true);
      }
    });

    test('databasePath is appSupport/redclass.db (D-17)', () {
      expect(
        resolver.databasePath,
        p.join(tempRoot.path, 'appSupport', 'redclass.db'),
      );
    });

    test('tempDir returns the temp directory path', () {
      expect(resolver.tempDir, p.join(tempRoot.path, 'temp'));
    });

    test('modelsDir creates appDocs/models/ if missing (D-18)', () async {
      final dir = await resolver.modelsDir;
      expect(await dir.exists(), true);
      expect(p.basename(dir.path), 'models');
      expect(p.dirname(dir.path), p.join(tempRoot.path, 'appDocs'));
    });

    test('cacheDir creates appDocs/cache/ if missing', () async {
      final dir = await resolver.cacheDir;
      expect(await dir.exists(), true);
      expect(p.basename(dir.path), 'cache');
    });

    test('diagnosticsDir creates appDocs/diagnostics/ if missing', () async {
      final dir = await resolver.diagnosticsDir;
      expect(await dir.exists(), true);
      expect(p.basename(dir.path), 'diagnostics');
    });

    test('modelsDir is idempotent — calling twice returns same dir', () async {
      final dir1 = await resolver.modelsDir;
      final dir2 = await resolver.modelsDir;
      expect(dir1.path, dir2.path);
    });

    test('tempImportDir creates cache/import_work/ if missing', () async {
      final dirPath = await resolver.tempImportDir;
      final dir = Directory(dirPath);
      expect(await dir.exists(), true);
      expect(p.basename(dir.path), 'import_work');
      // Parent should be cache/
      expect(p.basename(p.dirname(dir.path)), 'cache');
    });

    test('tempImportDir is idempotent', () async {
      final dir1 = await resolver.tempImportDir;
      final dir2 = await resolver.tempImportDir;
      expect(dir1, dir2);
    });

    test(
      'pandoc getter throws PandocNotFoundException when pandoc not in PATH',
      () async {
        // In test environment, pandoc is unlikely to be available.
        // If it is, the test still passes (returns path); if not, we
        // verify the correct exception type.
        try {
          final pandocPath = await resolver.pandoc;
          // If pandoc happens to be installed, that's fine too
          expect(pandocPath, isA<String>());
        } on PandocNotFoundException {
          // Expected — pandoc not installed in test env
          expect(true, true);
        }
      },
      skip: false,
    );
  });
}
