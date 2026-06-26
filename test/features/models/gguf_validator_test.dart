// test/features/models/gguf_validator_test.dart
// ── GGUF validator + model catalog provider unit tests ──

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/features/models/services/gguf_validator.dart';
import 'package:redclass/features/models/providers/model_catalog_provider.dart';

void main() {
  group('GgufValidator (magic number validation)', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('gguf_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('.gguf file with correct GGUF magic number returns true', () async {
      final file = File('${tempDir.path}/valid.gguf');
      await file.writeAsBytes([0x47, 0x47, 0x55, 0x46, 0x01, 0x00, 0x00, 0x00]);

      final result = await GgufValidator.isGgufFile(file.path);
      expect(result, isTrue);
    });

    test('.exe file returns false (wrong extension)', () async {
      final file = File('${tempDir.path}/test.exe');
      await file.writeAsBytes([0x47, 0x47, 0x55, 0x46, 0x01, 0x00]);

      final result = await GgufValidator.isGgufFile(file.path);
      expect(result, isFalse);
    });

    test('.gguf file with wrong magic number returns false', () async {
      final file = File('${tempDir.path}/fake.gguf');
      await file.writeAsBytes([0x00, 0x01, 0x02, 0x03, 0x04, 0x05]);

      final result = await GgufValidator.isGgufFile(file.path);
      expect(result, isFalse);
    });

    test(
      '.gguf file with correct magic but only 3 bytes returns false',
      () async {
        final file = File('${tempDir.path}/short.gguf');
        await file.writeAsBytes([
          0x47,
          0x47,
          0x55,
        ]); // Only 3 bytes — missing 'F'

        final result = await GgufValidator.isGgufFile(file.path);
        expect(result, isFalse);
      },
    );

    test('non-existent file returns false', () async {
      final result = await GgufValidator.isGgufFile(
        '${tempDir.path}/nope.gguf',
      );
      expect(result, isFalse);
    });

    test('.txt file returns false', () async {
      final file = File('${tempDir.path}/test.txt');
      await file.writeAsBytes([0x47, 0x47, 0x55, 0x46]);

      final result = await GgufValidator.isGgufFile(file.path);
      expect(result, isFalse);
    });

    test('validateGgufFile returns null for valid GGUF file', () async {
      final file = File('${tempDir.path}/valid2.gguf');
      await file.writeAsBytes([0x47, 0x47, 0x55, 0x46, 0x01]);

      final result = await GgufValidator.validateGgufFile(file.path);
      expect(result, isNull);
    });

    test(
      'validateGgufFile returns "仅支持 .gguf 文件" for non-.gguf extension',
      () async {
        final result = await GgufValidator.validateGgufFile(
          '${tempDir.path}/test.exe',
        );
        expect(result, equals('仅支持 .gguf 文件'));
      },
    );

    test(
      'validateGgufFile returns error message for .gguf with wrong magic',
      () async {
        final file = File('${tempDir.path}/bad.gguf');
        await file.writeAsBytes([0x01, 0x02, 0x03, 0x04]);

        final result = await GgufValidator.validateGgufFile(file.path);
        expect(result, equals('文件格式无效，无法识别为 GGUF 模型'));
      },
    );

    test('validateGgufFile returns error for non-existent .gguf', () async {
      final result = await GgufValidator.validateGgufFile(
        '${tempDir.path}/missing.gguf',
      );
      expect(result, equals('文件格式无效，无法识别为 GGUF 模型'));
    });
  });

  group('ModelCatalogProvider (3-tier preset models)', () {
    test('modelCatalogProvider returns 3 models', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final catalog = container.read(modelCatalogProvider);
      expect(catalog.length, equals(3));
    });

    test('models have tiers: recommended, fast, experimental', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final catalog = container.read(modelCatalogProvider);
      final tiers = catalog.map((m) => m.tier).toSet();
      expect(
        tiers,
        containsAll([
          ModelTier.recommended,
          ModelTier.fast,
          ModelTier.experimental,
        ]),
      );
    });

    test(
      'Recommended model has name "Qwen2.5-1.5B Q4_K_M" and tier recommended',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final catalog = container.read(modelCatalogProvider);
        final recommended = catalog.firstWhere(
          (m) => m.tier == ModelTier.recommended,
        );
        expect(recommended.name, equals('Qwen2.5-1.5B Q4_K_M'));
        expect(recommended.sizeBytes, equals(1200000000));
      },
    );

    test('Each ModelInfo has all required fields: id, name, tier, sizeBytes, '
        'ramRequirement, description, downloadUrl, sha256Hash', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final catalog = container.read(modelCatalogProvider);
      for (final model in catalog) {
        expect(model.id, isNotEmpty);
        expect(model.name, isNotEmpty);
        expect(model.tier, isA<ModelTier>());
        expect(model.sizeBytes, greaterThan(0));
        expect(model.ramRequirement, isNotEmpty);
        expect(model.description, isNotEmpty);
        expect(model.downloadUrl, isNotEmpty);
        expect(model.sha256Hash, isNotEmpty);
      }
    });

    test('downloadUrl uses HuggingFace /resolve/main/ pattern', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final catalog = container.read(modelCatalogProvider);
      for (final model in catalog) {
        expect(model.downloadUrl, contains('huggingface.co'));
        expect(model.downloadUrl, contains('/resolve/main/'));
        expect(model.downloadUrl, endsWith('.gguf'));
      }
    });
  });
}
