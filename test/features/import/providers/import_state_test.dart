// test/features/import/providers/import_state_test.dart
// ── ImportState 单元测试 ──
// 验证 ImportPhase 枚举扩展和 ImportState 新增字段。

import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/features/import/parsing/llm/canonicalizer.dart';
import 'package:redclass/features/import/providers/import_state.dart';

void main() {
  group('ImportPhase', () {
    // Test 1: ImportPhase enum has 8 values including llmParsing
    test('has 8 values including llmParsing between parsing and editing', () {
      expect(ImportPhase.values.length, 8);
      expect(ImportPhase.values, contains(ImportPhase.llmParsing));

      // llmParsing should come after parsing and before editing
      final parsingIdx = ImportPhase.values.indexOf(ImportPhase.parsing);
      final llmParsingIdx = ImportPhase.values.indexOf(ImportPhase.llmParsing);
      final editingIdx = ImportPhase.values.indexOf(ImportPhase.editing);
      expect(llmParsingIdx, greaterThan(parsingIdx));
      expect(llmParsingIdx, lessThan(editingIdx));
    });
  });

  group('ImportState parseSources', () {
    // Test 2: ImportState has parseSources field
    test('has parseSources field of type Map<int, ParseSource>', () {
      const state = ImportState();
      expect(state.parseSources, isA<Map<int, ParseSource>>());
    });

    // Test 3: ImportState default parseSources is empty Map
    test('default parseSources is empty Map', () {
      const state = ImportState();
      expect(state.parseSources, isEmpty);
    });

    // Test 4: copyWith() correctly updates parseSources
    test('copyWith correctly updates parseSources', () {
      const state = ImportState();
      final updated = state.copyWith(
        parseSources: {0: ParseSource.llm, 1: ParseSource.fallback},
      );
      expect(updated.parseSources.length, 2);
      expect(updated.parseSources[0], ParseSource.llm);
      expect(updated.parseSources[1], ParseSource.fallback);
    });
  });

  group('ImportState isLlmParsing', () {
    // Test 5: isLlmParsing returns true when phase == ImportPhase.llmParsing
    test('returns true when phase is llmParsing', () {
      const state = ImportState(phase: ImportPhase.llmParsing);
      expect(state.isLlmParsing, isTrue);
    });

    test('returns false when phase is parsing (heuristic)', () {
      const state = ImportState(phase: ImportPhase.parsing);
      expect(state.isLlmParsing, isFalse);
    });

    test('returns false when phase is editing', () {
      const state = ImportState(phase: ImportPhase.editing);
      expect(state.isLlmParsing, isFalse);
    });

    test('returns false when phase is idle', () {
      const state = ImportState(phase: ImportPhase.idle);
      expect(state.isLlmParsing, isFalse);
    });
  });
}
