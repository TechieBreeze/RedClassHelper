// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parse_candidate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ParseCandidate _$ParseCandidateFromJson(Map<String, dynamic> json) =>
    ParseCandidate(
      rawText: json['rawText'] as String,
      candidateType: $enumDecode(_$CandidateTypeEnumMap, json['candidateType']),
      title: json['title'] as String? ?? '',
      options:
          (json['options'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      answer: json['answer'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      startLine: (json['startLine'] as num?)?.toInt() ?? 0,
      endLine: (json['endLine'] as num?)?.toInt() ?? 0,
      metadata:
          (json['metadata'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$ParseCandidateToJson(ParseCandidate instance) =>
    <String, dynamic>{
      'rawText': instance.rawText,
      'candidateType': _$CandidateTypeEnumMap[instance.candidateType]!,
      'title': instance.title,
      'options': instance.options,
      'answer': instance.answer,
      'explanation': instance.explanation,
      'confidence': instance.confidence,
      'startLine': instance.startLine,
      'endLine': instance.endLine,
      'metadata': instance.metadata,
    };

const _$CandidateTypeEnumMap = {
  CandidateType.singleChoice: 'single_choice',
  CandidateType.multiChoice: 'multi_choice',
  CandidateType.trueFalse: 'true_false',
  CandidateType.shortAnswer: 'short_answer',
  CandidateType.unknown: 'unknown',
};
