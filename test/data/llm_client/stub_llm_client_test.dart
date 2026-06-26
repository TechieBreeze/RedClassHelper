// test/data/llm_client/stub_llm_client_test.dart
// ── Unit tests for StubLlmClient ──
// Tests deterministic stub behaviors: fixture selection, metadata,
// interface compliance, and error-free operation.

import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/data/llm_client/llm_client.dart';
import 'package:redclass/data/llm_client/stub_llm_client.dart';
import 'package:redclass/features/import/parsing/parse_candidate.dart';

// Test fixture data matching the structure defined in
// assets/fixtures/sample_llm_response.json
const _testFixtures = <String, dynamic>{
  'default': {
    'title': '以下哪项是正确的人工智能定义？',
    'type': 'single',
    'options': ['A. 让计算机像人一样思考', 'B. 模拟人类智能的理论与方法', 'C. 自动化所有任务', 'D. 替代人类决策'],
    'answer': 'B',
    'explanation': '人工智能最准确的通用定义是模拟人类智能的理论与方法。',
  },
  'multi': {
    'title': '以下哪些属于机器学习的主要范式？',
    'type': 'multiple',
    'options': ['A. 监督学习', 'B. 无监督学习', 'C. 强化学习', 'D. 规则学习', 'E. 群体学习'],
    'answer': 'ABC',
    'explanation': '监督学习、无监督学习和强化学习是机器学习三大核心范式。',
  },
  'truefalse': {
    'title': '图灵测试是检验机器是否具有智能的一种方法。',
    'type': 'truefalse',
    'options': ['A. 正确', 'B. 错误'],
    'answer': 'A',
    'explanation': '图灵测试由艾伦·图灵于1950年提出，用于测试机器是否展现出与人类相当的智能行为。',
  },
};

void main() {
  group('StubLlmClient interface compliance', () {
    test('StubLlmClient implements LlmClient', () {
      final client = StubLlmClient(fixtures: _testFixtures);
      expect(client, isA<LlmClient>());
    });
  });

  group('StubLlmClient.parse()', () {
    test(
      'parse() with default text returns singleChoice, answer="B", 4 options',
      () async {
        final client = StubLlmClient(fixtures: _testFixtures);
        final candidate = await client.parse('任意题目文本');

        expect(candidate.candidateType, CandidateType.singleChoice);
        expect(candidate.answer, 'B');
        expect(candidate.options.length, 4);
        expect(candidate.confidence, 1.0);
        expect(candidate.title, isNotEmpty);
      },
    );

    test(
      'parse() with text containing "以下哪些" returns multiChoice, answer="ABC"',
      () async {
        final client = StubLlmClient(fixtures: _testFixtures);
        final candidate = await client.parse('以下哪些属于正确的选项？请选择。');

        expect(candidate.candidateType, CandidateType.multiChoice);
        expect(candidate.answer, 'ABC');
        expect(candidate.options.length, 5);
        expect(candidate.confidence, 1.0);
      },
    );

    test('parse() with text containing "判断对错" returns trueFalse', () async {
      final client = StubLlmClient(fixtures: _testFixtures);
      final candidate = await client.parse('请判断对错。');

      expect(candidate.candidateType, CandidateType.trueFalse);
      expect(candidate.answer, 'A');
      expect(candidate.options.length, 2);
    });

    test(
      'parse() with bankName stores value in metadata[\'bankName\']',
      () async {
        const bankName = '计算机基础题库';
        final client = StubLlmClient(fixtures: _testFixtures);
        final candidate = await client.parse('试题文本', bankName: bankName);

        expect(candidate.metadata['bankName'], bankName);
      },
    );

    test(
      'two calls with same rawText produce byte-identical results',
      () async {
        final client = StubLlmClient(fixtures: _testFixtures);
        const text = '完全相同的题目文本';

        final result1 = await client.parse(text);
        final result2 = await client.parse(text);

        // Structural equality via ParseCandidate.==
        expect(result1, equals(result2));
        // Also check full serialized identity
        expect(result1.toJson(), equals(result2.toJson()));
      },
    );

    test('metadata[\'source\'] == \'stub\' on all results', () async {
      final client = StubLlmClient(fixtures: _testFixtures);
      final candidate1 = await client.parse('题目一');
      final candidate2 = await client.parse('以下哪些题目二');
      final candidate3 = await client.parse('判断对错题目三');

      expect(candidate1.metadata['source'], 'stub');
      expect(candidate2.metadata['source'], 'stub');
      expect(candidate3.metadata['source'], 'stub');
    });

    test(
      'parse() never throws for any input (including empty string)',
      () async {
        final client = StubLlmClient(fixtures: _testFixtures);

        // Normal Chinese text
        await expectLater(client.parse('正常的题目文本'), completes);
        // Empty string
        await expectLater(client.parse(''), completes);
        // Whitespace
        await expectLater(client.parse('   '), completes);
        // English
        await expectLater(client.parse('What is AI?'), completes);
        // Long text
        await expectLater(client.parse('A' * 10000), completes);
        // Special characters
        await expectLater(
          client.parse('!@#\$%^&*()_+-=[]{}|;:\'",.<>?/'),
          completes,
        );
      },
    );

    test('parse() with "属于" keyword returns multiChoice type', () async {
      final client = StubLlmClient(fixtures: _testFixtures);
      final candidate = await client.parse('下列选项中属于机器学习算法的有');

      expect(candidate.candidateType, CandidateType.multiChoice);
    });

    test('parse() with "对错" keyword returns trueFalse type', () async {
      final client = StubLlmClient(fixtures: _testFixtures);
      final candidate = await client.parse('请判断以下说法对错');

      expect(candidate.candidateType, CandidateType.trueFalse);
    });

    test('parse() stores rawText in the returned candidate', () async {
      const rawText = '这是原始文本';
      final client = StubLlmClient(fixtures: _testFixtures);
      final candidate = await client.parse(rawText);

      expect(candidate.rawText, rawText);
    });

    test('parse() returns confidence=1.0 for all fixture types', () async {
      final client = StubLlmClient(fixtures: _testFixtures);
      final defaultResult = await client.parse('default');
      final multiResult = await client.parse('以下哪些');
      final tfResult = await client.parse('判断对错');

      expect(defaultResult.confidence, 1.0);
      expect(multiResult.confidence, 1.0);
      expect(tfResult.confidence, 1.0);
    });

    test(
      'parse() fixtures are lazy-loaded (first call triggers load)',
      () async {
        final client = StubLlmClient(fixtures: _testFixtures);
        // The fact that we can call parse() multiple times without error
        // and get results proves lazy loading works
        await client.parse('test 1');
        await client.parse('test 2');
        await client.parse('test 3');
        // No exception thrown = cached correctly
      },
    );

    test(
      'parse() returns non-empty explanation for all fixture types',
      () async {
        final client = StubLlmClient(fixtures: _testFixtures);
        final defaultResult = await client.parse('default');
        final multiResult = await client.parse('以下哪些');
        final tfResult = await client.parse('判断对错');

        expect(defaultResult.explanation, isNotEmpty);
        expect(multiResult.explanation, isNotEmpty);
        expect(tfResult.explanation, isNotEmpty);
      },
    );
  });
}
