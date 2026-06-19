// lib/features/import/providers/import_state.dart
// ── 导入管道状态模型 ──
// 表示导入管道从文件选择到持久化的完整生命周期。

import '../../import/parsing/parse_candidate.dart';

/// 导入管道阶段
enum ImportPhase {
  /// 未开始——等待用户选择文件
  idle,

  /// 文件选择器/拖放中
  picking,

  /// 正在提取文本（可能耗时较长）
  extracting,

  /// 正在解析候选题目
  parsing,

  /// 等待用户审核/编辑
  editing,

  /// 正在写入数据库
  committing,

  /// 导入完成
  done,
}

/// 单个导入文件信息
class ImportFile {
  final String path;
  final String name;
  final int sizeBytes;

  const ImportFile({
    required this.path,
    required this.name,
    required this.sizeBytes,
  });
}

/// 导入管道状态
class ImportState {
  /// 当前解析任务 ID（用于路由参数和日志关联）
  final String jobId;

  /// 当前阶段
  final ImportPhase phase;

  /// 选中的文件列表
  final List<ImportFile> files;

  /// 提取后的原始文本
  final String extractedText;

  /// 解析出的候选题目
  final List<ParseCandidate> candidates;

  /// 已确认（用户未删除）的候选索引
  final Set<int> confirmedIndices;

  /// 进度 0.0–1.0
  final double progress;

  /// 错误信息
  final String? error;

  /// 最终存入 DB 的题目数量
  final int committedCount;

  /// 题库名称（从文件名推导）
  final String bankName;

  const ImportState({
    this.jobId = '',
    this.phase = ImportPhase.idle,
    this.files = const [],
    this.extractedText = '',
    this.candidates = const [],
    this.confirmedIndices = const {},
    this.progress = 0.0,
    this.error,
    this.committedCount = 0,
    this.bankName = '',
  });

  /// 便捷检查器
  bool get isIdle => phase == ImportPhase.idle;
  bool get isExtracting => phase == ImportPhase.extracting;
  bool get isParsing => phase == ImportPhase.parsing;
  bool get isEditing => phase == ImportPhase.editing;
  bool get isCommitting => phase == ImportPhase.committing;
  bool get isDone => phase == ImportPhase.done;
  bool get hasError => error != null;

  /// 有候选可供审核
  bool get hasCandidates => candidates.isNotEmpty;

  /// 未被用户确认的候选题目（即跳过项），带跳过原因。
  List<({int index, ParseCandidate candidate, String reason})>
      get skippedCandidates {
    return candidates.asMap().entries
        .where((e) => !confirmedIndices.contains(e.key))
        .map((e) {
          final c = e.value;
          final reason = _deriveSkipReason(c);
          return (index: e.key, candidate: c, reason: reason);
        })
        .toList();
  }

  /// 推导跳过原因
  String _deriveSkipReason(ParseCandidate c) {
    if (c.confidence < 0.3) return '置信度过低';
    if (c.candidateType == CandidateType.unknown) return '题型未识别';
    if (c.title.isEmpty && c.options.isEmpty) return '题干和选项均缺失';
    if (c.options.length < 2) return '选项不足（少于2个）';
    if (c.answer.isEmpty) return '答案未识别';
    return '用户跳过';
  }

  ImportState copyWith({
    String? jobId,
    ImportPhase? phase,
    List<ImportFile>? files,
    String? extractedText,
    List<ParseCandidate>? candidates,
    Set<int>? confirmedIndices,
    double? progress,
    String? error,
    int? committedCount,
    String? bankName,
    bool clearError = false,
  }) {
    return ImportState(
      jobId: jobId ?? this.jobId,
      phase: phase ?? this.phase,
      files: files ?? this.files,
      extractedText: extractedText ?? this.extractedText,
      candidates: candidates ?? this.candidates,
      confirmedIndices: confirmedIndices ?? this.confirmedIndices,
      progress: progress ?? this.progress,
      error: clearError ? null : (error ?? this.error),
      committedCount: committedCount ?? this.committedCount,
      bankName: bankName ?? this.bankName,
    );
  }
}
