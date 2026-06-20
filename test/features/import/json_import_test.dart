import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

import 'package:redclass/data/db/database.dart';
import 'package:redclass/features/import/providers/import_notifier.dart';
import 'package:redclass/features/import/providers/import_state.dart';

/// Helper: Build a valid D-01 JSON map with a given number of single-choice
/// questions. Each question has the correct key 'B' (default).
Map<String, dynamic> _validJson({
  String bankName = 'Test Bank',
  int questionCount = 1,
  String correctKey = 'B',
  int answerType = 0,
  List<String>? questionStems,
}) {
  final questions = <String, dynamic>{};
  for (var i = 0; i < questionCount; i++) {
    final stem = questionStems != null && i < questionStems.length
        ? questionStems[i]
        : '${i + 1}. Test question ${i + 1}?';
    questions['${i + 1}'] = {
      'question': stem,
      'answer': {
        'A': 'Option A',
        'B': 'Option B',
        'C': 'Option C',
        'D': 'Option D',
      },
      'key': correctKey,
      'answer_type': answerType,
    };
  }
  return {
    'name': bankName,
    'version': '1.0',
    'questions': questions,
  };
}

/// Helper: Write a JSON file to [path] and return the [File] object.
Future<File> _writeTempJson(
  Directory dir,
  String fileName,
  Map<String, dynamic> data,
) async {
  final file = File('${dir.path}/$fileName');
  await file.writeAsString(jsonEncode(data));
  return file;
}

/// Helper: Create a [ProviderContainer] with in-memory DB override.
ProviderContainer _createContainer(AppDatabase db) {
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWith((ref) async => db),
    ],
  );
}

void main() {
  late AppDatabase db;
  late Directory tempDir;

  setUp(() async {
    db = AppDatabase.openInMemoryDatabase();
    tempDir = await Directory.systemTemp.createTemp('redclass_json_import_test_');
  });

  tearDown(() async {
    await db.close();
    // Clean up temp files
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  // ═════════════════════════════════════════════════════════════
  // Test 1: importJsonFile parses valid JSON and creates QuestionBank
  // ═════════════════════════════════════════════════════════════
  test('importJsonFile parses valid JSON and creates QuestionBank', () async {
    final container = _createContainer(db);
    addTearDown(container.dispose);

    final jsonData = _validJson(bankName: 'Test Bank', questionCount: 1);
    final file = await _writeTempJson(tempDir, 'test.json', jsonData);
    final notifier = container.read(importNotifierProvider.notifier);
    // Keep a subscription alive to prevent auto-dispose during async operations
    // ignore: unused_local_variable
    final _ = container.listen(importNotifierProvider, (_, _) {});

    notifier.pickFiles([ImportFile(path: file.path, name: 'test.json', sizeBytes: 100)]);
    await notifier.importJsonFile();

    final state = container.read(importNotifierProvider);
    expect(state.phase, ImportPhase.done,
        reason: 'Should transition to done after successful import');
    expect(state.committedCount, 1);
    expect(state.bankName, 'Test Bank');

    // Verify bank exists in DB
    final banks = await db.select(db.questionBanks).get();
    expect(banks.length, 1);
    expect(banks.first.name, 'Test Bank');
    expect(banks.first.questionCount, 1);

    // Verify question exists in DB
    final questions = await db.select(db.questions).get();
    expect(questions.length, 1);
    expect(questions.first.bankId, banks.first.id);
    expect(questions.first.type, 'single');
    expect(questions.first.stem, 'Test question 1?');
  });

  // ═════════════════════════════════════════════════════════════
  // Test 2: importJsonFile parses multi-choice question correctly
  // ═════════════════════════════════════════════════════════════
  test('importJsonFile parses multi-choice question correctly', () async {
    final container = _createContainer(db);
    addTearDown(container.dispose);

    final jsonData = _validJson(
      bankName: 'Multi Test',
      questionCount: 1,
      correctKey: 'ABC',
      answerType: 1,
    );
    final file = await _writeTempJson(tempDir, 'multi.json', jsonData);
    final notifier = container.read(importNotifierProvider.notifier);
    // Keep a subscription alive to prevent auto-dispose during async operations
    // ignore: unused_local_variable
    final _ = container.listen(importNotifierProvider, (_, _) {});

    notifier.pickFiles([ImportFile(path: file.path, name: 'multi.json', sizeBytes: 100)]);
    await notifier.importJsonFile();

    final state = container.read(importNotifierProvider);
    expect(state.phase, ImportPhase.done);
    expect(state.committedCount, 1);

    // Verify question in DB has type 'multiple' and correctJson
    final questions = await db.select(db.questions).get();
    expect(questions.length, 1);
    expect(questions.first.type, 'multiple');
    final correct = jsonDecode(questions.first.correctJson) as List;
    expect(correct, ['A', 'B', 'C']);
  });

  // ═════════════════════════════════════════════════════════════
  // Test 3: importJsonFile with duplicate bank name replaces existing (D-06)
  // ═════════════════════════════════════════════════════════════
  test('importJsonFile with duplicate bank name silently replaces existing (D-06)', () async {
    // Pre-insert a bank named "重复题库" with 5 questions
    final now = DateTime.now();
    final oldBankId = 'old-bank-id';
    await db.into(db.questionBanks).insert(
          QuestionBanksCompanion.insert(
            id: oldBankId,
            name: '重复题库',
            source: 'old-source',
            questionCount: 5,
            createdAt: now,
            updatedAt: now,
          ),
        );
    for (var i = 0; i < 5; i++) {
      await db.into(db.questions).insert(
            QuestionsCompanion.insert(
              id: 'old-q-$i',
              bankId: oldBankId,
              type: 'single',
              stem: 'Old question $i',
              optionsJson: '[{"key":"A","text":"x"}]',
              correctJson: '["A"]',
              rawText: 'Old question $i',
              createdAt: now,
            ),
          );
    }

    // Verify old bank exists
    var oldBanks = await db.select(db.questionBanks).get();
    expect(oldBanks.length, 1);
    var oldQuestions = await db.select(db.questions).get();
    expect(oldQuestions.length, 5);

    // Now import JSON with same name but 3 questions
    final container = _createContainer(db);
    addTearDown(container.dispose);

    final jsonData = _validJson(bankName: '重复题库', questionCount: 3);
    final file = await _writeTempJson(tempDir, 'dup.json', jsonData);
    final notifier = container.read(importNotifierProvider.notifier);
    // Keep a subscription alive to prevent auto-dispose during async operations
    // ignore: unused_local_variable
    final _ = container.listen(importNotifierProvider, (_, _) {});

    notifier.pickFiles([ImportFile(path: file.path, name: 'dup.json', sizeBytes: 100)]);
    await notifier.importJsonFile();

    final state = container.read(importNotifierProvider);
    expect(state.phase, ImportPhase.done,
        reason: 'Should succeed — silent replacement per D-06');
    expect(state.committedCount, 3);
    expect(state.error, isNull,
        reason: 'No error — replacement is silent per D-06');

    // Verify old bank is gone (cascade deleted)
    oldBanks = await db.select(db.questionBanks).get();
    expect(oldBanks.length, 1,
        reason: 'Should have exactly 1 bank (the new one)');
    expect(oldBanks.first.name, '重复题库');
    expect(oldBanks.first.questionCount, 3);
    expect(oldBanks.first.id, isNot(oldBankId),
        reason: 'New bank ID should differ from old');

    // Verify only 3 questions exist (old 5 were cascade-deleted)
    oldQuestions = await db.select(db.questions).get();
    expect(oldQuestions.length, 3);
  });

  // ═════════════════════════════════════════════════════════════
  // Test 4: importJsonFile rejects file >10MB
  // ═════════════════════════════════════════════════════════════
  test('importJsonFile rejects file >10MB', () async {
    final container = _createContainer(db);
    addTearDown(container.dispose);

    // Create a large file (>10MB)
    final largeFile = File('${tempDir.path}/large.json');
    // Write 10MB + 1 byte
    final sink = largeFile.openWrite();
    sink.write('{'); // Start JSON
    // Fill with padding (10MB+)
    final buffer = List.filled(1024 * 1024, 0); // 1MB buffer of zeros
    for (var i = 0; i < 11; i++) {
      sink.add(buffer);
    }
    sink.write('}');
    await sink.close();

    final notifier = container.read(importNotifierProvider.notifier);
    // ignore: unused_local_variable
    final _ = container.listen(importNotifierProvider, (_, _) {});
    notifier.pickFiles([ImportFile(path: largeFile.path, name: 'large.json', sizeBytes: 11 * 1024 * 1024)]);
    await notifier.importJsonFile();

    final state = container.read(importNotifierProvider);
    expect(state.phase, ImportPhase.idle,
        reason: 'Should stay idle — file too large');
    expect(state.error, isNotNull);
    expect(state.error!, contains('10MB'));
  });

  // ═════════════════════════════════════════════════════════════
  // Test 5: importJsonFile rejects malformed JSON
  // ═════════════════════════════════════════════════════════════
  test('importJsonFile rejects malformed JSON', () async {
    final container = _createContainer(db);
    addTearDown(container.dispose);

    // Write invalid JSON
    final badFile = File('${tempDir.path}/bad.json');
    await badFile.writeAsString('{"not": "json"');

    final notifier = container.read(importNotifierProvider.notifier);
    // ignore: unused_local_variable
    final _ = container.listen(importNotifierProvider, (_, _) {});
    notifier.pickFiles([ImportFile(path: badFile.path, name: 'bad.json', sizeBytes: 100)]);
    await notifier.importJsonFile();

    final state = container.read(importNotifierProvider);
    expect(state.phase, ImportPhase.idle,
        reason: 'Should stay idle on malformed JSON');
    expect(state.error, isNotNull);
  });

  // ═════════════════════════════════════════════════════════════
  // Test 6: importJsonFile rejects JSON missing 'questions' field
  // ═════════════════════════════════════════════════════════════
  test("importJsonFile rejects JSON missing 'questions' field", () async {
    final container = _createContainer(db);
    addTearDown(container.dispose);

    final jsonData = {'name': 'Test', 'version': '1.0'};
    final file = await _writeTempJson(tempDir, 'noq.json', jsonData);
    final notifier = container.read(importNotifierProvider.notifier);
    // Keep a subscription alive to prevent auto-dispose during async operations
    // ignore: unused_local_variable
    final _ = container.listen(importNotifierProvider, (_, _) {});

    notifier.pickFiles([ImportFile(path: file.path, name: 'noq.json', sizeBytes: 100)]);
    await notifier.importJsonFile();

    final state = container.read(importNotifierProvider);
    expect(state.phase, ImportPhase.idle,
        reason: 'Should stay idle — missing questions field');
    expect(state.error, isNotNull);
    expect(state.error!.toLowerCase(), contains('questions'));
  });

  // ═════════════════════════════════════════════════════════════
  // Test 7: importJsonFile rejects JSON with empty questions map
  // ═════════════════════════════════════════════════════════════
  test('importJsonFile rejects JSON with empty questions map', () async {
    final container = _createContainer(db);
    addTearDown(container.dispose);

    final jsonData = {
      'name': 'Test',
      'version': '1.0',
      'questions': <String, dynamic>{},
    };
    final file = await _writeTempJson(tempDir, 'emptyq.json', jsonData);
    final notifier = container.read(importNotifierProvider.notifier);
    // Keep a subscription alive to prevent auto-dispose during async operations
    // ignore: unused_local_variable
    final _ = container.listen(importNotifierProvider, (_, _) {});

    notifier.pickFiles([ImportFile(path: file.path, name: 'emptyq.json', sizeBytes: 100)]);
    await notifier.importJsonFile();

    final state = container.read(importNotifierProvider);
    expect(state.phase, ImportPhase.idle,
        reason: 'Should stay idle — empty questions map');
    expect(state.error, isNotNull);
    expect(state.error!.toLowerCase(), contains('questions'));
  });

  // ═════════════════════════════════════════════════════════════
  // Test 8: importJsonFile rejects key with non-A-H characters
  // ═════════════════════════════════════════════════════════════
  test('importJsonFile rejects key with non-A-H characters (T-05-07)', () async {
    final container = _createContainer(db);
    addTearDown(container.dispose);

    final jsonData = {
      'name': 'Bad Key Test',
      'version': '1.0',
      'questions': {
        '1': {
          'question': '1. Test?',
          'answer': {'A': 'x', 'Z': 'y'},
          'key': 'Z',
          'answer_type': 0,
        },
      },
    };
    final file = await _writeTempJson(tempDir, 'badkey.json', jsonData);
    final notifier = container.read(importNotifierProvider.notifier);
    // Keep a subscription alive to prevent auto-dispose during async operations
    // ignore: unused_local_variable
    final _ = container.listen(importNotifierProvider, (_, _) {});

    notifier.pickFiles([ImportFile(path: file.path, name: 'badkey.json', sizeBytes: 100)]);
    await notifier.importJsonFile();

    final state = container.read(importNotifierProvider);
    expect(state.phase, ImportPhase.idle,
        reason: 'Should stay idle — key validation failed in userJsonToEntities');
    expect(state.error, isNotNull);
  });

  // ═════════════════════════════════════════════════════════════
  // Test 9: importJsonFile rejects invalid answer_type (not 0 or 1)
  // ═════════════════════════════════════════════════════════════
  test('importJsonFile rejects invalid answer_type (not 0 or 1)', () async {
    final container = _createContainer(db);
    addTearDown(container.dispose);

    final jsonData = {
      'name': 'Bad Type Test',
      'version': '1.0',
      'questions': {
        '1': {
          'question': '1. Test?',
          'answer': {'A': 'x'},
          'key': 'A',
          'answer_type': 5,
        },
      },
    };
    final file = await _writeTempJson(tempDir, 'badtype.json', jsonData);
    final notifier = container.read(importNotifierProvider.notifier);
    // Keep a subscription alive to prevent auto-dispose during async operations
    // ignore: unused_local_variable
    final _ = container.listen(importNotifierProvider, (_, _) {});

    notifier.pickFiles([ImportFile(path: file.path, name: 'badtype.json', sizeBytes: 100)]);
    await notifier.importJsonFile();

    final state = container.read(importNotifierProvider);
    expect(state.phase, ImportPhase.idle,
        reason: 'Should stay idle — invalid answer_type');
    expect(state.error, isNotNull);
  });

  // ═════════════════════════════════════════════════════════════
  // Test 10: importJsonFile sets bankId after successful import
  // ═════════════════════════════════════════════════════════════
  test('importJsonFile sets bankId after successful import', () async {
    final container = _createContainer(db);
    addTearDown(container.dispose);

    final jsonData = _validJson(bankName: 'BankId Test', questionCount: 1);
    final file = await _writeTempJson(tempDir, 'idtest.json', jsonData);
    final notifier = container.read(importNotifierProvider.notifier);
    // Keep a subscription alive to prevent auto-dispose during async operations
    // ignore: unused_local_variable
    final _ = container.listen(importNotifierProvider, (_, _) {});

    notifier.pickFiles([ImportFile(path: file.path, name: 'idtest.json', sizeBytes: 100)]);
    await notifier.importJsonFile();

    final state = container.read(importNotifierProvider);
    expect(state.phase, ImportPhase.done);
    expect(state.bankId, isNotEmpty, reason: 'bankId must be set after import');
    // UUID format: 36 chars with 4 hyphens (8-4-4-4-12)
    expect(state.bankId.length, 36);
    expect(state.bankId, contains('-'));
  });

  // ═════════════════════════════════════════════════════════════
  // Test 11: extractAndParse() routes .json files to importJsonFile()
  // ═════════════════════════════════════════════════════════════
  test('extractAndParse() routes .json files to importJsonFile()', () async {
    final container = _createContainer(db);
    addTearDown(container.dispose);

    final jsonData = _validJson(bankName: 'Route Test', questionCount: 1);
    final file = await _writeTempJson(tempDir, 'route.json', jsonData);
    final notifier = container.read(importNotifierProvider.notifier);
    // Keep a subscription alive to prevent auto-dispose during async operations
    // ignore: unused_local_variable
    final _ = container.listen(importNotifierProvider, (_, _) {});

    notifier.pickFiles([ImportFile(path: file.path, name: 'route.json', sizeBytes: 100)]);
    await notifier.extractAndParse();

    final state = container.read(importNotifierProvider);
    expect(state.phase, ImportPhase.done,
        reason: 'extractAndParse() should route .json directly to done, NOT editing');
    expect(state.committedCount, 1);
    expect(state.bankName, 'Route Test');

    // Verify phase NEVER went through editing
    expect(state.isEditing, isFalse);
  });

  // ═════════════════════════════════════════════════════════════
  // Test 12: importJsonFile rejects JSON missing 'name' field
  // ═════════════════════════════════════════════════════════════
  test("importJsonFile rejects JSON missing 'name' field", () async {
    final container = _createContainer(db);
    addTearDown(container.dispose);

    final jsonData = {
      'version': '1.0',
      'questions': {
        '1': {
          'question': '1. Test?',
          'answer': {'A': 'x'},
          'key': 'A',
          'answer_type': 0,
        },
      },
    };
    final file = await _writeTempJson(tempDir, 'noname.json', jsonData);
    final notifier = container.read(importNotifierProvider.notifier);
    // Keep a subscription alive to prevent auto-dispose during async operations
    // ignore: unused_local_variable
    final _ = container.listen(importNotifierProvider, (_, _) {});

    notifier.pickFiles([ImportFile(path: file.path, name: 'noname.json', sizeBytes: 100)]);
    await notifier.importJsonFile();

    final state = container.read(importNotifierProvider);
    expect(state.phase, ImportPhase.idle);
    expect(state.error, isNotNull);
    expect(state.error!.toLowerCase(), contains('name'));
  });

  // ═════════════════════════════════════════════════════════════
  // Test 13: importJsonFile with 5 questions commits all correctly
  // ═════════════════════════════════════════════════════════════
  test('importJsonFile with 5 questions commits all correctly', () async {
    final container = _createContainer(db);
    addTearDown(container.dispose);

    final stems = [
      'What is A?',
      'What is B?',
      'What is C?',
      'What is D?',
      'What is E?',
    ];
    final jsonData = _validJson(
      bankName: 'Five Questions',
      questionCount: 5,
      questionStems: stems,
    );
    final file = await _writeTempJson(tempDir, 'five.json', jsonData);
    final notifier = container.read(importNotifierProvider.notifier);
    // Keep a subscription alive to prevent auto-dispose during async operations
    // ignore: unused_local_variable
    final _ = container.listen(importNotifierProvider, (_, _) {});

    notifier.pickFiles([ImportFile(path: file.path, name: 'five.json', sizeBytes: 100)]);
    await notifier.importJsonFile();

    final state = container.read(importNotifierProvider);
    expect(state.phase, ImportPhase.done);
    expect(state.committedCount, 5);
    expect(state.progress, 1.0);

    final questions = await db.select(db.questions).get();
    expect(questions.length, 5);
    // Verify stems preserved
    final storedStems = questions.map((q) => q.stem).toSet();
    for (final s in stems) {
      expect(storedStems, contains(s));
    }
  });

  // ═════════════════════════════════════════════════════════════
  // Test 14: importJsonFile rejects JSON with empty 'name'
  // ═════════════════════════════════════════════════════════════
  test("importJsonFile rejects JSON with empty 'name' field", () async {
    final container = _createContainer(db);
    addTearDown(container.dispose);

    final jsonData = {
      'name': '',
      'version': '1.0',
      'questions': {
        '1': {
          'question': '1. Test?',
          'answer': {'A': 'x'},
          'key': 'A',
          'answer_type': 0,
        },
      },
    };
    final file = await _writeTempJson(tempDir, 'emptyname.json', jsonData);
    final notifier = container.read(importNotifierProvider.notifier);
    // Keep a subscription alive to prevent auto-dispose during async operations
    // ignore: unused_local_variable
    final _ = container.listen(importNotifierProvider, (_, _) {});

    notifier.pickFiles([ImportFile(path: file.path, name: 'emptyname.json', sizeBytes: 100)]);
    await notifier.importJsonFile();

    final state = container.read(importNotifierProvider);
    expect(state.phase, ImportPhase.idle);
    expect(state.error, isNotNull);
    expect(state.error!.toLowerCase(), contains('name'));
  });
}
