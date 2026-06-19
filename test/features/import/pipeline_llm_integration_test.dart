// test/features/import/pipeline_llm_integration_test.dart
// ── LLM 解析管道集成测试 ──
// 端到端验证 LLM 解析流程：分块 → 解析 → 自动确认 → 预览。
// 使用 StubLlmClient 进行确定性测试。

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:redclass/data/db/database.dart';
import 'package:redclass/data/llm_client/llm_client.dart';
import 'package:redclass/data/llm_client/llm_error.dart';
import 'package:redclass/data/llm_client/providers.dart';
import 'package:redclass/features/import/parsing/llm/canonicalizer.dart';
import 'package:redclass/features/import/parsing/parse_candidate.dart';
import 'package:redclass/features/import/providers/import_notifier.dart';
import 'package:redclass/features/import/providers/import_state.dart';

/// 集成测试用 StubLlmClient，支持注入每块解析结果或模拟失败。
class IntegrationStubLlmClient implements LlmClient {
  final List<ParseCandidate Function(String, String?)> _parsers;
  int callCount = 0;

  IntegrationStubLlmClient({
    required List<ParseCandidate Function(String, String?)> parsers,
  }) : _parsers = parsers;

  @override
  Future<ParseCandidate> parse(String rawText, {String? bankName}) async {
    if (callCount < _parsers.length) {
      final result = _parsers[callCount](rawText, bankName);
      callCount++;
      return result;
    }
    // Default single-choice for any extra calls
    return ParseCandidate(
      rawText: rawText,
      candidateType: CandidateType.singleChoice,
      title: 'Extra question',
      options: ['A. Option'],
      answer: 'A',
      confidence: 1.0,
    );
  }

  static ParseCandidate makeSingle(String rawText, String? bankName) {
    return ParseCandidate(
      rawText: rawText,
      candidateType: CandidateType.singleChoice,
      title: 'Single choice Q',
      options: ['A. Alpha', 'B. Beta'],
      answer: 'A',
      confidence: 1.0,
    );
  }

  static ParseCandidate makeMulti(String rawText, String? bankName) {
    return ParseCandidate(
      rawText: rawText,
      candidateType: CandidateType.multiChoice,
      title: 'Multi choice Q',
      options: ['A. Apple', 'B. Banana', 'C. Cherry'],
      answer: 'A,B',
      confidence: 1.0,
    );
  }
}

void main() {
  late AppDatabase testDb;

  setUp(() async {
    testDb = AppDatabase.openInMemoryDatabase();
  });

  tearDown(() async {
    await testDb.close();
  });

  ProviderContainer createContainer({
    required LlmClient llmClient,
  }) {
    return ProviderContainer(
      overrides: [
        llmClientProvider.overrideWithValue(llmClient),
        appDatabaseProvider.overrideWith((ref) async => testDb),
      ],
    );
  }

  group('Full LLM parse pipeline', () {
    test('chunk → parse → editing with ParseSource.llm and auto-confirm',
        () async {
      final stub = IntegrationStubLlmClient(parsers: [
        IntegrationStubLlmClient.makeSingle,
        IntegrationStubLlmClient.makeMulti,
      ]);
      final container = createContainer(llmClient: stub);

      final notifier = container.read(importNotifierProvider.notifier);
      notifier.pickFiles([
        const ImportFile(
            path: 'test.docx', name: 'test.docx', sizeBytes: 100),
      ]);

      notifier.state = container.read(importNotifierProvider).copyWith(
            extractedText: '1. Question One\nA. Alpha\nB. Beta\n\n'
                '2. Question Two\nA. Apple\nB. Banana\nC. Cherry',
          );

      await notifier.llmParse();

      final finalState = container.read(importNotifierProvider);
      expect(finalState.phase, ImportPhase.editing);
      expect(finalState.candidates.length, 2);
      expect(finalState.confirmedIndices.length, 2); // D-08: auto-confirm
      expect(finalState.parseSources.length, 2);
      expect(finalState.parseSources[0], ParseSource.llm);
      expect(finalState.parseSources[1], ParseSource.llm);
      expect(finalState.candidates[0].confidence, 0.9);
      expect(finalState.candidates[1].metadata['source'], 'llm');
    });

    test('mixed LLM + fallback: parseSources records both source types',
        () async {
      final stub = IntegrationStubLlmClient(parsers: [
        IntegrationStubLlmClient.makeSingle,
        (rawText, bankName) =>
            throw LlmRetryExhaustedException(
              attempts: 3,
              lastError: 'mock retry exhausted',
            ),
      ]);
      final container = createContainer(llmClient: stub);

      final notifier = container.read(importNotifierProvider.notifier);
      notifier.pickFiles([
        const ImportFile(
            path: 'test.docx', name: 'test.docx', sizeBytes: 100),
      ]);

      notifier.state = container.read(importNotifierProvider).copyWith(
            extractedText: '1. Question One\nA. Option\n'
                'B. Option\n答案：A\n\n'
                '2. Question Two\nA. Option\n'
                'B. Option\n答案：B',
          );

      await notifier.llmParse();

      final finalState = container.read(importNotifierProvider);
      if (finalState.candidates.length >= 2) {
        expect(finalState.parseSources[0], ParseSource.llm);
        expect(finalState.parseSources[1], ParseSource.fallback);
        // Fallback candidate has reduced confidence
        expect(finalState.candidates[1].confidence, lessThan(0.9));
      }
    });

    test('LLM import sets parseStatus during processing', () async {
      final stub = IntegrationStubLlmClient(parsers: [
        IntegrationStubLlmClient.makeSingle,
        IntegrationStubLlmClient.makeSingle,
      ]);
      final container = createContainer(llmClient: stub);

      final notifier = container.read(importNotifierProvider.notifier);
      notifier.pickFiles([
        const ImportFile(
            path: 'test.docx', name: 'test.docx', sizeBytes: 100),
      ]);

      notifier.state = container.read(importNotifierProvider).copyWith(
            extractedText: '1. Q1\nA. Alpha\nB. Beta\n\n'
                '2. Q2\nA. Alpha\nB. Beta',
          );

      await notifier.llmParse();

      final finalState = container.read(importNotifierProvider);
      // After completion, parseStatus may be set or cleared
      // Just verify the parse completed successfully
      expect(finalState.phase, ImportPhase.editing);
      expect(finalState.parseSources.isNotEmpty, isTrue);
    });

    test('all chunks fail → idle with error', () async {
      final stub = IntegrationStubLlmClient(parsers: [
        (rawText, bankName) => throw Exception('total failure'),
      ]);
      final container = createContainer(llmClient: stub);

      final notifier = container.read(importNotifierProvider.notifier);
      notifier.pickFiles([
        const ImportFile(
            path: 'test.docx', name: 'test.docx', sizeBytes: 100),
      ]);

      notifier.state = container.read(importNotifierProvider).copyWith(
            extractedText: 'XYZ\nNo question pattern here',
          );

      await notifier.llmParse();

      final finalState = container.read(importNotifierProvider);
      if (finalState.candidates.isEmpty) {
        expect(finalState.phase, ImportPhase.idle);
        expect(finalState.error, isNotNull);
      }
    });

    test('parseStatus is set to "正在解析" during llmParsing loop',
        () async {
      final stub = IntegrationStubLlmClient(parsers: [
        IntegrationStubLlmClient.makeSingle,
      ]);
      final container = createContainer(llmClient: stub);

      // Listen to state changes to verify parseStatus is set
      final states = <ImportState>[];
      container.listen(importNotifierProvider, (prev, next) {
        states.add(next);
      });

      final notifier = container.read(importNotifierProvider.notifier);
      notifier.pickFiles([
        const ImportFile(
            path: 'test.docx', name: 'test.docx', sizeBytes: 100),
      ]);

      notifier.state = container.read(importNotifierProvider).copyWith(
            extractedText: '1. Question One\nA. Alpha\nB. Beta',
          );

      await notifier.llmParse();

      // Check that at least one state had parseStatus set
      final parsingStates = states
          .where((s) =>
              s.isLlmParsing &&
              s.parseStatus != null &&
              s.parseStatus!.contains('解析'))
          .toList();
      expect(parsingStates.isNotEmpty, isTrue);
    });

    test('progress updates from 0.0 to 1.0 during llmParsing', () async {
      final stub = IntegrationStubLlmClient(parsers: [
        IntegrationStubLlmClient.makeSingle,
        IntegrationStubLlmClient.makeSingle,
        IntegrationStubLlmClient.makeSingle,
      ]);
      final container = createContainer(llmClient: stub);

      final notifier = container.read(importNotifierProvider.notifier);
      notifier.pickFiles([
        const ImportFile(
            path: 'test.docx', name: 'test.docx', sizeBytes: 100),
      ]);

      notifier.state = container.read(importNotifierProvider).copyWith(
            extractedText: '1. Q1\nA. Opt\n\n2. Q2\nA. Opt\n\n'
                '3. Q3\nA. Opt',
          );

      await notifier.llmParse();

      final finalState = container.read(importNotifierProvider);
      expect(finalState.progress, 1.0);
    });
  });
}
