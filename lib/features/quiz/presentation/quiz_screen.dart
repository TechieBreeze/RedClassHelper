import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import '../../../core/nav/safe_nav.dart';

import 'package:redclass/data/db/database.dart';

import '../../../core/platform/platform_info.dart';
import '../../../core/platform/responsive.dart';
import '../../../core/theme.dart';
import '../models/quiz_session_state.dart';
import '../models/quiz_settings.dart';
import '../models/review_mode.dart';
import '../providers/quiz_session_controller.dart';
import '../providers/quiz_settings_provider.dart';
import 'widgets/keyboard_shortcut_hint.dart';
import 'widgets/option_card.dart';
import 'widgets/wrong_question_chip.dart';

/// Ephemeral UI-only state for selected options (single or multi-choice).
///
/// Single-choice holds 0-1 keys; multi-choice holds 0-N keys.
/// Uses [Set<String>] to support toggling for multi-choice.
/// Resets on submission or question change.
final _quizSelectedOptionProvider = StateProvider<Set<String>>((ref) => {});

/// Regex to strip inline answer markers like （A）, （ D ）, （AB）from stems.
final _inlineAnswerStripRE = RegExp(r'[（(]\s*[A-Ha-h\s]{1,24}\s*[）)]');

/// Strip inline answer from a question stem so the user doesn't see the answer.
String _stripInlineAnswer(String stem) {
  return stem.replaceAll(_inlineAnswerStripRE, '（  ）').trim();
}

/// Compute the visual state of an option card based on quiz context.
///
/// Follows the D-04 UI-SPEC color contract:
/// - Pre-submit: selected (highlighted) or normal
/// - Post-submit: correct, wrongSelected, correctUnselected, or dimmed
OptionCardState computeOptionState({
  required String optionKey,
  required List<String> correctKeys,
  required Set<String> selectedKeys,
  required bool hasSubmitted,
}) {
  if (!hasSubmitted) {
    return selectedKeys.contains(optionKey)
        ? OptionCardState.selected
        : OptionCardState.normal;
  }
  // Post-submit states
  final isCorrectOption = correctKeys.contains(optionKey);
  final isSelectedByUser = selectedKeys.contains(optionKey);

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
  const QuizScreen({
    super.key,
    required this.bankId,
    required this.mode,
    this.info,
  });

  /// The question bank ID from the route parameter.
  final String bankId;

  /// The review mode string from the route parameter (random/review/spotcheck).
  final String mode;

  /// Optional [PlatformInfo] override. When null, the screen reads from
  /// [PlatformInfo.fromContext]. Tests pass an explicit value to avoid
  /// depending on the host platform reported by `dart:io`.
  final PlatformInfo? info;

  /// Whether this is a desktop platform — sourced from [PlatformInfo].
  bool _isDesktop(BuildContext context) =>
      (info ?? PlatformInfo.fromContext(context)).isDesktop;

  /// Map from option letter to keyboard key, up to 8 options (A-H).
  static const _letterToKey = <String, LogicalKeyboardKey>{
    'A': LogicalKeyboardKey.keyA,
    'B': LogicalKeyboardKey.keyB,
    'C': LogicalKeyboardKey.keyC,
    'D': LogicalKeyboardKey.keyD,
    'E': LogicalKeyboardKey.keyE,
    'F': LogicalKeyboardKey.keyF,
    'G': LogicalKeyboardKey.keyG,
    'H': LogicalKeyboardKey.keyH,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeEnum = reviewModeFromString(mode);
    final sessionAsync = ref.watch(quizSessionControllerProvider(bankId, mode));
    final session = sessionAsync.value;
    final settings = ref.watch(quizSettingsProvider);
    final selectedKeys = ref.watch(_quizSelectedOptionProvider);

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

    // Check for saved session — show resume dialog
    final controller = ref.read(
      quizSessionControllerProvider(bankId, mode).notifier,
    );
    final pendingResume = controller.pendingResumeSession;
    if (pendingResume != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          _showResumeDialog(context, ref, pendingResume);
        }
      });
    }

    // Error state
    if (session.status == QuizStatus.error) {
      return Scaffold(
        appBar: AppBar(title: Text('${reviewModeDisplayName(modeEnum)} · 错误')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('加载题目失败，请重试', style: TextStyle(fontSize: 16)),
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
    if (session.status == QuizStatus.complete && session.totalQuestions == 0) {
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
              const Text('该题库暂无题目', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
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
          context.safePush('/quiz/$bankId/$mode/summary');
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final options = (jsonDecode(question.optionsJson) as List)
        .map((o) => Map<String, dynamic>.from(o as Map))
        .toList();
    final correctKeys = List<String>.from(
      jsonDecode(question.correctJson) as List,
    );
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
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
            tooltip: '设置',
          ),
        ],
      ),
      body: _isDesktop(context)
          ? Focus(
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
                  return KeyEventResult.ignored;
                }
                final isMultiChoice = correctKeys.length > 1;
                for (final opt in options) {
                  final letter = opt['key'] as String;
                  final key = _letterToKey[letter];
                  if (key != null && event.logicalKey == key) {
                    _onOptionTap(
                      ref,
                      letter,
                      settings,
                      hasSubmitted,
                      isMultiChoice,
                    );
                    return KeyEventResult.handled;
                  }
                }
                if (event.logicalKey == LogicalKeyboardKey.space &&
                    !hasSubmitted) {
                  _onSubmitConfirm(ref);
                  return KeyEventResult.handled;
                }
                if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                  _onPrevious(ref);
                  return KeyEventResult.handled;
                }
                if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
                    hasSubmitted) {
                  _onAdvance(ref);
                  return KeyEventResult.handled;
                }
                return KeyEventResult.handled;
              },
              child: _buildQuizBody(
                context,
                ref,
                _stripInlineAnswer(question.stem),
                options,
                correctKeys,
                selectedKeys,
                hasSubmitted,
                currentNumber,
                totalQuestions,
                settings,
                session,
              ),
            )
          : _buildQuizBody(
              context,
              ref,
              _stripInlineAnswer(question.stem),
              options,
              correctKeys,
              selectedKeys,
              hasSubmitted,
              currentNumber,
              totalQuestions,
              settings,
              session,
            ),
    );
  }

  /// Build the main quiz body via [AdaptiveLayout] (compact / medium /
  /// expanded). Each slot composes the same extracted pieces so the
  /// widgets stay in sync across form factors.
  Widget _buildQuizBody(
    BuildContext context,
    WidgetRef ref,
    String stem,
    List<Map<String, dynamic>> options,
    List<String> correctKeys,
    Set<String> selectedKeys,
    bool hasSubmitted,
    int currentNumber,
    int totalQuestions,
    QuizSettings settings,
    QuizSessionState session,
  ) {
    final isMultiChoice = correctKeys.length > 1;

    final progress = _buildProgressBar(context, currentNumber, totalQuestions);
    final stemCard = _buildStemCard(context, session, stem);
    final optionsList = _buildOptionList(
      ref,
      options,
      correctKeys,
      selectedKeys,
      hasSubmitted,
      settings,
      isMultiChoice,
      session,
    );
    final actions = _buildActionRow(
      context,
      ref,
      hasSubmitted,
      selectedKeys,
      isMultiChoice,
      settings,
      currentNumber,
      session,
    );

    return AdaptiveLayout(
      compact: (_) => KeyedSubtree(
        key: const Key('quiz_vertical_layout'),
        child: _buildVerticalLayout(
          context,
          progress,
          stemCard,
          optionsList,
          actions,
          maxWidth: null,
        ),
      ),
      medium: (_) => KeyedSubtree(
        key: const Key('quiz_vertical_layout'),
        child: _buildVerticalLayout(
          context,
          progress,
          stemCard,
          optionsList,
          actions,
          maxWidth: 720,
        ),
      ),
      expanded: (_) => KeyedSubtree(
        key: const Key('quiz_horizontal_layout'),
        child: _buildHorizontalLayout(
          context,
          progress,
          stemCard,
          optionsList,
          actions,
        ),
      ),
    );
  }

  /// Single-column layout used for compact and medium form factors.
  Widget _buildVerticalLayout(
    BuildContext context,
    Widget progress,
    Widget stemCard,
    Widget optionsList,
    Widget actions, {
    double? maxWidth,
  }) {
    final body = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          progress,
          const SizedBox(height: 20),
          stemCard,
          const SizedBox(height: 16),
          optionsList,
          actions,
        ],
      ),
    );
    if (maxWidth == null) return body;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: body,
      ),
    );
  }

  /// Two-column layout for expanded (desktop) form factors.
  /// Left column: progress + stem. Right column: options + actions +
  /// (desktop-only) keyboard shortcut hint.
  Widget _buildHorizontalLayout(
    BuildContext context,
    Widget progress,
    Widget stemCard,
    Widget optionsList,
    Widget actions,
  ) {
    final showShortcutHint = _isDesktop(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [progress, const SizedBox(height: 20), stemCard],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                optionsList,
                actions,
                if (showShortcutHint) ...[
                  const SizedBox(height: 12),
                  const KeyboardShortcutHint(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Progress bar widget (gradient with current/total indicator).
  Widget _buildProgressBar(
    BuildContext context,
    int currentNumber,
    int totalQuestions,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: heroGradient(cs, Theme.of(context).brightness),
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '$currentNumber',
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalQuestions > 0
                        ? currentNumber / totalQuestions
                        : 0,
                    minHeight: 6,
                    backgroundColor: Colors.white.withAlpha(40),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$currentNumber / $totalQuestions',
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.white.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Stem (question text) card widget.
  Widget _buildStemCard(
    BuildContext context,
    QuizSessionState session,
    String stem,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTypeChip(context, session.currentQuestion!),
          const SizedBox(height: 10),
          Text(
            stem,
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Option list widget (spread of [OptionCard]s).
  Widget _buildOptionList(
    WidgetRef ref,
    List<Map<String, dynamic>> options,
    List<String> correctKeys,
    Set<String> selectedKeys,
    bool hasSubmitted,
    QuizSettings settings,
    bool isMultiChoice,
    QuizSessionState session,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: options.map((option) {
        final key = option['key'] as String;
        final text = option['text'] as String;
        final state = computeOptionState(
          optionKey: key,
          correctKeys: correctKeys,
          selectedKeys:
              hasSubmitted && session.currentIndex < session.answers.length
              ? session.answers[session.currentIndex].givenAnswer.toSet()
              : selectedKeys,
          hasSubmitted: hasSubmitted,
        );
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: OptionCard(
            optionKey: key,
            optionText: text,
            state: state,
            onTap: () =>
                _onOptionTap(ref, key, settings, hasSubmitted, isMultiChoice),
          ),
        );
      }).toList(),
    );
  }

  /// Action row widget: confirm-submit button, wrong-question chip,
  /// next-question button.
  Widget _buildActionRow(
    BuildContext context,
    WidgetRef ref,
    bool hasSubmitted,
    Set<String> selectedKeys,
    bool isMultiChoice,
    QuizSettings settings,
    int currentNumber,
    QuizSessionState session,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Confirm submit button
        if (!hasSubmitted &&
            selectedKeys.isNotEmpty &&
            (settings.submitMode == QuizSubmitMode.confirm ||
                isMultiChoice)) ...[
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
            key: ValueKey(currentNumber),
            show: _shouldShowWrongChip(session),
          ),
        ],

        // Next button (manual advance mode, post-submit)
        if (hasSubmitted && settings.advanceMode == QuizAdvanceMode.manual) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _onAdvance(ref),
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('下一题'),
          ),
        ],
      ],
    );
  }

  /// Handle an option tap or keyboard selection (D-02).
  ///
  /// Single-choice: instant mode submits immediately, confirm mode sets selection.
  /// Multi-choice: always toggles in the set, never auto-submits.
  void _onOptionTap(
    WidgetRef ref,
    String optionKey,
    QuizSettings settings,
    bool hasSubmitted,
    bool isMultiChoice,
  ) {
    if (hasSubmitted) return; // T-04-11: guard against double-tap

    final notifier = ref.read(_quizSelectedOptionProvider.notifier);
    if (isMultiChoice) {
      // Toggle this option in the set
      final current = ref.read(_quizSelectedOptionProvider);
      final updated = Set<String>.from(current);
      if (updated.contains(optionKey)) {
        updated.remove(optionKey);
      } else {
        updated.add(optionKey);
      }
      notifier.state = updated;
    } else {
      // Single choice: select or switch
      if (settings.submitMode == QuizSubmitMode.instant) {
        notifier.state = {optionKey};
        _submitAnswer(ref, [optionKey]);
      } else {
        notifier.state = {optionKey};
      }
    }
  }

  /// Submit the confirmed answer (confirm mode Space key or button).
  void _onSubmitConfirm(WidgetRef ref) {
    final selected = ref.read(_quizSelectedOptionProvider);
    if (selected.isEmpty) return;
    _submitAnswer(ref, selected.toList());
  }

  /// Call the controller to submit the answer (D-04).
  void _submitAnswer(WidgetRef ref, List<String> optionKeys) {
    ref.read(_quizSelectedOptionProvider.notifier).state = {};
    ref
        .read(quizSessionControllerProvider(bankId, mode).notifier)
        .submitAnswer(optionKeys)
        .then((_) {
          // After submission: start auto-advance if in auto mode
          final settings = ref.read(quizSettingsProvider);
          if (settings.advanceMode == QuizAdvanceMode.auto) {
            ref
                .read(quizSessionControllerProvider(bankId, mode).notifier)
                .startAutoAdvance();
          }
        });
  }

  /// Go back to the previous question (left-arrow shortcut).
  void _onPrevious(WidgetRef ref) {
    ref
        .read(quizSessionControllerProvider(bankId, mode).notifier)
        .goToPrevious();
  }

  /// Advance to the next question (D-03, D-06).
  void _onAdvance(WidgetRef ref) {
    ref
        .read(quizSessionControllerProvider(bankId, mode).notifier)
        .advanceToNext();
  }

  /// 显示恢复上次答题进度的对话框。
  void _showResumeDialog(
    BuildContext context,
    WidgetRef ref,
    QuizSessionState saved,
  ) {
    final answered = saved.answers.length;
    final total = saved.questions.length;
    final remaining = total - answered;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.history, size: 48),
        title: const Text('发现上次未完成的答题'),
        content: Text('上次已答 $answered/$total 题，还剩 $remaining 题未答。\n是否继续上次的进度？'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(quizSessionControllerProvider(bankId, mode).notifier)
                  .discardSavedSession();
            },
            child: const Text('重新开始'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(quizSessionControllerProvider(bankId, mode).notifier)
                  .resumeSavedSession();
            },
            child: const Text('继续做题'),
          ),
        ],
      ),
    );
  }

  /// Build a small chip showing the question type (单选题/多选题/判断题).
  Widget _buildTypeChip(BuildContext context, Question question) {
    final isTrueFalse = _isTrueFalseQuestion(question);
    final (label, icon) = switch (question.type) {
      'single' =>
        isTrueFalse
            ? ('判断题', Icons.thumbs_up_down)
            : ('单选题', Icons.radio_button_checked),
      'multiple' => ('多选题', Icons.checklist),
      _ => (question.type, Icons.help_outline),
    };
    return Chip(
      avatar: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.zero,
    );
  }

  /// Detect true/false questions by options content: exactly A=对, B=错.
  bool _isTrueFalseQuestion(Question question) {
    try {
      final options = jsonDecode(question.optionsJson) as List;
      if (options.length != 2) return false;
      final texts = options.map((o) => (o as Map)['text'] as String).toSet();
      return texts.contains('对') && texts.contains('错');
    } catch (_) {
      return false;
    }
  }

  /// Determine whether to show the wrong-question chip (D-15).
  ///
  /// True when the last answer was wrong AND the mode writes to the ledger
  /// (not spotcheck mode).
  bool _shouldShowWrongChip(QuizSessionState session) {
    final idx = session.currentIndex;
    if (idx >= session.answers.length) return false;
    final answer = session.answers[idx];
    return !answer.isCorrect && session.mode != ReviewMode.spotcheck;
  }
}
