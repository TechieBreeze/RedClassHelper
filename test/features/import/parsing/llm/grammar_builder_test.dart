// test/features/import/parsing/llm/grammar_builder_test.dart
// ── Grammar Builder 单元测试 ──
// 验证 JSON Schema 生成和 GBNF 转换。

import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/features/import/parsing/llm/grammar_builder.dart';

void main() {
  group('buildQuestionJsonSchema', () {
    // Test 14: Returns Map with required keys
    test('returns Map with required keys', () {
      final schema = buildQuestionJsonSchema();
      expect(schema, isA<Map<String, dynamic>>());
      expect(schema['type'], 'object');
      expect(schema['properties'], isA<Map<String, dynamic>>());
      expect(schema['required'], isA<List>());
      expect(schema['additionalProperties'], false);
    });

    test('properties contains title, type, options, answer, explanation', () {
      final schema = buildQuestionJsonSchema();
      final props = schema['properties'] as Map<String, dynamic>;
      expect(props.containsKey('title'), isTrue);
      expect(props.containsKey('type'), isTrue);
      expect(props.containsKey('options'), isTrue);
      expect(props.containsKey('answer'), isTrue);
      expect(props.containsKey('explanation'), isTrue);
    });

    test('answer property has pattern constraint for A-H', () {
      final schema = buildQuestionJsonSchema();
      final props = schema['properties'] as Map<String, dynamic>;
      final answer = props['answer'] as Map<String, dynamic>;
      expect(answer['pattern'], '^[A-H]+\$');
    });

    test('required list includes title, type, options, answer', () {
      final schema = buildQuestionJsonSchema();
      final required = schema['required'] as List;
      expect(required, contains('title'));
      expect(required, contains('type'));
      expect(required, contains('options'));
      expect(required, contains('answer'));
    });

    test('type enum includes single, multiple, truefalse, unknown', () {
      final schema = buildQuestionJsonSchema();
      final props = schema['properties'] as Map<String, dynamic>;
      final type = props['type'] as Map<String, dynamic>;
      final enumValues = type['enum'] as List;
      expect(enumValues, contains('single'));
      expect(enumValues, contains('multiple'));
      expect(enumValues, contains('truefalse'));
      expect(enumValues, contains('unknown'));
    });
  });

  group('jsonSchemaToGbnf', () {
    // Test 15: Produces valid GBNF string containing "root ::="
    test('produces GBNF string starting with root ::=', () {
      final schema = buildQuestionJsonSchema();
      final gbnf = jsonSchemaToGbnf(schema);
      expect(gbnf, isA<String>());
      expect(gbnf, contains('root ::='));
    });

    test('GBNF output contains rules for title', () {
      final schema = buildQuestionJsonSchema();
      final gbnf = jsonSchemaToGbnf(schema);
      expect(gbnf, contains('title'));
    });

    test('GBNF output contains rules for type', () {
      final schema = buildQuestionJsonSchema();
      final gbnf = jsonSchemaToGbnf(schema);
      expect(gbnf, contains('type'));
    });

    test('GBNF output contains rules for options', () {
      final schema = buildQuestionJsonSchema();
      final gbnf = jsonSchemaToGbnf(schema);
      expect(gbnf, contains('options'));
    });

    test('GBNF output contains rules for answer', () {
      final schema = buildQuestionJsonSchema();
      final gbnf = jsonSchemaToGbnf(schema);
      expect(gbnf, contains('answer'));
    });

    test('GBNF output contains rules for explanation', () {
      final schema = buildQuestionJsonSchema();
      final gbnf = jsonSchemaToGbnf(schema);
      expect(gbnf, contains('explanation'));
    });
  });
}
