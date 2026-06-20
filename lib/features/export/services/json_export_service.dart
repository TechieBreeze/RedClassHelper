import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'package:redclass/data/db/database.dart';

/// Converts a bank and its questions to the user's established JSON format.
///
/// Output structure (D-01):
/// ```json
/// {
///   "name": "题库名称",
///   "version": "1.0",
///   "questions": {
///     "1": {"question": "...", "answer": {"A": "..."}, "key": "B", "answer_type": 0}
///   }
/// }
/// ```
///
/// Questions are numbered 1-based in the given [questions] list order.
/// Does NOT include timestamps, UUIDs, or rawText (D-02).
Map<String, dynamic> bankToUserJson(
  QuestionBank bank,
  List<Question> questions,
) {
  final questionsMap = <String, dynamic>{};
  for (var i = 0; i < questions.length; i++) {
    final q = questions[i];
    final optionsList =
        (jsonDecode(q.optionsJson) as List).cast<Map<String, dynamic>>();
    final correctList =
        (jsonDecode(q.correctJson) as List).cast<String>();

    final answerMap = <String, String>{};
    for (final opt in optionsList) {
      answerMap[opt['key'] as String] = opt['text'] as String;
    }

    final keyStr = correctList.join();

    questionsMap['${i + 1}'] = {
      'question': '${i + 1}. ${q.stem}',
      'answer': answerMap,
      'key': keyStr,
      'answer_type': q.type == 'multiple' ? 1 : 0,
    };
  }

  return {
    'name': bank.name,
    'version': '1.0',
    'questions': questionsMap,
  };
}

/// Converts user JSON format back to DB entities for insertion.
///
/// Validates the input structure (D-01):
/// - [json] must contain non-empty 'name' (String), 'version' (String),
///   and 'questions' (non-empty Map).
/// - Question keys must be numeric (e.g., "1", "2", ...).
/// - Each question's 'key' must match `^[A-H]+$`.
/// - Each question's 'answer_type' must be 0 or 1.
///
/// Returns a record containing the parsed bank name and a list of
/// [QuestionsCompanion.insert] instances ready for DB insertion.
///
/// Throws [FormatException] with a descriptive message on validation failure.
({String bankName, List<QuestionsCompanion> questions}) userJsonToEntities(
  Map<String, dynamic> json,
  String bankId,
) {
  // Validate top-level 'name'
  final name = json['name'];
  if (name is! String || name.isEmpty) {
    throw const FormatException(
      'JSON must contain a non-empty "name" field',
    );
  }

  // Validate 'version'
  if (json['version'] is! String) {
    throw const FormatException('JSON must contain a "version" field');
  }

  // Validate 'questions'
  final questionsData = json['questions'];
  if (questionsData is! Map<String, dynamic> || questionsData.isEmpty) {
    throw const FormatException(
      'JSON must contain a non-empty "questions" map',
    );
  }

  // Sort keys numerically (not lexicographically) — Pitfall 2
  final sortedKeys = questionsData.keys
      .map((k) => int.parse(k))
      .toList()
    ..sort();

  final companions = <QuestionsCompanion>[];
  for (final numKey in sortedKeys) {
    final keyStr = '$numKey';
    final qData = questionsData[keyStr];
    if (qData is! Map<String, dynamic>) {
      throw FormatException('Question $numKey is not a valid object');
    }

    // Validate 'key' — must match ^[A-H]+$
    final rawKey = qData['key'];
    if (rawKey is! String || !RegExp(r'^[A-H]+$').hasMatch(rawKey)) {
      throw FormatException(
        'Question $numKey has invalid key: $rawKey',
      );
    }

    // Validate 'answer_type' — must be 0 or 1
    final answerType = qData['answer_type'];
    if (answerType is! int || (answerType != 0 && answerType != 1)) {
      throw FormatException(
        'Question $numKey has invalid answer_type: $answerType',
      );
    }

    // Validate 'answer' — must be a Map (String → String)
    final answerRaw = qData['answer'];
    if (answerRaw is! Map) {
      throw FormatException('Question $numKey answer must be a map');
    }
    final answerMap = answerRaw.map(
      (k, v) => MapEntry(k.toString(), v.toString()),
    );

    // Convert answer map to options array: {"A":"text"} → [{"key":"A","text":"text"}]
    final optionsList = answerMap.entries.map((e) => {
          'key': e.key,
          'text': e.value,
        }).toList();

    // Convert key string to array: "AC" → ["A","C"]
    final correctList = rawKey.split('').toList();

    final questionText = qData['question'];
    companions.add(QuestionsCompanion.insert(
      id: const Uuid().v4(),
      bankId: bankId,
      type: answerType == 1 ? 'multiple' : 'single',
      stem: questionText is String ? questionText : '$questionText',
      optionsJson: jsonEncode(optionsList),
      correctJson: jsonEncode(correctList),
      rawText: questionText is String ? questionText : '$questionText',
      createdAt: DateTime.now(),
    ));
  }

  return (bankName: name, questions: companions);
}
