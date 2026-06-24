// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_session_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 答题会话控制器 — 管理整个答题生命周期 (D-01 ~ D-06, D-16, D-17)。
///
/// 拥有题目队列、当前索引、已提交答案、耗时统计和自动翻题计时器。
/// 所有 DB 写入委托给 [LedgerRepository] 以保证原子性 (D-16)。
///
/// 支持会话持久化：答题过程中自动保存进度到 SharedPreferences，
/// 退出后再次进入可恢复上次的答题状态。

@ProviderFor(QuizSessionController)
final quizSessionControllerProvider = QuizSessionControllerFamily._();

/// 答题会话控制器 — 管理整个答题生命周期 (D-01 ~ D-06, D-16, D-17)。
///
/// 拥有题目队列、当前索引、已提交答案、耗时统计和自动翻题计时器。
/// 所有 DB 写入委托给 [LedgerRepository] 以保证原子性 (D-16)。
///
/// 支持会话持久化：答题过程中自动保存进度到 SharedPreferences，
/// 退出后再次进入可恢复上次的答题状态。
final class QuizSessionControllerProvider
    extends $AsyncNotifierProvider<QuizSessionController, QuizSessionState> {
  /// 答题会话控制器 — 管理整个答题生命周期 (D-01 ~ D-06, D-16, D-17)。
  ///
  /// 拥有题目队列、当前索引、已提交答案、耗时统计和自动翻题计时器。
  /// 所有 DB 写入委托给 [LedgerRepository] 以保证原子性 (D-16)。
  ///
  /// 支持会话持久化：答题过程中自动保存进度到 SharedPreferences，
  /// 退出后再次进入可恢复上次的答题状态。
  QuizSessionControllerProvider._({
    required QuizSessionControllerFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'quizSessionControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$quizSessionControllerHash();

  @override
  String toString() {
    return r'quizSessionControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  QuizSessionController create() => QuizSessionController();

  @override
  bool operator ==(Object other) {
    return other is QuizSessionControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$quizSessionControllerHash() =>
    r'15004f061ae6aac8adf24a8cee319a5a2d4e2495';

/// 答题会话控制器 — 管理整个答题生命周期 (D-01 ~ D-06, D-16, D-17)。
///
/// 拥有题目队列、当前索引、已提交答案、耗时统计和自动翻题计时器。
/// 所有 DB 写入委托给 [LedgerRepository] 以保证原子性 (D-16)。
///
/// 支持会话持久化：答题过程中自动保存进度到 SharedPreferences，
/// 退出后再次进入可恢复上次的答题状态。

final class QuizSessionControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          QuizSessionController,
          AsyncValue<QuizSessionState>,
          QuizSessionState,
          FutureOr<QuizSessionState>,
          (String, String)
        > {
  QuizSessionControllerFamily._()
    : super(
        retry: null,
        name: r'quizSessionControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 答题会话控制器 — 管理整个答题生命周期 (D-01 ~ D-06, D-16, D-17)。
  ///
  /// 拥有题目队列、当前索引、已提交答案、耗时统计和自动翻题计时器。
  /// 所有 DB 写入委托给 [LedgerRepository] 以保证原子性 (D-16)。
  ///
  /// 支持会话持久化：答题过程中自动保存进度到 SharedPreferences，
  /// 退出后再次进入可恢复上次的答题状态。

  QuizSessionControllerProvider call(String bankId, String modeStr) =>
      QuizSessionControllerProvider._(argument: (bankId, modeStr), from: this);

  @override
  String toString() => r'quizSessionControllerProvider';
}

/// 答题会话控制器 — 管理整个答题生命周期 (D-01 ~ D-06, D-16, D-17)。
///
/// 拥有题目队列、当前索引、已提交答案、耗时统计和自动翻题计时器。
/// 所有 DB 写入委托给 [LedgerRepository] 以保证原子性 (D-16)。
///
/// 支持会话持久化：答题过程中自动保存进度到 SharedPreferences，
/// 退出后再次进入可恢复上次的答题状态。

abstract class _$QuizSessionController
    extends $AsyncNotifier<QuizSessionState> {
  late final _$args = ref.$arg as (String, String);
  String get bankId => _$args.$1;
  String get modeStr => _$args.$2;

  FutureOr<QuizSessionState> build(String bankId, String modeStr);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<QuizSessionState>, QuizSessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<QuizSessionState>, QuizSessionState>,
              AsyncValue<QuizSessionState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
