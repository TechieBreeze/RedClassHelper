import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'package:redclass/data/db/database.dart';

/// Matches inline answer markers like （D）, (ABC), (A B), （ A ）etc.
/// Captures opening and closing brackets separately so only the answer
/// letters inside are removed, preserving the brackets themselves.
final RegExp _inlineAnswerCleanRE = RegExp(
  r'([（(])\s*[A-Ha-h\s]{1,24}\s*([）)])',
);

/// Matches inline true/false markers like （对）（错）（T）（F）（✓）（×）.
/// Captures opening and closing brackets separately so only the answer
/// text inside is removed, preserving the brackets themselves.
final RegExp _trueFalseCleanRE = RegExp(
  r'([（(])\s*[✓✗×√×✔✘✅❌TFtf对错是非]{1,2}\s*([）)])',
);

/// Strips inline answer letters and true/false markers from brackets in a
/// question stem, preserving the brackets themselves.
///  "会议是（D）" → "会议是（）"
///  "资本是...价值。（对）" → "资本是...价值。（）"
String _stripInlineAnswer(String stem) {
  stem = stem.replaceAllMapped(
    _inlineAnswerCleanRE,
    (m) => '${m.group(1)}${m.group(2)}',
  );
  stem = stem.replaceAllMapped(
    _trueFalseCleanRE,
    (m) => '${m.group(1)}${m.group(2)}',
  );
  return stem;
}

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
/// Questions are numbered 1-based by the map keys; the stem itself carries
/// no number prefix.
/// Does NOT include timestamps, UUIDs, or rawText (D-02).
/// Inline answer markers like （D）are stripped from the question stem.
Map<String, dynamic> bankToUserJson(
  QuestionBank bank,
  List<Question> questions,
) {
  final questionsMap = <String, dynamic>{};
  for (var i = 0; i < questions.length; i++) {
    final q = questions[i];
    final optionsList = (jsonDecode(q.optionsJson) as List)
        .cast<Map<String, dynamic>>();
    final correctList = (jsonDecode(q.correctJson) as List).cast<String>();

    final answerMap = <String, String>{};
    for (final opt in optionsList) {
      answerMap[opt['key'] as String] = opt['text'] as String;
    }

    final keyStr = correctList.join();

    questionsMap['${i + 1}'] = {
      'question': _stripInlineAnswer(q.stem),
      'answer': answerMap,
      'key': keyStr,
      'answer_type': q.type == 'multiple' ? 1 : 0,
    };
  }

  return {'name': bank.name, 'version': '1.0', 'questions': questionsMap};
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
    throw const FormatException('JSON must contain a non-empty "name" field');
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
  final sortedKeys = questionsData.keys.map((k) => int.parse(k)).toList()
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
      throw FormatException('Question $numKey has invalid key: $rawKey');
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
    final optionsList = answerMap.entries
        .map((e) => {'key': e.key, 'text': e.value})
        .toList();

    // Convert key string to array: "AC" → ["A","C"]
    final correctList = rawKey.split('').toList();

    final questionText = qData['question'];
    // 去掉旧格式可能残留的 "1. " 编号前缀
    final stem = (questionText is String ? questionText : '$questionText')
        .replaceFirst(RegExp(r'^\d+[.、．]\s*'), '');
    companions.add(
      QuestionsCompanion.insert(
        id: const Uuid().v4(),
        bankId: bankId,
        type: answerType == 1 ? 'multiple' : 'single',
        stem: stem,
        optionsJson: jsonEncode(optionsList),
        correctJson: jsonEncode(correctList),
        rawText: stem,
        createdAt: DateTime.now(),
      ),
    );
  }

  return (bankName: name, questions: companions);
}
