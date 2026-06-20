/// 答题设置 -- 持久化在 shared_preferences 中。
/// D-02: quiz_submit_mode ('instant' | 'confirm', 默认 'instant')
/// D-03: quiz_advance_mode ('auto' | 'manual', 默认 'auto')
class QuizSettings {
  final QuizSubmitMode submitMode;
  final QuizAdvanceMode advanceMode;

  const QuizSettings({
    this.submitMode = QuizSubmitMode.instant,
    this.advanceMode = QuizAdvanceMode.auto,
  });

  QuizSettings copyWith({
    QuizSubmitMode? submitMode,
    QuizAdvanceMode? advanceMode,
  }) {
    return QuizSettings(
      submitMode: submitMode ?? this.submitMode,
      advanceMode: advanceMode ?? this.advanceMode,
    );
  }
}

/// 提交模式 -- D-02
enum QuizSubmitMode {
  /// 点击选项即提交（默认）。
  instant,

  /// 选中后点"确认提交"按钮或按空格键提交。
  confirm,
}

/// 翻题模式 -- D-03
enum QuizAdvanceMode {
  /// 答完后 2 秒自动跳转下一题（默认）。
  auto,

  /// 手动点击"下一题"按钮或按 -> 键翻题。
  manual,
}
