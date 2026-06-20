// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wrong_questions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 错题总数 Stream (D-14, D-15)。
///
/// 返回 [Stream<int>] — 全局活跃错题数 (WHERE mastered_at IS NULL)。
/// 每当 LedgerRepository 中的账本状态变更 (markWrong / markMastered)，
/// 所有监听此 stream 的 widget 自动重建。
///
/// D-14: 用于主页模式卡片右上角 badge 显示。
/// D-15: 答题结束后用于判断是否需要展示"已加入错题本"反馈。
///
/// 使用 async* generator 桥接异步 DB 解析与 Stream 返回。
/// [appDatabaseProvider] 是 keepAlive:true 的 FutureProvider，
/// 所以 DB 解析在应用启动后仅执行一次。

@ProviderFor(wrongQuestions)
final wrongQuestionsProvider = WrongQuestionsProvider._();

/// 错题总数 Stream (D-14, D-15)。
///
/// 返回 [Stream<int>] — 全局活跃错题数 (WHERE mastered_at IS NULL)。
/// 每当 LedgerRepository 中的账本状态变更 (markWrong / markMastered)，
/// 所有监听此 stream 的 widget 自动重建。
///
/// D-14: 用于主页模式卡片右上角 badge 显示。
/// D-15: 答题结束后用于判断是否需要展示"已加入错题本"反馈。
///
/// 使用 async* generator 桥接异步 DB 解析与 Stream 返回。
/// [appDatabaseProvider] 是 keepAlive:true 的 FutureProvider，
/// 所以 DB 解析在应用启动后仅执行一次。

final class WrongQuestionsProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// 错题总数 Stream (D-14, D-15)。
  ///
  /// 返回 [Stream<int>] — 全局活跃错题数 (WHERE mastered_at IS NULL)。
  /// 每当 LedgerRepository 中的账本状态变更 (markWrong / markMastered)，
  /// 所有监听此 stream 的 widget 自动重建。
  ///
  /// D-14: 用于主页模式卡片右上角 badge 显示。
  /// D-15: 答题结束后用于判断是否需要展示"已加入错题本"反馈。
  ///
  /// 使用 async* generator 桥接异步 DB 解析与 Stream 返回。
  /// [appDatabaseProvider] 是 keepAlive:true 的 FutureProvider，
  /// 所以 DB 解析在应用启动后仅执行一次。
  WrongQuestionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wrongQuestionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wrongQuestionsHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return wrongQuestions(ref);
  }
}

String _$wrongQuestionsHash() => r'fe1e110f4c5c6ae7bf93be631ba2427d73f5f3bc';
