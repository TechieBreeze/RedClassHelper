// test/widget/features/quiz/quiz_screen_responsive_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:redclass/core/platform/platform_info.dart';
import 'package:redclass/core/platform/responsive.dart';
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

class _StubSettingsNotifier extends QuizSettingsNotifier {
  _StubSettingsNotifier(this._initial);

  final QuizSettings _initial;

  @override
  QuizSettings build() => _initial;
}

/// Wrap [QuizScreen] in a [ResponsiveBuilder] that injects a hermetic
/// [PlatformInfo]. The form factor (compact/medium/expanded) selected by
/// the inner [AdaptiveLayout] will follow [info], not the host platform.
///
/// QuizScreen receives [info] directly via its constructor, so `_isDesktop`
/// is hermetic across CI hosts (Windows/Linux/macOS).
Widget _harness({
  required Size size,
  required AppPlatform platform,
  required QuizSessionState session,
  required QuizSettings settings,
}) {
  final info = PlatformInfo.forTesting(
    platform: platform,
    shortestSide: size.shortestSide,
  );
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
        child: ResponsiveBuilder(
          info: info,
          // Builder is unused — QuizScreen drives its own AdaptiveLayout.
          // We only need this wrapper to advertise the override pattern
          // for future tests that DO consume ResponsiveBuilder.
          builder: (_, _) =>
              QuizScreen(bankId: 'bank1', mode: 'random', info: info),
        ),
      ),
    ),
  );
}

/// True iff any [ConstrainedBox] DESCENDANT of the element matched by
/// [startFinder] has `maxWidth` equal to [maxWidth]. QuizScreen's medium
/// branch wraps the body in `Center > ConstrainedBox(maxWidth: 720) >
/// SingleChildScrollView > Column`. The compact branch wraps it in
/// nothing — its body is the bare `SingleChildScrollView > Column`.
/// Searching descendants of the `quiz_vertical_layout` KeyedSubtree
/// therefore distinguishes medium from compact.
bool _hasDescendantConstrainedBoxMaxWidth(Finder startFinder, double maxWidth) {
  final matches = find
      .descendant(
        of: startFinder,
        matching: find.byWidgetPredicate(
          (w) => w is ConstrainedBox && w.constraints.maxWidth == maxWidth,
        ),
      )
      .evaluate();
  return matches.isNotEmpty;
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
        platform: AppPlatform.android,
        session: _makeActiveSession(),
        settings: const QuizSettings(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quiz_vertical_layout')), findsOneWidget);
    expect(find.byKey(const Key('quiz_horizontal_layout')), findsNothing);
  });

  testWidgets(
    'medium width (700x900) renders vertical layout key with 720-centered ConstrainedBox ancestor',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(700, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(
          size: const Size(700, 900),
          platform: AppPlatform.android,
          session: _makeActiveSession(),
          settings: const QuizSettings(),
        ),
      );
      await tester.pumpAndSettle();

      // Medium shares the vertical layout key with compact (per the brief).
      expect(find.byKey(const Key('quiz_vertical_layout')), findsOneWidget);
      expect(find.byKey(const Key('quiz_horizontal_layout')), findsNothing);

      // The medium branch wraps the body in Center + ConstrainedBox(720).
      // Compact does NOT — its maxWidth is null. So this assertion
      // distinguishes medium from compact.
      expect(
        _hasDescendantConstrainedBoxMaxWidth(
          find.byKey(const Key('quiz_vertical_layout')),
          720,
        ),
        isTrue,
      );
    },
  );

  testWidgets('expanded width (1500x1000) renders horizontal layout key', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1500, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _harness(
        size: const Size(1500, 1000),
        platform: AppPlatform.windows,
        session: _makeActiveSession(),
        settings: const QuizSettings(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quiz_horizontal_layout')), findsOneWidget);
    expect(find.byKey(const Key('quiz_vertical_layout')), findsNothing);
  });
}
