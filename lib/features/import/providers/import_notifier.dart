// lib/features/import/providers/import_notifier.dart
// ── 导入管道 Notifier ──
// 管理 idle → picking → extracting → parsing → editing → committing → done 全流程。

import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/paths.dart';
import '../../../data/db/database.dart';
import '../../../data/llm_client/llm_client.dart';
import '../../../data/llm_client/llm_error.dart';
import '../../../data/llm_client/providers.dart';
import '../../import/extraction/text_extractor.dart';
import '../../import/parsing/heuristic_parser.dart';
import '../../import/parsing/llm/canonicalizer.dart';
import '../../import/parsing/llm/chunker.dart';
import '../../import/parsing/parse_candidate.dart';
import 'import_state.dart';

part 'import_notifier.g.dart';

/// Backward-compatible alias — generated provider is `importProvider`
/// (Riverpod 4.x strips `Notifier` suffix), but all existing screen code
/// references `importNotifierProvider`.
// ignore: non_constant_identifier_names
final importNotifierProvider = importProvider;

/// 导入管道 Notifier。
///
/// 通过 Riverpod 管理导入全流程状态，依赖 PathResolver 和 AppDatabase。
@riverpod
class ImportNotifier extends _$ImportNotifier {
  final HeuristicParser _parser = HeuristicParser();
  final Uuid _uuid = const Uuid();

  @override
  ImportState build() => const ImportState();

  /// 阶段 0 → 1: 选择文件
  void pickFiles(List<ImportFile> files) {
    if (files.isEmpty) return;

    final bankName = _deriveBankName(files.first.name);
    state = state.copyWith(
      jobId: _uuid.v4(),
      phase: ImportPhase.picking,
      files: files,
      bankName: bankName,
      clearError: true,
    );
  }

  /// 阶段 1 → 2 → 3: 提取文本并解析
  Future<void> extractAndParse() async {
    if (state.files.isEmpty) return;

    // 提取阶段
    state = state.copyWith(
      phase: ImportPhase.extracting,
      progress: 0.0,
      clearError: true,
    );

    final resolver = await ref.read(pathResolverProvider.future);
    // Guard: provider may have been disposed during the await.
    if (state.phase != ImportPhase.extracting) return;

    final allText = StringBuffer();
    final totalFiles = state.files.length;

    for (var i = 0; i < totalFiles; i++) {
      final file = state.files[i];
      try {
        state = state.copyWith(
          progress: (i / totalFiles) * 0.5,
        );

        final ext = p.extension(file.path);
        final text = await extractText(
          file.path,
          fileExtension: ext,
          pandocResolver: () => resolver.pandoc,
          tempImportDirResolver: () => resolver.tempImportDir,
        );

        allText.writeln(text);
        allText.writeln(); // 文件分隔

        // Guard: provider may have been disposed during extractText await.
        if (state.phase != ImportPhase.extracting) return;
      } on PandocNotFoundException catch (e) {
        state = state.copyWith(
          phase: ImportPhase.idle,
          error: e.message,
        );
        return;
      } on Exception catch (e) {
        state = state.copyWith(
          phase: ImportPhase.idle,
          error: '文本提取失败: ${e.toString()}',
        );
        return;
      }
    }

    state = state.copyWith(
      extractedText: allText.toString().trim(),
      progress: 0.6,
    );

    // 解析阶段
    state = state.copyWith(phase: ImportPhase.parsing);

    final candidates = _parser.parse(
      allText.toString(),
      bankName: state.bankName,
    );

    if (candidates.isEmpty) {
      state = state.copyWith(
        phase: ImportPhase.idle,
        error: '未能从文件中识别到题目。请检查文件格式或尝试手动创建题库',
      );
      return;
    }

    state = state.copyWith(
      phase: ImportPhase.editing,
      candidates: candidates,
      confirmedIndices: List.generate(candidates.length, (i) => i).toSet(),
      progress: 1.0,
    );
  }

  /// 编辑阶段操作：切换候选确认状态
  void toggleCandidate(int index) {
    final confirmed = Set<int>.from(state.confirmedIndices);
    if (confirmed.contains(index)) {
      confirmed.remove(index);
    } else {
      confirmed.add(index);
    }
    state = state.copyWith(confirmedIndices: confirmed);
  }

  /// 编辑阶段操作：手动设置候选题型
  void setCandidateType(int index, CandidateType type) {
    final candidates = List<ParseCandidate>.from(state.candidates);
    if (index >= 0 && index < candidates.length) {
      final old = candidates[index];
      candidates[index] = old.copyWith(candidateType: type);
      state = state.copyWith(candidates: candidates);
    }
  }

  /// 编辑阶段操作：手动编辑选项
  void setCandidateOptions(int index, List<String> options) {
    final candidates = List<ParseCandidate>.from(state.candidates);
    if (index >= 0 && index < candidates.length) {
      final old = candidates[index];
      candidates[index] = old.copyWith(options: options);
      state = state.copyWith(candidates: candidates);
    }
  }

  /// 编辑阶段操作：手动编辑答案
  void setCandidateAnswer(int index, String answer) {
    final candidates = List<ParseCandidate>.from(state.candidates);
    if (index >= 0 && index < candidates.length) {
      final old = candidates[index];
      candidates[index] = old.copyWith(answer: answer);
      state = state.copyWith(candidates: candidates);
    }
  }

  /// 阶段 4 → 5 → 6: 提交到数据库
  Future<void> commitToDatabase() async {
    if (!state.isEditing || state.confirmedIndices.isEmpty) return;

    state = state.copyWith(
      phase: ImportPhase.committing,
      progress: 0.0,
    );

    try {
      final db = await ref.read(appDatabaseProvider.future);
      final bankId = _uuid.v4();
      final now = DateTime.now();
      final confirmedCandidates = state.confirmedIndices
          .where((i) => i < state.candidates.length)
          .map((i) => state.candidates[i])
          .toList();

      // 创建 ParseJob
      final job = ParseJobsCompanion.insert(
        id: _uuid.v4(),
        sourcePath: state.files.map((f) => f.path).join(';'),
        status: 'succeeded',
        progress: 1.0,
        resultCount: confirmedCandidates.length,
        createdAt: now,
        updatedAt: now,
      );
      await db.into(db.parseJobs).insert(job);

      // 创建 QuestionBank
      final bank = QuestionBanksCompanion.insert(
        id: bankId,
        name: state.bankName,
        source: state.files.first.path,
        questionCount: confirmedCandidates.length,
        createdAt: now,
        updatedAt: now,
      );
      await db.into(db.questionBanks).insert(bank);

      state = state.copyWith(progress: 0.3);

      // 逐个插入 Question
      for (var i = 0; i < confirmedCandidates.length; i++) {
        final c = confirmedCandidates[i];
        final question = QuestionsCompanion.insert(
          id: _uuid.v4(),
          bankId: bankId,
          type: _toDbType(c.candidateType),
          stem: c.title.isNotEmpty ? c.title : c.rawText,
          optionsJson: _optionsToJson(c.options),
          correctJson: _answerToJson(c.answer),
          rawText: c.rawText,
          createdAt: now,
        );
        await db.into(db.questions).insert(question);

        state = state.copyWith(
          progress: 0.3 + 0.7 * ((i + 1) / confirmedCandidates.length),
        );
      }

      state = state.copyWith(
        phase: ImportPhase.done,
        committedCount: confirmedCandidates.length,
        progress: 1.0,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        phase: ImportPhase.editing,
        error: '保存失败: ${e.toString()}',
      );
    }
  }

  /// 设置题库名称（用户在预览页编辑时调用）
  void setBankName(String name) {
    state = state.copyWith(bankName: name);
  }

  /// 重新解析单个候选题目（摘要页"重试"按钮触发）
  void retryParseCandidate(int index) {
    if (index < 0 || index >= state.candidates.length) return;

    final rawText = state.candidates[index].rawText;
    final reparsed = _parser.parse(rawText, bankName: state.bankName);

    final candidates = List<ParseCandidate>.from(state.candidates);
    if (reparsed.isNotEmpty) {
      // 保留原始行号信息
      candidates[index] = reparsed.first.copyWith(
        startLine: candidates[index].startLine,
        endLine: candidates[index].endLine,
      );
    }
    // 无论重解析成功与否，都加入确认集
    final confirmed = Set<int>.from(state.confirmedIndices);
    confirmed.add(index);
    state = state.copyWith(candidates: candidates, confirmedIndices: confirmed);
  }

  /// LLM 解析分支：分块 → 逐题 LLM 调用 → 自动确认（D-07, D-08, D-09）。
  ///
  /// 流程：
  /// 1. 调用 [splitIntoQuestionBlocks] 将提取出的文本按题号分块。
  /// 2. 逐块调用 [LlmClient.parse]，每次带 3 次重试。
  /// 3. LLM 成功：规范化答案，记录 [ParseSource.llm]，自动确认。
  /// 4. LLM 失败：回退到启发式解析，记录 [ParseSource.fallback]。
  /// 5. 失败事件写入 [ParseLogs] 表。
  /// 6. 全部成功后进入编辑阶段，所有候选自动确认。
  Future<void> llmParse() async {
    if (state.extractedText.isEmpty) {
      state = state.copyWith(
        phase: ImportPhase.idle,
        error: '没有可解析的文本内容',
      );
      return;
    }

    state = state.copyWith(
      phase: ImportPhase.llmParsing,
      progress: 0.0,
      clearError: true,
    );

    final blocks = splitIntoQuestionBlocks(state.extractedText);
    if (blocks.isEmpty) {
      state = state.copyWith(
        phase: ImportPhase.idle,
        error: '未能将文本拆分为题目块',
      );
      return;
    }

    final candidates = <ParseCandidate>[];
    final sources = <int, ParseSource>{};
    final db = await ref.read(appDatabaseProvider.future);
    // Guard: provider may have been disposed during the await.
    if (state.phase != ImportPhase.llmParsing) return;

    for (var i = 0; i < blocks.length; i++) {
      state = state.copyWith(
        progress: (i / blocks.length) * 0.95,
        parseStatus: '正在解析第 ${i + 1} 题…',
      );

      ParseCandidate? candidate;
      ParseSource source;

      try {
        // 带内置重试的 LLM 解析（HttpLlmClient 内部最多 3 次重试）
        final llmResult = await ref.read(llmClientProvider).parse(
          blocks[i],
          bankName: state.bankName,
        );
        // 答案规范化（PITFALL 1: LLM 可能输出多种格式）
        final canonicalAnswer =
            formatAnswerForDisplay(canonicalizeAnswer(llmResult.answer));
        candidate = llmResult.copyWith(
          answer: canonicalAnswer,
          metadata: {
            ...llmResult.metadata,
            'source': 'llm',
            'chunkIndex': i.toString(),
          },
          confidence: 0.9,
        );
        source = ParseSource.llm;
      } on LlmRetryExhaustedException catch (e) {
        // D-09: 3 次重试耗尽 → 该题回退启发式兜底
        source = ParseSource.fallback;
        candidate = _fallbackParseSingle(blocks[i], i);

        state = state.copyWith(
          parseStatus: '第 ${i + 1} 题切换启发式兜底…',
        );

        // 写入 parse_log（D-09: 失败记录可在汇总页展示）
        await _logParseEvent(
          db: db,
          jobId: state.jobId,
          level: 'warn',
          message: '第 ${i + 1} 题 LLM 失败，切换启发式兜底',
          context: {
            'attempts': e.attempts,
            'lastError': e.lastError,
            'chunkIndex': i,
          },
        );
      } on Exception catch (e) {
        // 意外错误 → 回退启发式兜底
        source = ParseSource.fallback;
        candidate = _fallbackParseSingle(blocks[i], i);

        state = state.copyWith(
          parseStatus: '第 ${i + 1} 题切换启发式兜底…',
        );

        await _logParseEvent(
          db: db,
          jobId: state.jobId,
          level: 'error',
          message: '第 ${i + 1} 题 LLM 异常: ${e.toString()}',
          context: {'error': e.toString(), 'chunkIndex': i},
        );
      }

      if (candidate != null) {
        candidates.add(candidate);
        sources[candidates.length - 1] = source;
      }
    }

    if (candidates.isEmpty) {
      // 全部分块失败 → 回退到空闲状态并给出明确错误
      state = state.copyWith(
        phase: ImportPhase.idle,
        error: 'LLM 解析全部失败，请使用快速解析（启发式）重试',
        progress: 1.0,
      );
      return;
    }

    // D-08: LLM 结果自动确认（所有候选加入 confirmedIndices）
    state = state.copyWith(
      phase: ImportPhase.editing,
      candidates: candidates,
      confirmedIndices: List.generate(candidates.length, (i) => i).toSet(),
      parseSources: sources,
      progress: 1.0,
    );
  }

  /// 重置管道
  void reset() {
    state = const ImportState();
  }

  // ── LLM 解析辅助方法 ──

  /// 单题启发式兜底解析（LLM 失败时调用）。
  ///
  /// 使用 [HeuristicParser] 对单个题目块进行解析，
  /// 置信度在原始基础上降低 20%（乘以 0.8），并标记来源为 'heuristic_fallback'。
  ParseCandidate? _fallbackParseSingle(String block, int chunkIndex) {
    final parsed = _parser.parse(block, bankName: state.bankName);
    if (parsed.isNotEmpty) {
      return parsed.first.copyWith(
        metadata: {
          ...parsed.first.metadata,
          'source': 'heuristic_fallback',
          'chunkIndex': chunkIndex.toString(),
        },
        confidence:
            (parsed.first.confidence * 0.8).clamp(0.0, 1.0),
      );
    }
    return null;
  }

  /// 向 [ParseLogs] 表写入一条解析事件。
  ///
  /// 日志写入是"尽力而为"的操作——即使写入失败也不应中断导入流程。
  Future<void> _logParseEvent({
    required AppDatabase db,
    required String jobId,
    required String level,
    required String message,
    required Map<String, dynamic> context,
  }) async {
    try {
      await db.into(db.parseLogs).insert(
        ParseLogsCompanion.insert(
          parseJobId: jobId,
          level: level,
          message: message,
          contextJson: jsonEncode(context),
          createdAt: DateTime.now(),
        ),
      );
    } catch (_) {
      // parse_log 是尽力而为的操作——静默失败不中断导入
    }
  }

  // ── 原有辅助方法 ──

  String _deriveBankName(String fileName) {
    final base = p.basenameWithoutExtension(fileName);
    // 去掉常见后缀
    return base
        .replaceAll(RegExp(r'[（(]?\d{4}年[春夏秋冬]季学期[）)]?'), '')
        .replaceAll(RegExp(r'[（(]?\d{4}年\d{1,2}月\d{1,2}日修订[）)]?'), '')
        .trim();
  }

  String _toDbType(CandidateType type) {
    switch (type) {
      case CandidateType.singleChoice:
      case CandidateType.trueFalse:
        return 'single';
      case CandidateType.multiChoice:
        return 'multiple';
      case CandidateType.shortAnswer:
      case CandidateType.unknown:
        return 'single'; // 默认按单选处理
    }
  }

  String _optionsToJson(List<String> options) {
    final list = <Map<String, String>>[];
    for (var i = 0; i < options.length; i++) {
      final key = String.fromCharCode('A'.codeUnitAt(0) + i);
      // 去掉 "A. " 前缀
      final text = options[i].replaceFirst(RegExp(r'^[A-H][.、．]\s*'), '');
      list.add({'key': key, 'text': text});
    }
    return jsonEncode(list);
  }

  String _answerToJson(String answer) {
    final chars = answer
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-H]'), '')
        .split('');
    return jsonEncode(chars);
  }
}
