// test/features/import/parsing/llm/chunker_test.dart
// ── Chunker 单元测试 ──
// 验证 splitIntoQuestionBlocks 按题号拆分原始文本。

import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/features/import/parsing/llm/chunker.dart';

void main() {
  group('splitIntoQuestionBlocks', () {
    // Test 1: Multi-question English numbering split
    test('splits multi-question text by English number pattern', () {
      const input = '1. Question One\nA. Option\nB. Option\n\n2. Question Two\n'
          'A. Option\nB. Option';
      final blocks = splitIntoQuestionBlocks(input);
      expect(blocks.length, 2);
      expect(blocks[0], contains('Question One'));
      expect(blocks[1], contains('Question Two'));
    });

    // Test 2: Empty input → empty list
    test('returns empty list for empty input', () {
      expect(splitIntoQuestionBlocks(''), isEmpty);
      expect(splitIntoQuestionBlocks('   \n\n  '), isEmpty);
    });

    // Test 3: Single question with no number prefix → single block
    test('returns single block for text without question numbers', () {
      const input = 'This is just plain text without any question numbering.';
      final blocks = splitIntoQuestionBlocks(input);
      expect(blocks.length, 1);
      expect(blocks[0], input);
    });

    // Test 4: Chinese number pattern "1、题目" matches
    test('matches Chinese顿号 number pattern', () {
      const input = '1、下列关于马克思主义的说法正确的是\nA. 选项一\nB. 选项二\n\n'
          '2、辩证法的核心是\nA. 对立统一\nB. 量变质变';
      final blocks = splitIntoQuestionBlocks(input);
      expect(blocks.length, 2);
      expect(blocks[0], contains('马克思主义'));
      expect(blocks[1], contains('辩证法'));
    });

    // Test 5: Preserves multi-line stems
    test('preserves multi-line stem text before first option', () {
      const input = '1. This is a question stem\n'
          'that spans multiple lines\n'
          'and continues further.\n'
          'A. Option one\n'
          'B. Option two';
      final blocks = splitIntoQuestionBlocks(input);
      expect(blocks.length, 1);
      expect(blocks[0], contains('spans multiple lines'));
      expect(blocks[0], contains('Option one'));
    });

    // Test 6: Chinese parenthesized numbering （1）
    test('matches Chinese parenthesized numbering （1）', () {
      const input = '（1）题目一内容\nA. 选项A\nB. 选项B\n\n'
          '（2）题目二内容\nA. 选项C\nB. 选项D';
      final blocks = splitIntoQuestionBlocks(input);
      expect(blocks.length, 2);
    });

    // Test 7: Chinese circled number ① pattern
    test('matches circled number ① pattern', () {
      const input = '①题目一\nA. 选项\nB. 选项\n\n'
          '②题目二\nA. 选项\nB. 选项';
      final blocks = splitIntoQuestionBlocks(input);
      expect(blocks.length, 2);
    });

    // Test 8: Mixed numbering patterns
    test('handles mixed Chinese and English numbering', () {
      const input = '1. English numbered\nA. Option\n\n'
          '2、Chinese顿号 numbered\nA. 选项\n\n'
          '3) Parenthesized\nA. Option';
      final blocks = splitIntoQuestionBlocks(input);
      expect(blocks.length, 3);
    });

    // Test 9: Real exam text with answers interspersed
    test('handles exam text with answer lines after questions', () {
      const input = '1. 马克思主义哲学的核心观点是\n'
          'A. 唯物辩证法\nB. 唯心主义\nC. 形而上学\nD. 二元论\n'
          '答案：A\n'
          '解析：唯物辩证法是马克思主义哲学的核心观点。\n\n'
          '2. 实践是检验真理的唯一标准\n'
          'A. 正确\nB. 错误\n'
          '答案：A';
      final blocks = splitIntoQuestionBlocks(input);
      expect(blocks.length, 2);
      expect(blocks[0], contains('马克思主义哲学'));
      expect(blocks[1], contains('实践是检验真理'));
    });
  });
}
