// test/features/import/parsing/llm/canonicalizer_test.dart
// ── Canonicalizer 单元测试 ──
// 验证 canonicalizeAnswer 将 LLM 的各种答案格式归一化为排序后的字母列表。

import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/features/import/parsing/llm/canonicalizer.dart';

void main() {
  group('canonicalizeAnswer', () {
    // Test 6: "AB" → ["A","B"]
    test('normalizes "AB" to ["A","B"]', () {
      expect(canonicalizeAnswer('AB'), ['A', 'B']);
    });

    // Test 7: "A,B" → ["A","B"]
    test('normalizes "A,B" to ["A","B"]', () {
      expect(canonicalizeAnswer('A,B'), ['A', 'B']);
    });

    // Test 8: "A和B" → ["A","B"]
    test('normalizes "A和B" to ["A","B"]', () {
      expect(canonicalizeAnswer('A和B'), ['A', 'B']);
    });

    // Test 9: '["A","B"]' → ["A","B"]
    test('normalizes JSON array format to ["A","B"]', () {
      expect(canonicalizeAnswer('["A","B"]'), ['A', 'B']);
    });

    // Test 10: "a,b" → ["A","B"] (case normalization)
    test('normalizes lowercase to uppercase', () {
      expect(canonicalizeAnswer('a,b'), ['A', 'B']);
    });

    // Test 11: "A B" → ["A","B"] (space-separated)
    test('normalizes space-separated letters', () {
      expect(canonicalizeAnswer('A B'), ['A', 'B']);
    });

    // Test 12: "C" → ["C"] (single letter)
    test('returns single letter for single-char input', () {
      expect(canonicalizeAnswer('C'), ['C']);
    });

    // Test 13: "因为A选项正确" → ["A"] (strips non-letter chars)
    test('strips non-letter characters and extracts A-H', () {
      expect(canonicalizeAnswer('因为A选项正确'), ['A']);
    });

    // Edge case: empty string → []
    test('returns empty list for empty input', () {
      expect(canonicalizeAnswer(''), isEmpty);
    });

    // Edge case: "XYZ" (no A-H letters) → []
    test('returns empty list when no A-H letters found', () {
      expect(canonicalizeAnswer('XYZ'), isEmpty);
    });

    // Edge case: "A、B" (Chinese comma separator)
    test('handles Chinese comma separator', () {
      expect(canonicalizeAnswer('A、B'), ['A', 'B']);
    });

    // Edge case: "A,B,C" deduplicates and sorts
    test('deduplicates and sorts output', () {
      expect(canonicalizeAnswer('C,B,A,C'), ['A', 'B', 'C']);
    });

    // Edge case: JSON array with mixed case
    test('handles JSON array with mixed case', () {
      expect(canonicalizeAnswer('["a","B"]'), ['A', 'B']);
    });

    // Edge case: multi-char answer like "ABC"
    test('normalizes "ABC" to ["A","B","C"]', () {
      expect(canonicalizeAnswer('ABC'), ['A', 'B', 'C']);
    });
  });

  group('formatAnswerForDisplay', () {
    test('converts canonical list to display string', () {
      expect(formatAnswerForDisplay(['A', 'B']), 'AB');
    });

    test('handles single letter', () {
      expect(formatAnswerForDisplay(['C']), 'C');
    });

    test('handles empty list', () {
      expect(formatAnswerForDisplay([]), '');
    });
  });

  group('ParseSource', () {
    test('ParseSource enum has three values', () {
      expect(ParseSource.values.length, 3);
      expect(ParseSource.values, contains(ParseSource.llm));
      expect(ParseSource.values, contains(ParseSource.heuristic));
      expect(ParseSource.values, contains(ParseSource.fallback));
    });
  });
}
