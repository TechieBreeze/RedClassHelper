import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:redclass/data/db/database.dart';
import 'package:redclass/features/export/services/json_export_service.dart';

/// Helper: build a QuestionBank data class for unit tests (no DB needed).
QuestionBank _testBank({
  String id = 'bank-1',
  String name = 'Test Bank',
  String source = 'test.json',
  int questionCount = 1,
}) {
  final now = DateTime.now();
  return QuestionBank(
    id: id,
    name: name,
    source: source,
    questionCount: questionCount,
    createdAt: now,
    updatedAt: now,
  );
}

/// Helper: build a single-choice Question data class.
Question _singleChoiceQuestion({
  String id = 'q-1',
  String bankId = 'bank-1',
  String stem = 'What is the capital of France?',
  List<String> options = const ['Paris', 'London', 'Berlin', 'Madrid'],
  String correctKey = 'A',
}) {
  final optionsList = <Map<String, String>>[];
  for (var i = 0; i < options.length; i++) {
    final key = String.fromCharCode('A'.codeUnitAt(0) + i);
    optionsList.add({'key': key, 'text': options[i]});
  }
  return Question(
    id: id,
    bankId: bankId,
    type: 'single',
    stem: stem,
    optionsJson: jsonEncode(optionsList),
    correctJson: jsonEncode([correctKey]),
    rawText: stem,
    createdAt: DateTime.now(),
  );
}

/// Helper: build a multi-choice Question data class.
Question _multiChoiceQuestion({
  String id = 'q-2',
  String bankId = 'bank-1',
  String stem = 'Which of these are fruits?',
  List<String> options = const ['Apple', 'Carrot', 'Banana', 'Potato'],
  List<String> correctKeys = const ['A', 'C'],
}) {
  final optionsList = <Map<String, String>>[];
  for (var i = 0; i < options.length; i++) {
    final key = String.fromCharCode('A'.codeUnitAt(0) + i);
    optionsList.add({'key': key, 'text': options[i]});
  }
  return Question(
    id: id,
    bankId: bankId,
    type: 'multiple',
    stem: stem,
    optionsJson: jsonEncode(optionsList),
    correctJson: jsonEncode(correctKeys),
    rawText: stem,
    createdAt: DateTime.now(),
  );
}

void main() {
  // ═════════════════════════════════════════════════════════════
  // bankToUserJson() tests
  // ═════════════════════════════════════════════════════════════

  group('bankToUserJson', () {
    // Test 1: single-choice → answer_type=0, key="A", answer map
    test('single-choice produces answer_type=0, key="A", answer map', () {
      final bank = _testBank(name: '2024秋-数据库原理');
      final question = _singleChoiceQuestion(
        stem: '数据库系统的核心是_____。',
        options: ['数据库', '数据库管理系统', '数据模型', '软件工具'],
        correctKey: 'B',
      );

      final result = bankToUserJson(bank, [question]);

      expect(result['name'], '2024秋-数据库原理');
      expect(result['version'], '1.0');

      final questions = result['questions'] as Map<String, dynamic>;
      expect(questions.length, 1);

      final q1 = questions['1'] as Map<String, dynamic>;
      expect(q1['question'], '数据库系统的核心是_____。');
      expect(q1['key'], 'B');
      expect(q1['answer_type'], 0);

      final answer = q1['answer'] as Map<String, dynamic>;
      expect(answer['A'], '数据库');
      expect(answer['B'], '数据库管理系统');
      expect(answer['C'], '数据模型');
      expect(answer['D'], '软件工具');
    });

    // Test 2: multi-choice → answer_type=1, key="AC", answer map 4 entries
    test('multi-choice produces answer_type=1, key="AC", 4 answer entries',
        () {
      final bank = _testBank();
      final question = _multiChoiceQuestion(
        stem: 'Which of these are fruits?',
        options: ['Apple', 'Carrot', 'Banana', 'Potato'],
        correctKeys: ['A', 'C'],
      );

      final result = bankToUserJson(bank, [question]);

      final q1 = (result['questions'] as Map<String, dynamic>)['1']
          as Map<String, dynamic>;
      expect(q1['answer_type'], 1);
      expect(q1['key'], 'AC');
      expect((q1['answer'] as Map).length, 4);
      expect(q1['answer']['A'], 'Apple');
      expect(q1['answer']['C'], 'Banana');
    });

    // Test 3: empty question list → empty questions map
    test('empty question list produces empty questions map', () {
      final bank = _testBank(name: 'X');

      final result = bankToUserJson(bank, []);

      expect(result['name'], 'X');
      expect(result['version'], '1.0');
      final questions = result['questions'] as Map<String, dynamic>;
      expect(questions, isEmpty);
    });

    // Test 4: 5 questions → numbered keys "1" through "5"
    test('5 questions produce numbered keys 1-5 in order', () {
      final bank = _testBank();
      final questions = List.generate(5, (i) => _singleChoiceQuestion(
            id: 'q-${i + 1}',
            stem: 'Question ${i + 1}',
          ));

      final result = bankToUserJson(bank, questions);

      final qs = result['questions'] as Map<String, dynamic>;
      expect(qs.length, 5);
      for (var i = 1; i <= 5; i++) {
        expect(qs.containsKey('$i'), isTrue,
            reason: 'Expected key "$i" in questions map');
      }
      // Verify order: the map itself has insertion order
      final keys = qs.keys.toList();
      expect(keys, ['1', '2', '3', '4', '5']);
    });

    // Test 5: no timestamps or UUIDs in output (D-02)
    test('output does NOT include timestamps or UUIDs', () {
      final bank = _testBank(id: 'some-uuid', name: 'Test');
      final question = _singleChoiceQuestion(id: 'q-uuid', bankId: 'some-uuid');

      final result = bankToUserJson(bank, [question]);
      final jsonStr = jsonEncode(result);

      // Should not contain UUIDs
      expect(jsonStr, isNot(contains('some-uuid')));
      expect(jsonStr, isNot(contains('q-uuid')));

      // Should not contain timestamp keys
      expect(jsonStr, isNot(contains('createdAt')));
      expect(jsonStr, isNot(contains('created_at')));
      expect(jsonStr, isNot(contains('updatedAt')));
      expect(jsonStr, isNot(contains('updated_at')));

      // Should not contain rawText
      expect(jsonStr, isNot(contains('rawText')));
      expect(jsonStr, isNot(contains('raw_text')));

      // Should not contain source
      expect(jsonStr, isNot(contains('source')));

      // Top-level keys should be exactly name, version, questions
      expect(result.keys.toSet(), {'name', 'version', 'questions'});
    });

    // Test 5a: inline answer brackets preserved, only answer letters removed
    test('strips answer letters from （X）but keeps brackets', () {
      final bank = _testBank(name: 'Test');
      final question = _singleChoiceQuestion(
        stem: '会议是（D）',
        options: ['A选项', 'B选项', 'C选项', 'D选项'],
        correctKey: 'D',
      );

      final result = bankToUserJson(bank, [question]);
      final q1 = (result['questions'] as Map<String, dynamic>)['1']
          as Map<String, dynamic>;
      expect(q1['question'], '会议是（）');
    });

    test('strips answer letters from （ABC）but keeps brackets', () {
      final bank = _testBank(name: 'Test');
      final question = _multiChoiceQuestion(
        stem: '下列哪些是正确的（ABC）',
        options: ['A选项', 'B选项', 'C选项', 'D选项'],
        correctKeys: ['A', 'B', 'C'],
      );

      final result = bankToUserJson(bank, [question]);
      final q1 = (result['questions'] as Map<String, dynamic>)['1']
          as Map<String, dynamic>;
      expect(q1['question'], '下列哪些是正确的（）');
    });

    test('preserves stem without answer marker unchanged', () {
      final bank = _testBank(name: 'Test');
      final question = _singleChoiceQuestion(
        stem: '普通无标记的题干',
        options: ['A', 'B', 'C', 'D'],
        correctKey: 'B',
      );

      final result = bankToUserJson(bank, [question]);
      final q1 = (result['questions'] as Map<String, dynamic>)['1']
          as Map<String, dynamic>;
      expect(q1['question'], '普通无标记的题干');
    });

    test('strips true/false （对）marker, keeps brackets', () {
      final bank = _testBank(name: 'Test');
      final question = Question(
        id: 'q-tf',
        bankId: 'bank-1',
        type: 'single',
        stem: '资本是能够带来剩余价值的价值。（对）',
        optionsJson: jsonEncode([]),
        correctJson: jsonEncode(['对']),
        rawText: '资本是能够带来剩余价值的价值。（对）',
        createdAt: DateTime.now(),
      );

      final result = bankToUserJson(bank, [question]);
      final q1 = (result['questions'] as Map<String, dynamic>)['1']
          as Map<String, dynamic>;
      expect(q1['question'], '资本是能够带来剩余价值的价值。（）');
    });

    test('strips true/false （错）marker, keeps brackets', () {
      final bank = _testBank(name: 'Test');
      final question = Question(
        id: 'q-tf2',
        bankId: 'bank-1',
        type: 'single',
        stem: '运动和发展是唯物辩证法的总特征。（错）',
        optionsJson: jsonEncode([]),
        correctJson: jsonEncode(['错']),
        rawText: '运动和发展是唯物辩证法的总特征。（错）',
        createdAt: DateTime.now(),
      );

      final result = bankToUserJson(bank, [question]);
      final q1 = (result['questions'] as Map<String, dynamic>)['1']
          as Map<String, dynamic>;
      expect(q1['question'], '运动和发展是唯物辩证法的总特征。（）');
    });

    test('true/false with A/B options exports as single-choice', () {
      final bank = _testBank(name: '马原理题库');
      final question = Question(
        id: 'q-tf-export',
        bankId: 'bank-1',
        type: 'single',
        stem: '资本是能够带来剩余价值的价值。',
        optionsJson: jsonEncode([
          {'key': 'A', 'text': '对'},
          {'key': 'B', 'text': '错'},
        ]),
        correctJson: jsonEncode(['A']),
        rawText: '资本是能够带来剩余价值的价值。',
        createdAt: DateTime.now(),
      );

      final result = bankToUserJson(bank, [question]);
      final q1 = (result['questions'] as Map<String, dynamic>)['1']
          as Map<String, dynamic>;

      expect(q1['answer_type'], 0);
      expect(q1['key'], 'A');
      expect(q1['answer'], {'A': '对', 'B': '错'});
      expect(q1['question'], '资本是能够带来剩余价值的价值。');
    });

    test('true/false export round-trip preserves options and key', () async {
      // Simulate the full import→DB→export→import cycle for a true/false question.
      // Step 1: Export an already-normalized true/false question from DB
      final bank = _testBank(name: '判断题库', id: 'tf-round');
      final originalQ = Question(
        id: 'tf-q',
        bankId: 'tf-round',
        type: 'single',
        stem: '垄断价格是垄断组织规定的旨在保证获取最大限度利润的市场价格。',
        optionsJson: jsonEncode([
          {'key': 'A', 'text': '对'},
          {'key': 'B', 'text': '错'},
        ]),
        correctJson: jsonEncode(['A']),
        rawText: '垄断价格...（对）',
        createdAt: DateTime.now(),
      );

      // Export
      final exported = bankToUserJson(bank, [originalQ]);

      // Step 2: Import back
      final imported = userJsonToEntities(exported, 'new-bank');

      // Verify bank name preserved
      expect(imported.bankName, '判断题库');

      // Verify question
      expect(imported.questions.length, 1);
      final q = imported.questions.first;
      expect(q.type.value, 'single');
      expect(q.stem.value, '垄断价格是垄断组织规定的旨在保证获取最大限度利润的市场价格。');

      final options = jsonDecode(q.optionsJson.value) as List;
      expect(options.length, 2);
      expect(options[0], {'key': 'A', 'text': '对'});
      expect(options[1], {'key': 'B', 'text': '错'});

      final correct = jsonDecode(q.correctJson.value) as List;
      expect(correct, ['A']);
    });
  });

  // ═════════════════════════════════════════════════════════════
  // userJsonToEntities() tests
  // ═════════════════════════════════════════════════════════════

  group('userJsonToEntities', () {
    // Test 6: valid JSON → correct QuestionsCompanion with type='single'
    test('parses valid JSON and produces correct QuestionsCompanion list', () {
      final json = {
        'name': 'Test Bank',
        'version': '1.0',
        'questions': {
          '1': {
            'question': '1. What is 2+2?',
            'answer': {
              'A': '3',
              'B': '4',
              'C': '5',
              'D': '6',
            },
            'key': 'B',
            'answer_type': 0,
          },
        },
      };

      final result = userJsonToEntities(json, 'bank-id-1');

      expect(result.bankName, 'Test Bank');
      expect(result.questions.length, 1);

      final q = result.questions.first;
      expect(q.type.present, isTrue);
      expect(q.type.value, 'single');
      expect(q.stem.value, 'What is 2+2?');
      expect(q.bankId.value, 'bank-id-1');

      // Verify optionsJson was correctly converted
      final options =
          jsonDecode(q.optionsJson.value) as List;
      expect(options.length, 4);
      expect(options[0]['key'], 'A');
      expect(options[0]['text'], '3');

      // Verify correctJson was correctly converted
      final correct = jsonDecode(q.correctJson.value) as List;
      expect(correct, ['B']);
    });

    // Test 7: answer_type=1 → type='multiple'
    test('answer_type=1 produces type="multiple"', () {
      final json = {
        'name': 'Multi Test',
        'version': '1.0',
        'questions': {
          '1': {
            'question': '1. Select fruits.',
            'answer': {
              'A': 'Apple',
              'B': 'Carrot',
              'C': 'Banana',
              'D': 'Potato',
            },
            'key': 'AC',
            'answer_type': 1,
          },
        },
      };

      final result = userJsonToEntities(json, 'bank-id');

      expect(result.questions.length, 1);
      expect(result.questions.first.type.value, 'multiple');
    });

    // Test 8: key="ABC" → correctJson containing ["A","B","C"]
    test('key="ABC" produces correctJson ["A","B","C"]', () {
      final json = {
        'name': 'Multi Key Test',
        'version': '1.0',
        'questions': {
          '1': {
            'question': '1. Select all.',
            'answer': {'A': 'a', 'B': 'b', 'C': 'c'},
            'key': 'ABC',
            'answer_type': 1,
          },
        },
      };

      final result = userJsonToEntities(json, 'bank-id');

      final correct =
          jsonDecode(result.questions.first.correctJson.value) as List;
      expect(correct, ['A', 'B', 'C']);
    });

    // Test 9: Round-trip preserves stems, keys, options
    test('round-trip: export then import preserves all question data', () async {
      // Use an in-memory DB to simulate the round-trip more realistically
      final db = AppDatabase.openInMemoryDatabase();
      addTearDown(() async => await db.close());

      final now = DateTime.now();
      final bankId = 'round-trip-bank';

      // Insert bank
      await db.into(db.questionBanks).insert(
            QuestionBanksCompanion.insert(
              id: bankId,
              name: 'Round Trip Bank',
              source: 'test',
              questionCount: 3,
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Insert questions
      await db.into(db.questions).insert(
            QuestionsCompanion.insert(
              id: 'rt-q1',
              bankId: bankId,
              type: 'single',
              stem: 'What is the capital of France?',
              optionsJson: jsonEncode([
                {'key': 'A', 'text': 'Paris'},
                {'key': 'B', 'text': 'London'},
              ]),
              correctJson: jsonEncode(['A']),
              rawText: 'What is the capital of France?',
              createdAt: now,
            ),
          );
      await db.into(db.questions).insert(
            QuestionsCompanion.insert(
              id: 'rt-q2',
              bankId: bankId,
              type: 'multiple',
              stem: 'Select prime numbers.',
              optionsJson: jsonEncode([
                {'key': 'A', 'text': '2'},
                {'key': 'B', 'text': '4'},
                {'key': 'C', 'text': '3'},
                {'key': 'D', 'text': '6'},
              ]),
              correctJson: jsonEncode(['A', 'C']),
              rawText: 'Select prime numbers.',
              createdAt: now,
            ),
          );
      await db.into(db.questions).insert(
            QuestionsCompanion.insert(
              id: 'rt-q3',
              bankId: bankId,
              type: 'single',
              stem: 'What is 1+1?',
              optionsJson: jsonEncode([
                {'key': 'A', 'text': '1'},
                {'key': 'B', 'text': '2'},
                {'key': 'C', 'text': '3'},
                {'key': 'D', 'text': '4'},
              ]),
              correctJson: jsonEncode(['B']),
              rawText: 'What is 1+1?',
              createdAt: now,
            ),
          );

      // Read back from DB
      final bank = await (db.select(db.questionBanks)
            ..where((b) => b.id.equals(bankId)))
          .getSingle();
      final dbQuestions = await (db.select(db.questions)
            ..where((q) => q.bankId.equals(bankId)))
          .get();

      // Export to user JSON format
      final exported = bankToUserJson(bank, dbQuestions);

      // Import back
      final imported = userJsonToEntities(
        exported,
        'new-bank-id',
      );

      expect(imported.bankName, 'Round Trip Bank');
      expect(imported.questions.length, 3);

      // Verify stems preserved (no number prefix — numbering is in the map keys)
      final stems = imported.questions.map((q) => q.stem.value).toList();
      expect(stems[0], 'What is the capital of France?');
      expect(stems[1], 'Select prime numbers.');
      expect(stems[2], 'What is 1+1?');

      // Verify single-choice question
      final q1 = imported.questions[0];
      expect(q1.type.value, 'single');
      final q1Options =
          jsonDecode(q1.optionsJson.value) as List;
      expect(q1Options.length, 2);
      expect((q1Options[0] as Map)['key'], 'A');
      expect((q1Options[0] as Map)['text'], 'Paris');
      final q1Correct =
          jsonDecode(q1.correctJson.value) as List;
      expect(q1Correct, ['A']);

      // Verify multi-choice question
      final q2 = imported.questions[1];
      expect(q2.type.value, 'multiple');
      final q2Correct =
          jsonDecode(q2.correctJson.value) as List;
      expect(q2Correct, ['A', 'C']);

      // Verify option texts round-trip
      final q2Options =
          jsonDecode(q2.optionsJson.value) as List;
      expect((q2Options[0] as Map)['key'], 'A');
      expect((q2Options[0] as Map)['text'], '2');
      expect((q2Options[2] as Map)['key'], 'C');
      expect((q2Options[2] as Map)['text'], '3');
    });

    // Test 10: non-numeric question key → FormatException
    test('non-numeric question key throws FormatException', () {
      final json = {
        'name': 'Test',
        'version': '1.0',
        'questions': {
          'Q1': {
            'question': '1. Test',
            'answer': {'A': 'a'},
            'key': 'A',
            'answer_type': 0,
          },
        },
      };

      expect(
        () => userJsonToEntities(json, 'bank-id'),
        throwsA(isA<FormatException>()),
      );
    });

    // Test 11: missing 'questions' key → FormatException
    test('missing questions key throws FormatException', () {
      final json = {
        'name': 'Test',
        'version': '1.0',
      };

      expect(
        () => userJsonToEntities(json, 'bank-id'),
        throwsA(isA<FormatException>()),
      );
    });

    // Test 12: key containing character outside A-H → FormatException
    test('key with character outside A-H throws FormatException', () {
      final json = {
        'name': 'Test',
        'version': '1.0',
        'questions': {
          '1': {
            'question': '1. Test',
            'answer': {'A': 'a', 'Z': 'z'},
            'key': 'Z',
            'answer_type': 0,
          },
        },
      };

      expect(
        () => userJsonToEntities(json, 'bank-id'),
        throwsA(isA<FormatException>()),
      );
    });

    // Test 13: invalid answer_type=2 → FormatException
    test('answer_type=2 throws FormatException', () {
      final json = {
        'name': 'Test',
        'version': '1.0',
        'questions': {
          '1': {
            'question': '1. Test',
            'answer': {'A': 'a'},
            'key': 'A',
            'answer_type': 2,
          },
        },
      };

      expect(
        () => userJsonToEntities(json, 'bank-id'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
