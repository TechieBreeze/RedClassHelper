// lib/features/import/parsing/parse_candidate.dart
// ── 解析候选：解析器输出的统一数据模型 ──
// 纯 Dart 数据类，可被 JSON 序列化以便跨 isolate 传递。

import 'package:json_annotation/json_annotation.dart';

part 'parse_candidate.g.dart';

/// 题型枚举（映射到 QuestionTable.questionType）。
enum CandidateType {
  @JsonValue('single_choice')
  singleChoice,

  @JsonValue('multi_choice')
  multiChoice,

  @JsonValue('true_false')
  trueFalse,

  @JsonValue('short_answer')
  shortAnswer,

  @JsonValue('unknown')
  unknown,
}

/// 解析器输出的单个题目候选。
///
/// 由 [HeuristicParser] 生成，传递给 ImportPreviewScreen 供用户审核。
@JsonSerializable()
class ParseCandidate {
  /// 原始文本块（题目的完整文本）
  final String rawText;

  /// 识别到的题型
  final CandidateType candidateType;

  /// 题目标题（首行提取）
  final String title;

  /// 选项列表（A/B/C/D 等）
  final List<String> options;

  /// 参考答案文本
  final String answer;

  /// 解析/解释文本
  final String explanation;

  /// 置信度 0.0–1.0
  final double confidence;

  /// 在原文中的行号范围（用于定位）
  final int startLine;
  final int endLine;

  /// 附加元数据
  final Map<String, String> metadata;

  const ParseCandidate({
    required this.rawText,
    required this.candidateType,
    this.title = '',
    this.options = const [],
    this.answer = '',
    this.explanation = '',
    this.confidence = 0.0,
    this.startLine = 0,
    this.endLine = 0,
    this.metadata = const {},
  });

  factory ParseCandidate.fromJson(Map<String, dynamic> json) =>
      _$ParseCandidateFromJson(json);

  Map<String, dynamic> toJson() => _$ParseCandidateToJson(this);

  /// 创建副本，可选择性覆盖字段
  ParseCandidate copyWith({
    String? rawText,
    CandidateType? candidateType,
    String? title,
    List<String>? options,
    String? answer,
    String? explanation,
    double? confidence,
    int? startLine,
    int? endLine,
    Map<String, String>? metadata,
  }) {
    return ParseCandidate(
      rawText: rawText ?? this.rawText,
      candidateType: candidateType ?? this.candidateType,
      title: title ?? this.title,
      options: options ?? this.options,
      answer: answer ?? this.answer,
      explanation: explanation ?? this.explanation,
      confidence: confidence ?? this.confidence,
      startLine: startLine ?? this.startLine,
      endLine: endLine ?? this.endLine,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParseCandidate &&
          runtimeType == other.runtimeType &&
          rawText == other.rawText &&
          candidateType == other.candidateType &&
          answer == other.answer;

  @override
  int get hashCode =>
      rawText.hashCode ^ candidateType.hashCode ^ answer.hashCode;

  @override
  String toString() =>
      'ParseCandidate(type: $candidateType, title: $title,'
      ' confidence: $confidence)';
}
