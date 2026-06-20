import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quiz_settings.dart';

part 'quiz_settings_provider.g.dart';

/// SharedPreferences 实例 -- 在 main() 中预初始化, 通过 ProviderScope override 注入。
///
/// 避免 shared_preferences 的异步初始化竞态 (RESEARCH.md Pitfall 4)。
/// 使用模式与 [pathResolverProvider] 相同: 预初始化 + override。
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  );
}

/// 答题设置 Notifier -- D-02, D-03, D-07。
///
/// 从 shared_preferences 读取 quiz_submit_mode (默认 'instant') 和
/// quiz_advance_mode (默认 'auto')。
/// 写入时同步持久化到 shared_preferences。
@riverpod
class QuizSettingsNotifier extends _$QuizSettingsNotifier {
  @override
  QuizSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final submitModeStr = prefs.getString('quiz_submit_mode') ?? 'instant';
    final advanceModeStr = prefs.getString('quiz_advance_mode') ?? 'auto';
    return QuizSettings(
      submitMode: submitModeStr == 'confirm'
          ? QuizSubmitMode.confirm
          : QuizSubmitMode.instant,
      advanceMode: advanceModeStr == 'manual'
          ? QuizAdvanceMode.manual
          : QuizAdvanceMode.auto,
    );
  }

  /// 设置提交模式并持久化到 shared_preferences (D-02, D-07)。
  void setSubmitMode(QuizSubmitMode mode) {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString(
      'quiz_submit_mode',
      mode == QuizSubmitMode.confirm ? 'confirm' : 'instant',
    );
    state = state.copyWith(submitMode: mode);
  }

  /// 设置翻题模式并持久化到 shared_preferences (D-03, D-07)。
  void setAdvanceMode(QuizAdvanceMode mode) {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString(
      'quiz_advance_mode',
      mode == QuizAdvanceMode.manual ? 'manual' : 'auto',
    );
    state = state.copyWith(advanceMode: mode);
  }
}
