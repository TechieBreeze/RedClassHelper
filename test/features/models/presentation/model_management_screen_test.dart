// test/features/models/presentation/model_management_screen_test.dart
// ── Widget tests for SettingsScreen and ModelManagementScreen ──

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/core/paths.dart';
import 'package:redclass/features/models/providers/model_catalog_provider.dart';
import 'package:redclass/features/models/providers/model_download_provider.dart';
import 'package:redclass/features/models/providers/installed_models_provider.dart';
import 'package:redclass/features/models/presentation/settings_screen.dart';
import 'package:redclass/features/models/presentation/model_management_screen.dart';

/// Fake PathResolver for tests that returns an empty temp models dir.
class _FakePathResolver extends Fake implements PathResolver {
  final String _modelsPath;

  _FakePathResolver(this._modelsPath);

  @override
  Future<Directory> get modelsDir async {
    final dir = Directory(_modelsPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}

/// A simpler fake that just returns an existing temp directory.
class _SimpleFakePathResolver extends Fake implements PathResolver {
  final String _modelsPath;

  _SimpleFakePathResolver(this._modelsPath);

  @override
  Future<Directory> get modelsDir async {
    final dir = Directory(_modelsPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}

Widget _wrapWithProviders(Widget child, {Directory? tempDir}) {
  final dir = tempDir ?? Directory.systemTemp;
  // Ensure models dir exists
  final modelsPath = '${dir.path}/models';
  Directory(modelsPath).createSync(recursive: true);

  return ProviderScope(
    overrides: [
      pathResolverProvider.overrideWith(
        (ref) async => _SimpleFakePathResolver(modelsPath),
      ),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  group('SettingsScreen', () {
    testWidgets('renders 设置 AppBar title', (tester) async {
      await tester.pumpWidget(_wrapWithProviders(const SettingsScreen()));
      await tester.pumpAndSettle();
      expect(find.text('设置'), findsOneWidget);
    });

    testWidgets('renders 模型管理 ListTile on desktop', (tester) async {
      await tester.pumpWidget(_wrapWithProviders(const SettingsScreen()));
      await tester.pumpAndSettle();
      if (Platform.isWindows || Platform.isLinux) {
        expect(find.text('模型管理'), findsOneWidget);
        expect(find.text('查看已安装模型、下载推荐模型'), findsOneWidget);
      }
    });
  });

  group('ModelManagementScreen', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('mm_test_');
    });

    tearDown(() async {
      try {
        await Future.delayed(const Duration(milliseconds: 200));
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {
        // Best effort cleanup
      }
    });

    testWidgets('renders 模型管理 AppBar title', (tester) async {
      final modelsPath = '${tempDir.path}/models';
      await Directory(modelsPath).create(recursive: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pathResolverProvider.overrideWith(
              (ref) async => _FakePathResolver(modelsPath),
            ),
          ],
          child: const MaterialApp(
            home: ModelManagementScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('模型管理'), findsOneWidget);
    });

    testWidgets('renders 3 sections: 已安装模型, 推荐模型, 自定义模型',
        (tester) async {
      final modelsPath = '${tempDir.path}/models';
      await Directory(modelsPath).create(recursive: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pathResolverProvider.overrideWith(
              (ref) async => _FakePathResolver(modelsPath),
            ),
          ],
          child: const MaterialApp(
            home: ModelManagementScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('已安装模型'), findsOneWidget);
      expect(find.text('推荐模型'), findsOneWidget);
      expect(find.text('自定义模型'), findsOneWidget);
    });

    testWidgets('renders empty state 尚未安装模型 when no models installed',
        (tester) async {
      final modelsPath = '${tempDir.path}/models';
      await Directory(modelsPath).create(recursive: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pathResolverProvider.overrideWith(
              (ref) async => _FakePathResolver(modelsPath),
            ),
          ],
          child: const MaterialApp(
            home: ModelManagementScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('尚未安装模型'), findsOneWidget);
      expect(
        find.text('从下方推荐模型中选择一个下载，或添加自定义模型'),
        findsOneWidget,
      );
    });

    testWidgets('renders 3 catalog model cards', (tester) async {
      final modelsPath = '${tempDir.path}/models';
      await Directory(modelsPath).create(recursive: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pathResolverProvider.overrideWith(
              (ref) async => _FakePathResolver(modelsPath),
            ),
          ],
          child: const MaterialApp(
            home: ModelManagementScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Three preset model names from catalog
      expect(find.text('Qwen2.5-1.5B Q4_K_M'), findsOneWidget);
      expect(find.text('Qwen2.5-0.5B Q4_K_M'), findsOneWidget);
      expect(find.text('Qwen2.5-3B Q4_K_M'), findsOneWidget);
    });

    testWidgets('renders tier badges for catalog models', (tester) async {
      final modelsPath = '${tempDir.path}/models';
      await Directory(modelsPath).create(recursive: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pathResolverProvider.overrideWith(
              (ref) async => _FakePathResolver(modelsPath),
            ),
          ],
          child: const MaterialApp(
            home: ModelManagementScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('推荐'), findsOneWidget);
      expect(find.text('快速'), findsOneWidget);
      expect(find.text('实验'), findsOneWidget);
    });

    testWidgets('renders 添加模型 card in custom section', (tester) async {
      final modelsPath = '${tempDir.path}/models';
      await Directory(modelsPath).create(recursive: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pathResolverProvider.overrideWith(
              (ref) async => _FakePathResolver(modelsPath),
            ),
          ],
          child: const MaterialApp(
            home: ModelManagementScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('添加模型'), findsOneWidget);
      expect(
        find.text('通过 URL 或本地文件添加自定义 .gguf 模型'),
        findsOneWidget,
      );
    });

    testWidgets('tapping 添加模型 shows snackbar placeholder', (tester) async {
      final modelsPath = '${tempDir.path}/models';
      await Directory(modelsPath).create(recursive: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pathResolverProvider.overrideWith(
              (ref) async => _FakePathResolver(modelsPath),
            ),
          ],
          child: const MaterialApp(
            home: ModelManagementScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the "添加模型" card
      await tester.tap(find.text('添加模型'));
      await tester.pumpAndSettle();

      // Placeholder snackbar should appear
      expect(find.text('添加自定义模型 — Task 2 实现'), findsOneWidget);
    });

    testWidgets('renders download buttons for non-installed catalog models',
        (tester) async {
      final modelsPath = '${tempDir.path}/models';
      await Directory(modelsPath).create(recursive: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pathResolverProvider.overrideWith(
              (ref) async => _FakePathResolver(modelsPath),
            ),
          ],
          child: const MaterialApp(
            home: ModelManagementScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // All 3 models have "下载" buttons since none are installed
      expect(find.text('下载'), findsNWidgets(3));
    });

    testWidgets('renders model metadata (size + RAM) for catalog models',
        (tester) async {
      final modelsPath = '${tempDir.path}/models';
      await Directory(modelsPath).create(recursive: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pathResolverProvider.overrideWith(
              (ref) async => _FakePathResolver(modelsPath),
            ),
          ],
          child: const MaterialApp(
            home: ModelManagementScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('约 1.2 GB'), findsOneWidget);
      expect(find.textContaining('需 2-3 GB'), findsOneWidget);
      expect(find.textContaining('约 0.5 GB'), findsOneWidget);
      expect(find.textContaining('需 1-2 GB'), findsOneWidget);
      expect(find.textContaining('约 2.2 GB'), findsOneWidget);
      expect(find.textContaining('需 4 GB+'), findsOneWidget);
    });
  });
}
