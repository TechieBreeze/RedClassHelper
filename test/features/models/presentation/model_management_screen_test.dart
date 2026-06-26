// test/features/models/presentation/model_management_screen_test.dart
// ── Widget tests for SettingsScreen and ModelManagementScreen ──

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/core/paths.dart';
import 'package:redclass/features/models/providers/model_catalog_provider.dart';
import 'package:redclass/features/models/providers/model_download_provider.dart';
import 'package:redclass/features/models/services/model_downloader.dart';
import 'package:redclass/features/models/providers/installed_models_provider.dart';
import 'package:redclass/features/models/presentation/settings_screen.dart';
import 'package:redclass/features/models/presentation/model_management_screen.dart';
import 'package:redclass/features/models/widgets/model_card.dart';
import 'package:redclass/features/models/widgets/download_progress.dart';
import 'package:redclass/features/models/widgets/add_model_dialog.dart';

/// Fake PathResolver for tests that returns an empty temp models dir.
class _FakePathResolver extends Fake implements PathResolver {
  final String _modelsPath;

  _FakePathResolver(this._modelsPath);

  @override
  Future<Directory> get modelsDir async {
    final dir = Directory(_modelsPath);
    // 使用同步 I/O 避免 testWidgets 的 FakeAsync zone 卡住真实 I/O Future
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
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
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
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
    child: MaterialApp(home: child),
  );
}

void main() {
  group('SettingsScreen', () {
    testWidgets('renders 设置 AppBar title', (tester) async {
      await tester.pumpWidget(_wrapWithProviders(const SettingsScreen()));
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('设置'), findsOneWidget);
    });

    testWidgets('renders 模型管理 ListTile on desktop', (tester) async {
      await tester.pumpWidget(_wrapWithProviders(const SettingsScreen()));
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump();
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
          child: const MaterialApp(home: ModelManagementScreen()),
        ),
      );
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('模型管理'), findsOneWidget);
    });

    testWidgets('renders 3 sections: 已安装模型, 推荐模型, 自定义模型', (tester) async {
      final modelsPath = '${tempDir.path}/models';
      await Directory(modelsPath).create(recursive: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pathResolverProvider.overrideWith(
              (ref) async => _FakePathResolver(modelsPath),
            ),
          ],
          child: const MaterialApp(home: ModelManagementScreen()),
        ),
      );
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('已安装模型'), findsOneWidget);
      expect(find.text('推荐模型'), findsOneWidget);
      expect(find.text('自定义模型'), findsOneWidget);
    });

    testWidgets('renders empty state 尚未安装模型 when no models installed', (
      tester,
    ) async {
      final modelsPath = '${tempDir.path}/models';
      await Directory(modelsPath).create(recursive: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pathResolverProvider.overrideWith(
              (ref) async => _FakePathResolver(modelsPath),
            ),
          ],
          child: const MaterialApp(home: ModelManagementScreen()),
        ),
      );
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('尚未安装模型'), findsOneWidget);
      expect(find.text('从下方推荐模型中选择一个下载，或添加自定义模型'), findsOneWidget);
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
          child: const MaterialApp(home: ModelManagementScreen()),
        ),
      );
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump();

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
          child: const MaterialApp(home: ModelManagementScreen()),
        ),
      );
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump();

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
          child: const MaterialApp(home: ModelManagementScreen()),
        ),
      );
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('添加模型'), findsOneWidget);
      expect(find.text('通过 URL 或本地文件添加自定义 .gguf 模型'), findsOneWidget);
    });

    testWidgets('tapping 添加模型 opens AddModelDialog', (tester) async {
      final modelsPath = '${tempDir.path}/models';
      await Directory(modelsPath).create(recursive: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pathResolverProvider.overrideWith(
              (ref) async => _FakePathResolver(modelsPath),
            ),
          ],
          child: const MaterialApp(home: ModelManagementScreen()),
        ),
      );
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump();

      // Tap the "添加模型" card
      await tester.tap(find.text('添加模型'));
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump();

      // Dialog should appear with 2 tabs
      expect(find.text('添加自定义模型'), findsOneWidget);
      expect(find.text('从 URL 下载'), findsOneWidget);
      expect(find.text('选择本地文件'), findsOneWidget);
    });

    testWidgets('renders download buttons for non-installed catalog models', (
      tester,
    ) async {
      final modelsPath = '${tempDir.path}/models';
      await Directory(modelsPath).create(recursive: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pathResolverProvider.overrideWith(
              (ref) async => _FakePathResolver(modelsPath),
            ),
          ],
          child: const MaterialApp(home: ModelManagementScreen()),
        ),
      );
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump();

      // All 3 models have "下载" buttons since none are installed
      expect(find.text('下载'), findsNWidgets(3));
    });

    testWidgets('renders model metadata (size + RAM) for catalog models', (
      tester,
    ) async {
      final modelsPath = '${tempDir.path}/models';
      await Directory(modelsPath).create(recursive: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pathResolverProvider.overrideWith(
              (ref) async => _FakePathResolver(modelsPath),
            ),
          ],
          child: const MaterialApp(home: ModelManagementScreen()),
        ),
      );
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('约 1.2 GB'), findsOneWidget);
      expect(find.textContaining('需 2-3 GB'), findsOneWidget);
      expect(find.textContaining('约 0.5 GB'), findsOneWidget);
      expect(find.textContaining('需 1-2 GB'), findsOneWidget);
      expect(find.textContaining('约 2.2 GB'), findsOneWidget);
      expect(find.textContaining('需 4 GB+'), findsOneWidget);
    });
  });

  group('ModelCard', () {
    final testModel = const ModelInfo(
      id: 'test-model',
      name: 'Test Model Q4_K_M',
      tier: ModelTier.recommended,
      sizeBytes: 500000000,
      sizeDisplay: '约 0.5 GB',
      ramRequirement: '需 1-2 GB 可用内存',
      description: '高性能测试模型。',
      downloadUrl: 'https://example.com/model.gguf',
      sha256Hash: 'TBD',
    );

    Widget _wrap(Widget child) {
      return ProviderScope(
        overrides: [
          pathResolverProvider.overrideWith(
            (ref) async =>
                _SimpleFakePathResolver('${Directory.systemTemp.path}/models'),
          ),
        ],
        child: MaterialApp(home: Scaffold(body: child)),
      );
    }

    testWidgets('idle model card renders 下载 button', (tester) async {
      await tester.pumpWidget(_wrap(ModelCard(model: testModel)));
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('下载'), findsOneWidget);
      expect(find.text('推荐'), findsOneWidget);
    });

    testWidgets('downloading model card renders progress indicator', (
      tester,
    ) async {
      final progress = DownloadProgress(
        bytesDownloaded: 50000000,
        totalBytes: 500000000,
        speedBytesPerSec: 3145728,
      );
      final activeDownload = ActiveDownload(
        modelId: 'test-model',
        status: DownloadProviderStatus.downloading,
        progress: progress,
      );

      await tester.pumpWidget(
        _wrap(ModelCard(model: testModel, activeDownload: activeDownload)),
      );
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.textContaining('下载中'), findsOneWidget);
    });

    testWidgets('installed model card renders 已安装 chip', (tester) async {
      await tester.pumpWidget(
        _wrap(ModelCard(model: testModel, isInstalled: true)),
      );
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('已安装'), findsOneWidget);
      expect(find.text('删除'), findsOneWidget);
    });

    testWidgets('model card with another active download shows 等待中', (
      tester,
    ) async {
      final otherDownload = ActiveDownload(
        modelId: 'other-model',
        status: DownloadProviderStatus.downloading,
      );

      await tester.pumpWidget(
        _wrap(ModelCard(model: testModel, activeDownload: otherDownload)),
      );
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('等待中'), findsOneWidget);
    });

    testWidgets('error model card shows 重新下载 button', (tester) async {
      final errorDownload = ActiveDownload(
        modelId: 'test-model',
        status: DownloadProviderStatus.error,
        errorMessage: '下载失败：网络连接异常',
      );

      await tester.pumpWidget(
        _wrap(ModelCard(model: testModel, activeDownload: errorDownload)),
      );
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('重新下载'), findsOneWidget);
      expect(find.textContaining('网络连接异常'), findsOneWidget);
    });
  });

  group('DownloadProgressWidget', () {
    testWidgets('renders percentage and speed', (tester) async {
      final progress = DownloadProgress(
        bytesDownloaded: 150000000,
        totalBytes: 500000000,
        speedBytesPerSec: 5242880,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DownloadProgressWidget(progress: progress)),
        ),
      );
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump();

      // 0.3 * 100 = 30
      expect(find.textContaining('30%'), findsOneWidget);
      // 5242880 / 1048576 = 5.0
      expect(find.textContaining('5.0 MB/s'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });

  group('AddModelDialog', () {
    testWidgets('renders 2 tabs and title', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      // Show the dialog
      showAddModelDialog(tester.element(find.byType(SizedBox)));
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('添加自定义模型'), findsOneWidget);
      expect(find.text('从 URL 下载'), findsOneWidget);
      expect(find.text('选择本地文件'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
    });

    testWidgets('URL validation: non-HTTPS shows error', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      showAddModelDialog(tester.element(find.byType(SizedBox)));
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump();

      // Enter non-HTTPS URL
      await tester.enterText(
        find.byType(TextField),
        'http://example.com/model.gguf',
      );
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('请输入有效的 HTTPS URL'), findsOneWidget);
    });

    testWidgets('URL validation: non-.gguf path shows error', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      showAddModelDialog(tester.element(find.byType(SizedBox)));
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump();

      // Enter HTTPS URL without .gguf
      await tester.enterText(
        find.byType(TextField),
        'https://example.com/model.bin',
      );
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('该地址不指向 .gguf 文件'), findsOneWidget);
    });

    testWidgets('URL validation: valid HTTPS .gguf URL clears errors', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      showAddModelDialog(tester.element(find.byType(SizedBox)));
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump();

      // Enter valid URL
      await tester.enterText(
        find.byType(TextField),
        'https://huggingface.co/Qwen/model.gguf',
      );
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump();

      // No error should be visible, submit button enabled
      expect(find.text('请输入有效的 HTTPS URL'), findsNothing);
      expect(find.text('该地址不指向 .gguf 文件'), findsNothing);
      // "添加并下载" button should be enabled
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '添加并下载'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('cancel button dismisses dialog', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      showAddModelDialog(tester.element(find.byType(SizedBox)));
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('取消'));
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump();

      // Dialog should be closed
      expect(find.text('添加自定义模型'), findsNothing);
    });
  });
}
