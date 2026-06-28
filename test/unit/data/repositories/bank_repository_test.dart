import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/data/db/database.dart';
import 'package:redclass/data/repositories/bank_repository.dart';

void main() {
  late AppDatabase db;
  late BankRepository repo;

  setUp(() async {
    db = AppDatabase.openInMemoryDatabase();
    repo = BankRepositoryImpl(db);
  });

  tearDown(() async => await db.close());

  Future<void> insertBank(String id, {String name = 'Test Bank'}) async {
    final now = DateTime.now();
    await db
        .into(db.questionBanks)
        .insertOnConflictUpdate(
          QuestionBanksCompanion.insert(
            id: id,
            name: name,
            source: const Value('test'),
            questionCount: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> insertQuestion(String id, String bankId) async {
    final now = DateTime.now();
    await db
        .into(db.questions)
        .insert(
          QuestionsCompanion.insert(
            id: id,
            bankId: bankId,
            type: 'single',
            stem: 'Q?',
            optionsJson: '[{"key":"A","text":"a"}]',
            correctJson: '["A"]',
            rawText: 'Q?',
            createdAt: now,
          ),
        );
  }

  group('BankRepository.deleteBank', () {
    test('cascades delete to questions', () async {
      await insertBank('b1');
      await insertQuestion('q1', 'b1');
      await insertQuestion('q2', 'b1');

      await repo.deleteBank('b1');

      expect(await db.select(db.questionBanks).get(), isEmpty);
      expect(await db.select(db.questions).get(), isEmpty);
    });

    test('cascades three levels: attempts/bookmarks/wrong_ledger', () async {
      await insertBank('b1');
      await insertQuestion('q1', 'b1');
      final now = DateTime.now();
      await db
          .into(db.answerAttempts)
          .insert(
            AnswerAttemptsCompanion.insert(
              questionId: 'q1',
              givenAnswerJson: '["A"]',
              isCorrect: true,
              mode: 'random',
              elapsedMs: 100,
              createdAt: now,
            ),
          );
      await db
          .into(db.bookmarks)
          .insert(BookmarksCompanion.insert(questionId: 'q1', createdAt: now));
      await db
          .into(db.wrongLedgerEntries)
          .insert(
            WrongLedgerEntriesCompanion.insert(
              questionId: 'q1',
              timesWrong: 1,
              firstWrongAt: now,
              lastWrongAt: now,
            ),
          );

      await repo.deleteBank('b1');

      expect(await db.select(db.answerAttempts).get(), isEmpty);
      expect(await db.select(db.bookmarks).get(), isEmpty);
      expect(await db.select(db.wrongLedgerEntries).get(), isEmpty);
    });

    test('empty bank (0 questions) deletes cleanly', () async {
      await insertBank('b1');

      await expectLater(repo.deleteBank('b1'), completes);
      expect(await db.select(db.questionBanks).get(), isEmpty);
    });

    test('preserves orphan parse_jobs after bank deletion', () async {
      await insertBank('b1');
      final now = DateTime.now();
      await db
          .into(db.parseJobs)
          .insertOnConflictUpdate(
            ParseJobsCompanion.insert(
              id: 'pj1',
              sourcePath: const Value('old/path.pdf'),
              status: 'success',
              progress: 1.0,
              resultCount: 5,
              createdAt: now,
              updatedAt: now,
            ),
          );

      await repo.deleteBank('b1');

      expect(await db.select(db.parseJobs).get(), hasLength(1));
    });

    test('is idempotent for non-existent bankId', () async {
      await expectLater(repo.deleteBank('does-not-exist'), completes);
    });
  });
}
