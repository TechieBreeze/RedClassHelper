// lib/features/import/providers/import_notifier.dart
// ── 导入管道 Notifier ──
// 管理 idle → picking → extracting → parsing → editing → committing → done 全流程。

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/paths.dart';
import '../../../data/db/database.dart';
import '../../import/extraction/text_extractor.dart';
import '../../import/parsing/heuristic_parser.dart';
import '../../import/parsing/parse_candidate.dart';
import 'import_state.dart';

part 'import_notifier.g.dart';

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

  /// 重置管道
  void reset() {
    state = const ImportState();
  }

  // ── 辅助方法 ──

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
