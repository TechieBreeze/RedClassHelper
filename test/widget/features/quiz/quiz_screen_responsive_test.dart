// test/widget/features/quiz/quiz_screen_responsive_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:redclass/data/db/database.dart';
import 'package:redclass/features/quiz/models/quiz_session_state.dart';
import 'package:redclass/features/quiz/models/quiz_settings.dart';
import 'package:redclass/features/quiz/models/review_mode.dart';
import 'package:redclass/features/quiz/presentation/quiz_screen.dart';
import 'package:redclass/features/quiz/providers/quiz_session_controller.dart';
import 'package:redclass/features/quiz/providers/quiz_settings_provider.dart';

Question _makeQuestion({String id = 'q1', String type = 'single'}) {
  return Question(
    id: id,
    bankId: 'bank1',
    type: type,
    stem: '题干示例',
    optionsJson: '[{"key":"A","text":"对"},{"key":"B","text":"错"}]',
    correctJson: '["A"]',
    rawText: '题干示例',
    createdAt: DateTime(2026, 1, 1),
  );
}

QuizSessionState _makeActiveSession() {
  return QuizSessionState(
    bankId: 'bank1',
    mode: ReviewMode.random,
    questions: [_makeQuestion()],
    currentIndex: 0,
    answers: const [],
    startTime: DateTime(2026, 1, 1),
    status: QuizStatus.active,
    bankName: '示例题库',
    totalQuestions: 1,
  );
}

/// Stub controller that returns a pre-built session via build() and
/// exposes no-op methods for everything QuizScreen calls.
class _StubSessionController extends QuizSessionController {
  _StubSessionController(this._stub);

  final QuizSessionState _stub;

  @override
  Future<QuizSessionState> build(String bankId, String modeStr) async {
    return _stub;
  }

  @override
  Future<void> submitAnswer(List<String> optionKeys) async {}

  @override
  void advanceToNext() {}

  @override
  void goToPrevious() {}

  @override
  Future<void> discardSavedSession() async {}

  @override
  void resumeSavedSession() {}

  @override
  void startAutoAdvance() {}
}

Widget _harness({
  required Size size,
  required QuizSessionState session,
  required QuizSettings settings,
}) {
  return ProviderScope(
    overrides: [
      quizSessionControllerProvider(
        'bank1',
        'random',
      ).overrideWith(() => _StubSessionController(session)),
      quizSettingsProvider.overrideWith(() => _StubSettingsNotifier(settings)),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: const QuizScreen(bankId: 'bank1', mode: 'random'),
      ),
    ),
  );
}

class _StubSettingsNotifier extends QuizSettingsNotifier {
  _StubSettingsNotifier(this._initial);

  final QuizSettings _initial;

  @override
  QuizSettings build() => _initial;
}

void main() {
  testWidgets('compact width (400x800) renders vertical layout key', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _harness(
        size: const Size(400, 800),
        session: _makeActiveSession(),
        settings: const QuizSettings(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quiz_vertical_layout')), findsOneWidget);
    expect(find.byKey(const Key('quiz_horizontal_layout')), findsNothing);
  });

  testWidgets('expanded width (1500x1000) renders horizontal layout key', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1500, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _harness(
        size: const Size(1500, 1000),
        session: _makeActiveSession(),
        settings: const QuizSettings(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quiz_horizontal_layout')), findsOneWidget);
    expect(find.byKey(const Key('quiz_vertical_layout')), findsNothing);
  });
}
