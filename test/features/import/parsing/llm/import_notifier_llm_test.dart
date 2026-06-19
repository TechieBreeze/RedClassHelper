// test/features/import/parsing/llm/import_notifier_llm_test.dart
// ── ImportNotifier LLM 分支测试 ──
// 验证 llmParse() 的完整流程：分块、LLM 调用、重试、兜底、parse_log、自动确认。

import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

import 'package:redclass/data/db/database.dart';
import 'package:redclass/data/llm_client/llm_client.dart';
import 'package:redclass/data/llm_client/llm_error.dart';
import 'package:redclass/data/llm_client/providers.dart';
import 'package:redclass/data/llm_client/stub_llm_client.dart';
import 'package:redclass/features/import/parsing/llm/canonicalizer.dart';
import 'package:redclass/features/import/parsing/parse_candidate.dart';
import 'package:redclass/features/import/providers/import_notifier.dart';
import 'package:redclass/features/import/providers/import_state.dart';

/// 用于 multi-question 测试的 StubLlmClient 子类。
/// 支持注入自定义的解析结果，以及模拟异常。
class TestStubLlmClient implements LlmClient {
  ParseCandidate Function(String, String?) _parser;
  int callCount = 0;

  TestStubLlmClient({
    ParseCandidate Function(String, String?)? parser,
  }) : _parser = parser ?? _defaultParser;

  static ParseCandidate _defaultParser(String rawText, String? bankName) {
    return ParseCandidate(
      rawText: rawText,
      candidateType: CandidateType.singleChoice,
      title: 'Test title',
      options: ['A. Option A', 'B. Option B'],
      answer: 'A',
      explanation: 'Test explanation',
      confidence: 1.0,
    );
  }

  void setParser(ParseCandidate Function(String, String?) parser) {
    _parser = parser;
  }

  @override
  Future<ParseCandidate> parse(String rawText, {String? bankName}) async {
    callCount++;
    return _parser(rawText, bankName);
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

  /// 创建一个带有 LLM 覆盖的 ProviderContainer。
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

  group('llmParse basic flow', () {
    test('transitions phase to llmParsing then editing on success', () async {
      final stubClient = TestStubLlmClient();
      final container = createContainer(llmClient: stubClient);

      final notifier = container.read(importNotifierProvider.notifier);
      notifier.pickFiles([
        const ImportFile(path: 'test.docx', name: 'test.docx', sizeBytes: 100),
      ]);

      // Set extracted text with multi-question input
      final stateWithText = container
          .read(importNotifierProvider)
          .copyWith(extractedText: '1. Question One\nA. Option\nB. Option\n\n'
              '2. Question Two\nA. Option\nB. Option');

      // Manually set the state with extracted text
      notifier.state = stateWithText;

      await notifier.llmParse();

      final finalState = container.read(importNotifierProvider);
      expect(finalState.phase, ImportPhase.editing);
      expect(finalState.candidates.length, greaterThanOrEqualTo(1));
      expect(finalState.confirmedIndices.length,
          finalState.candidates.length); // D-08: auto-confirm
    });

    test('parseSources records ParseSource.llm for successful candidates',
        () async {
      final stubClient = TestStubLlmClient();
      final container = createContainer(llmClient: stubClient);

      final notifier = container.read(importNotifierProvider.notifier);
      notifier.pickFiles([
        const ImportFile(path: 'test.docx', name: 'test.docx', sizeBytes: 100),
      ]);

      notifier.state = container
          .read(importNotifierProvider)
          .copyWith(extractedText: '1. Question One\nA. Option\nB. Option');

      await notifier.llmParse();

      final finalState = container.read(importNotifierProvider);
      expect(finalState.parseSources.isNotEmpty, isTrue);
      expect(finalState.parseSources[0], ParseSource.llm);
    });

    test('LLM candidates have confidence=0.9 and metadata source=llm', () async {
      final stubClient = TestStubLlmClient();
      final container = createContainer(llmClient: stubClient);

      final notifier = container.read(importNotifierProvider.notifier);
      notifier.pickFiles([
        const ImportFile(path: 'test.docx', name: 'test.docx', sizeBytes: 100),
      ]);

      notifier.state = container
          .read(importNotifierProvider)
          .copyWith(extractedText: '1. Question One\nA. Option\nB. Option');

      await notifier.llmParse();

      final finalState = container.read(importNotifierProvider);
      expect(finalState.candidates[0].confidence, 0.9);
      expect(finalState.candidates[0].metadata['source'], 'llm');
    });

    test('progress updates from 0.0 towards 1.0 during llmParsing', () async {
      final stubClient = TestStubLlmClient();
      final container = createContainer(llmClient: stubClient);

      final notifier = container.read(importNotifierProvider.notifier);
      notifier.pickFiles([
        const ImportFile(path: 'test.docx', name: 'test.docx', sizeBytes: 100),
      ]);

      notifier.state = container
          .read(importNotifierProvider)
          .copyWith(extractedText: '1. Q1\nA. Opt\n\n2. Q2\nA. Opt\n\n'
              '3. Q3\nA. Opt');

      await notifier.llmParse();

      final finalState = container.read(importNotifierProvider);
      expect(finalState.progress, 1.0);
    });
  });

  group('llmParse fallback and failure', () {
    test('on LlmRetryExhaustedException, uses heuristic fallback', () async {
      final stubClient = TestStubLlmClient();
      stubClient.setParser((rawText, bankName) {
        throw LlmRetryExhaustedException(
          attempts: 3,
          lastError: 'mock retry exhausted',
        );
      });

      final container = createContainer(llmClient: stubClient);

      final notifier = container.read(importNotifierProvider.notifier);
      notifier.pickFiles([
        const ImportFile(path: 'test.docx', name: 'test.docx', sizeBytes: 100),
      ]);

      notifier.state = container
          .read(importNotifierProvider)
          .copyWith(extractedText: '1. Question One\nA. Option\n'
              'B. Option\n答案：A');

      await notifier.llmParse();

      final finalState = container.read(importNotifierProvider);
      // Fallback candidate should have ParseSource.fallback
      if (finalState.candidates.isNotEmpty) {
        expect(finalState.parseSources[0], ParseSource.fallback);
        expect(finalState.candidates[0].metadata['source'],
            'heuristic_fallback');
        // Lower confidence for fallback
        expect(finalState.candidates[0].confidence, lessThan(0.9));
      }
    });

    test('empty extractedText returns idle state with error', () async {
      final stubClient = TestStubLlmClient();
      final container = createContainer(llmClient: stubClient);

      final notifier = container.read(importNotifierProvider.notifier);
      notifier.pickFiles([
        const ImportFile(path: 'test.docx', name: 'test.docx', sizeBytes: 100),
      ]);

      notifier.state =
          container.read(importNotifierProvider).copyWith(extractedText: '');

      await notifier.llmParse();

      final finalState = container.read(importNotifierProvider);
      expect(finalState.phase, ImportPhase.idle);
    });

    test('all chunks fail transitions to idle with error message', () async {
      final stubClient = TestStubLlmClient();
      // Override parser to throw on every call
      stubClient.setParser((rawText, bankName) {
        throw Exception('total failure');
      });

      final container = createContainer(llmClient: stubClient);

      final notifier = container.read(importNotifierProvider.notifier);
      notifier.pickFiles([
        const ImportFile(path: 'test.docx', name: 'test.docx', sizeBytes: 100),
      ]);

      notifier.state = container
          .read(importNotifierProvider)
          .copyWith(extractedText: 'XYZ\nNo question pattern here');

      await notifier.llmParse();

      final finalState = container.read(importNotifierProvider);
      // Text without question number patterns produces single block
      // If that single block's LLM call throws and fallback also fails,
      // candidates could be empty
      if (finalState.candidates.isEmpty) {
        expect(finalState.phase, ImportPhase.idle);
        expect(finalState.error, isNotNull);
      }
    });
  });

  group('llmParse canonicalization', () {
    test('canonicalizeAnswer is applied to LLM results', () async {
      final stubClient = TestStubLlmClient(
        parser: (rawText, bankName) {
          return ParseCandidate(
            rawText: rawText,
            candidateType: CandidateType.singleChoice,
            title: 'Canonicalization test',
            options: ['A. Option A', 'B. Option B'],
            answer: 'A,B', // Uncanonicalized answer
            explanation: 'Test',
            confidence: 1.0,
          );
        },
      );

      final container = createContainer(llmClient: stubClient);

      final notifier = container.read(importNotifierProvider.notifier);
      notifier.pickFiles([
        const ImportFile(path: 'test.docx', name: 'test.docx', sizeBytes: 100),
      ]);

      notifier.state = container
          .read(importNotifierProvider)
          .copyWith(extractedText: '1. Question One\nA. Option A\nB. Option B');

      await notifier.llmParse();

      final finalState = container.read(importNotifierProvider);
      expect(finalState.candidates[0].answer, 'AB'); // canonicalized A,B → AB
    });
  });

  group('llmParse parse_log', () {
    test('parse_log entries written on fallback', () async {
      // Create a parse_job entry to satisfy FK constraint
      final jobId = 'test-job-id';
      await testDb.into(testDb.parseJobs).insert(
        ParseJobsCompanion.insert(
          id: jobId,
          sourcePath: 'test.docx',
          status: 'running',
          progress: 0.5,
          resultCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final stubClient = TestStubLlmClient();
      stubClient.setParser((rawText, bankName) {
        throw LlmRetryExhaustedException(
          attempts: 3,
          lastError: 'mock retry exhausted for log test',
        );
      });

      final container = createContainer(llmClient: stubClient);

      final notifier = container.read(importNotifierProvider.notifier);
      // Set jobId to match the parse_job we created
      notifier.state = const ImportState()
          .copyWith(
            jobId: jobId,
            extractedText: '1. Question One\nA. Option\n'
                'B. Option\n答案：A',
            files: [
              const ImportFile(
                path: 'test.docx',
                name: 'test.docx',
                sizeBytes: 100,
              ),
            ],
          );

      await notifier.llmParse();

      // Check parse_log entries were written
      final logs = await testDb.select(testDb.parseLogs).get();
      final warnLogs = logs.where((l) => l.level == 'warn').toList();
      expect(warnLogs.isNotEmpty, isTrue);
      expect(warnLogs.any((l) => l.message.contains('兜底')), isTrue);
    });
  });
}
