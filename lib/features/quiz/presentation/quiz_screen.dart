import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/quiz_session_state.dart';
import '../models/quiz_settings.dart';
import '../models/review_mode.dart';
import '../providers/quiz_session_controller.dart';
import '../providers/quiz_settings_provider.dart';
import 'widgets/keyboard_shortcut_hint.dart';
import 'widgets/option_card.dart';
import 'widgets/quiz_progress_bar.dart';
import 'widgets/wrong_question_chip.dart';

/// Ephemeral UI-only state for the selected option in confirm submit mode.
///
/// This is a transient selection that the user makes before confirming
/// via Space key or "确认提交" button. It resets after submission or
/// when the question changes. Uses built-in [StateProvider] to avoid
/// code generation for this UI-local state.
final _quizSelectedOptionProvider = StateProvider<String?>((ref) => null);

/// Compute the visual state of an option card based on quiz context.
///
/// Follows the D-04 UI-SPEC color contract:
/// - Pre-submit: selected (highlighted) or normal
/// - Post-submit: correct, wrongSelected, correctUnselected, or dimmed
OptionCardState computeOptionState({
  required String optionKey,
  required List<String> correctKeys,
  required String? selectedKey,
  required bool hasSubmitted,
}) {
  if (!hasSubmitted) {
    return selectedKey == optionKey
        ? OptionCardState.selected
        : OptionCardState.normal;
  }
  // Post-submit states
  final isCorrectOption = correctKeys.contains(optionKey);
  final isSelectedByUser = selectedKey == optionKey;

  if (isCorrectOption && isSelectedByUser) return OptionCardState.correct;
  if (!isCorrectOption && isSelectedByUser) {
    return OptionCardState.wrongSelected;
  }
  if (isCorrectOption && !isSelectedByUser) {
    return OptionCardState.correctUnselected;
  }
  return OptionCardState.dimmed; // !correct && !selected
}

/// The primary quiz-taking screen — D-01 through D-06.
///
/// Displays one question at a time: stem, four option cards, progress bar,
/// keyboard shortcut hint, and animated wrong-question chip.
///
/// Supports instant/confirm submit modes and auto/manual advance modes
/// per quiz settings persisted in shared_preferences (D-02, D-03).
/// Desktop keyboard shortcuts are handled via [CallbackShortcuts] (D-06).
///
/// On non-desktop platforms, displays a fallback message since v1 is
/// desktop-only (Windows/Linux).
class QuizScreen extends ConsumerWidget {
  const QuizScreen({super.key, required this.bankId, required this.mode});

  /// The question bank ID from the route parameter.
  final String bankId;

  /// The review mode string from the route parameter (random/review/spotcheck).
  final String mode;

  /// Whether this is a desktop platform (Windows or Linux).
  bool get _isDesktop => !kIsWeb && (Platform.isWindows || Platform.isLinux);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_isDesktop) {
      return Scaffold(
        appBar: AppBar(title: const Text('答题')),
        body: const Center(
          child: Text('答题功能仅支持桌面端 (Windows/Linux)'),
        ),
      );
    }

    final modeEnum = reviewModeFromString(mode);
    final sessionAsync =
        ref.watch(quizSessionControllerProvider(bankId, mode));
    final session = sessionAsync.value;
    final settings = ref.watch(quizSettingsNotifierProvider);
    final selectedOption = ref.watch(_quizSelectedOptionProvider);

    // Loading state
    if (session == null || session.status == QuizStatus.loading) {
      return Scaffold(
        appBar: AppBar(title: Text('${reviewModeDisplayName(modeEnum)} · ...')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('加载题目...'),
            ],
          ),
        ),
      );
    }

    // Error state
    if (session.status == QuizStatus.error) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${reviewModeDisplayName(modeEnum)} · 错误'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                '加载题目失败，请重试',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () {
                  ref.invalidate(quizSessionControllerProvider(bankId, mode));
                },
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty bank state
    if (session.status == QuizStatus.complete &&
        session.totalQuestions == 0) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            '${reviewModeDisplayName(modeEnum)} · ${session.bankName}',
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '该题库暂无题目',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => context.go('/'),
                child: const Text('返回'),
              ),
            ],
          ),
        ),
      );
    }

    // Quiz complete — redirect to summary
    if (session.status == QuizStatus.complete &&
        (session.totalQuestions ?? 0) > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/quiz/$bankId/$mode/summary');
        }
      });
      return Scaffold(
        appBar: AppBar(
          title: Text(
            '${reviewModeDisplayName(modeEnum)} · ${session.bankName ?? ''}',
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Active quiz — build the full quiz UI
    final question = session.currentQuestion;
    if (question == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final options = (jsonDecode(question.optionsJson) as List)
        .map((o) => Map<String, dynamic>.from(o as Map))
        .toList();
    final correctKeys =
        List<String>.from(jsonDecode(question.correctJson) as List);
    final hasSubmitted = session.status == QuizStatus.showingFeedback;
    final totalQuestions = session.questions.length;
    final currentNumber = session.currentIndex + 1;

    final modeName = reviewModeDisplayName(modeEnum);
    final bankName = session.bankName ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('$modeName · $bankName'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Focus(
        autofocus: true,
        child: CallbackShortcuts(
          bindings: _buildKeyBindings(ref, settings, hasSubmitted),
          child: _buildQuizBody(
            context,
            ref,
            question.stem,
            options,
            correctKeys,
            selectedOption,
            hasSubmitted,
            currentNumber,
            totalQuestions,
            settings,
            session,
          ),
        ),
      ),
    );
  }

  /// Build keyboard shortcut bindings for desktop (D-06).
  Map<ShortcutActivator, VoidCallback> _buildKeyBindings(
    WidgetRef ref,
    QuizSettings settings,
    bool hasSubmitted,
  ) {
    return <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.keyA):
          () => _onOptionTap(ref, 'A', settings, hasSubmitted),
      const SingleActivator(LogicalKeyboardKey.keyB):
          () => _onOptionTap(ref, 'B', settings, hasSubmitted),
      const SingleActivator(LogicalKeyboardKey.keyC):
          () => _onOptionTap(ref, 'C', settings, hasSubmitted),
      const SingleActivator(LogicalKeyboardKey.keyD):
          () => _onOptionTap(ref, 'D', settings, hasSubmitted),
      const SingleActivator(LogicalKeyboardKey.space): () {
        if (settings.submitMode == QuizSubmitMode.confirm && !hasSubmitted) {
          _onSubmitConfirm(ref);
        }
      },
      const SingleActivator(LogicalKeyboardKey.arrowRight): () {
        if (hasSubmitted && settings.advanceMode == QuizAdvanceMode.manual) {
          _onAdvance(ref);
        }
      },
    };
  }

  /// Build the main quiz body with LayoutBuilder + ConstrainedBox pattern.
  Widget _buildQuizBody(
    BuildContext context,
    WidgetRef ref,
    String stem,
    List<Map<String, dynamic>> options,
    List<String> correctKeys,
    String? selectedOption,
    bool hasSubmitted,
    int currentNumber,
    int totalQuestions,
    QuizSettings settings,
    QuizSessionState session,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress bar + counter (D-05)
                  QuizProgressBar(
                    current: currentNumber,
                    total: totalQuestions,
                  ),
                  const SizedBox(height: 24),

                  // Question stem (D-01)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        stem,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Option cards (D-01, D-04)
                  ...options.map((option) {
                    final key = option['key'] as String;
                    final text = option['text'] as String;
                    final state = computeOptionState(
                      optionKey: key,
                      correctKeys: correctKeys,
                      selectedKey: hasSubmitted
                          ? session.answers.last.givenAnswer.firstOrNull
                          : selectedOption,
                      hasSubmitted: hasSubmitted,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: OptionCard(
                        optionKey: key,
                        optionText: text,
                        state: state,
                        onTap: () =>
                            _onOptionTap(ref, key, settings, hasSubmitted),
                      ),
                    );
                  }),

                  // Confirm submit button (confirm mode, pre-submit)
                  if (settings.submitMode == QuizSubmitMode.confirm &&
                      !hasSubmitted &&
                      selectedOption != null) ...[
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => _onSubmitConfirm(ref),
                      child: const Text('确认提交'),
                    ),
                  ],

                  // Wrong question chip (D-15)
                  if (hasSubmitted) ...[
                    const SizedBox(height: 8),
                    WrongQuestionChip(
                      show: _shouldShowWrongChip(session),
                    ),
                  ],

                  // Next button (manual advance mode, post-submit)
                  if (hasSubmitted &&
                      settings.advanceMode == QuizAdvanceMode.manual) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _onAdvance(ref),
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('下一题'),
                    ),
                  ],

                  // Keyboard shortcut hint (D-06)
                  const SizedBox(height: 12),
                  const KeyboardShortcutHint(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Handle an option tap or keyboard selection (D-02).
  ///
  /// In instant mode, immediately submits the answer.
  /// In confirm mode, sets the local selection state.
  void _onOptionTap(
    WidgetRef ref,
    String optionKey,
    QuizSettings settings,
    bool hasSubmitted,
  ) {
    if (hasSubmitted) return; // T-04-11: guard against double-tap

    if (settings.submitMode == QuizSubmitMode.instant) {
      _submitAnswer(ref, optionKey);
    } else {
      ref.read(_quizSelectedOptionProvider.notifier).state = optionKey;
    }
  }

  /// Submit the confirmed answer (confirm mode Space key or button).
  void _onSubmitConfirm(WidgetRef ref) {
    final selected = ref.read(_quizSelectedOptionProvider);
    if (selected == null) return;
    _submitAnswer(ref, selected);
  }

  /// Call the controller to submit the answer (D-04).
  void _submitAnswer(WidgetRef ref, String optionKey) {
    ref.read(_quizSelectedOptionProvider.notifier).state = null;
    ref
        .read(quizSessionControllerProvider(bankId, mode).notifier)
        .submitAnswer(optionKey)
        .then((_) {
      // After submission: start auto-advance if in auto mode
      final settings = ref.read(quizSettingsNotifierProvider);
      if (settings.advanceMode == QuizAdvanceMode.auto) {
        ref
            .read(quizSessionControllerProvider(bankId, mode).notifier)
            .startAutoAdvance();
      }
    });
  }

  /// Advance to the next question (D-03, D-06).
  void _onAdvance(WidgetRef ref) {
    ref
        .read(quizSessionControllerProvider(bankId, mode).notifier)
        .advanceToNext();
  }

  /// Determine whether to show the wrong-question chip (D-15).
  ///
  /// True when the last answer was wrong AND the mode writes to the ledger
  /// (not spotcheck mode).
  bool _shouldShowWrongChip(QuizSessionState session) {
    if (session.answers.isEmpty) return false;
    final lastAnswer = session.answers.last;
    // Spotcheck mode does not write to the ledger (D-17)
    return !lastAnswer.isCorrect && session.mode != ReviewMode.spotcheck;
  }
}
