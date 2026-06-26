// test/features/models/providers_test.dart
// ── Model download + installed models Riverpod provider tests ──

import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/core/paths.dart';
import 'package:redclass/features/models/providers/model_catalog_provider.dart';
import 'package:redclass/features/models/providers/model_download_provider.dart';
import 'package:redclass/features/models/providers/installed_models_provider.dart';

/// A fake PathResolver for testing that returns a temp directory as modelsDir.
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

void main() {
  group('ModelDownloadNotifier', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('mdl_prov_');
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

    test('initial state is idle (null)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(modelDownloadProvider);
      expect(state, isNull);
    });

    test(
      'startDownload(ModelInfo) transitions state to downloading or error',
      () async {
        final container = ProviderContainer(
          overrides: [
            pathResolverProvider.overrideWith(
              (ref) async => _FakePathResolver(tempDir.path),
            ),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(modelDownloadProvider.notifier);
        final modelInfo = container.read(modelCatalogProvider).first;

        // Start download — since there's no real server, it will fail,
        // but the state should be non-null during or after
        try {
          await notifier.startDownload(modelInfo);
        } catch (_) {
          // Expected — no real server
        }

        final state = container.read(modelDownloadProvider);
        // After completion (even error), state should be non-null
        expect(state, isNotNull);
        if (state != null) {
          // Should be error or downloading
          expect(
            state.status,
            anyOf(
              equals(DownloadProviderStatus.error),
              equals(DownloadProviderStatus.downloading),
            ),
          );
        }
      },
    );

    test('Concurrent download throws StateError', () {
      final container = ProviderContainer(
        overrides: [
          pathResolverProvider.overrideWith(
            (ref) async => _FakePathResolver(tempDir.path),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(modelDownloadProvider.notifier);
      final modelInfo = container.read(modelCatalogProvider).first;

      // Set state to "downloading" manually to simulate active download
      container.read(modelDownloadProvider.notifier).state = ActiveDownload(
        modelId: modelInfo.id,
        status: DownloadProviderStatus.downloading,
      );

      // Now startDownload should throw StateError
      expect(
        () => notifier.startDownload(modelInfo),
        throwsA(isA<StateError>()),
      );
    });

    test('cancelDownload() sets state to cancelled', () {
      final container = ProviderContainer(
        overrides: [
          pathResolverProvider.overrideWith(
            (ref) async => _FakePathResolver(tempDir.path),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(modelDownloadProvider.notifier);
      final modelInfo = container.read(modelCatalogProvider).first;

      // Set state to "downloading" manually
      container.read(modelDownloadProvider.notifier).state = ActiveDownload(
        modelId: modelInfo.id,
        status: DownloadProviderStatus.downloading,
      );

      // Cancel
      notifier.cancelDownload();

      final state = container.read(modelDownloadProvider);
      expect(state, isNotNull);
      if (state != null) {
        expect(state.status, anyOf(equals(DownloadProviderStatus.cancelled)));
      }
    });

    test('clearState() resets to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(modelDownloadProvider.notifier);
      final modelInfo = ModelInfo(
        id: 'test',
        name: 'Test',
        tier: ModelTier.custom,
        sizeBytes: 100,
        sizeDisplay: '100 B',
        ramRequirement: '1 GB',
        description: 'Test',
        downloadUrl: 'http://localhost/test.gguf',
        sha256Hash: 'TBD',
      );

      notifier.state = ActiveDownload(
        modelId: modelInfo.id,
        status: DownloadProviderStatus.done,
      );

      expect(container.read(modelDownloadProvider), isNotNull);

      notifier.clearState();

      expect(container.read(modelDownloadProvider), isNull);
    });
  });

  group('InstalledModelsProvider', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('im_prov_');
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

    test('returns empty list when modelsDir has no .gguf files', () async {
      final modelsDir = Directory('${tempDir.path}/models');
      await modelsDir.create(recursive: true);

      final container = ProviderContainer(
        overrides: [
          pathResolverProvider.overrideWith(
            (ref) async => _FakePathResolver(modelsDir.path),
          ),
        ],
      );
      addTearDown(container.dispose);

      final models = await container.read(installedModelsProvider.future);
      expect(models, isEmpty);
    });

    test('returns list with .gguf files present in modelsDir', () async {
      final modelsDir = Directory('${tempDir.path}/models');
      await modelsDir.create(recursive: true);

      // Create some .gguf files and one non-.gguf file
      await File(
        '${modelsDir.path}/model1.gguf',
      ).writeAsBytes([0x47, 0x47, 0x55, 0x46, 0x01]);
      await File(
        '${modelsDir.path}/model2.gguf',
      ).writeAsBytes([0x47, 0x47, 0x55, 0x46, 0x01, 0x02]);
      await File('${modelsDir.path}/readme.txt').writeAsBytes([0x01, 0x02]);

      final container = ProviderContainer(
        overrides: [
          pathResolverProvider.overrideWith(
            (ref) async => _FakePathResolver(modelsDir.path),
          ),
        ],
      );
      addTearDown(container.dispose);

      final models = await container.read(installedModelsProvider.future);
      expect(models.length, equals(2));

      final fileNames = models.map((m) => m.fileName).toSet();
      expect(fileNames, contains('model1.gguf'));
      expect(fileNames, contains('model2.gguf'));
      expect(fileNames, isNot(contains('readme.txt')));

      // Each InstalledModel should have filePath, fileName, sizeBytes
      for (final model in models) {
        expect(model.filePath, isNotEmpty);
        expect(model.fileName, isNotEmpty);
        expect(model.sizeBytes, greaterThan(0));
      }
    });
  });
}
