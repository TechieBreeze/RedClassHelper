// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bank_pick_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 所有题库的展示数据列表 -- 包含题库名称、总题数、错题数 (D-09)。
///
/// 返回 [Future<List<BankPickItem>>], 每个 item 包含:
/// - [QuestionBank] 元数据 (id, name, source, questionCount, createdAt)
/// - 该题库的总题目数 (COUNT from Questions table)
/// - 该题库的活跃错题数 (via LedgerRepository.getActiveByBank)

@ProviderFor(bankPickList)
final bankPickListProvider = BankPickListProvider._();

/// 所有题库的展示数据列表 -- 包含题库名称、总题数、错题数 (D-09)。
///
/// 返回 [Future<List<BankPickItem>>], 每个 item 包含:
/// - [QuestionBank] 元数据 (id, name, source, questionCount, createdAt)
/// - 该题库的总题目数 (COUNT from Questions table)
/// - 该题库的活跃错题数 (via LedgerRepository.getActiveByBank)

final class BankPickListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BankPickItem>>,
          List<BankPickItem>,
          FutureOr<List<BankPickItem>>
        >
    with
        $FutureModifier<List<BankPickItem>>,
        $FutureProvider<List<BankPickItem>> {
  /// 所有题库的展示数据列表 -- 包含题库名称、总题数、错题数 (D-09)。
  ///
  /// 返回 [Future<List<BankPickItem>>], 每个 item 包含:
  /// - [QuestionBank] 元数据 (id, name, source, questionCount, createdAt)
  /// - 该题库的总题目数 (COUNT from Questions table)
  /// - 该题库的活跃错题数 (via LedgerRepository.getActiveByBank)
  BankPickListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bankPickListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bankPickListHash();

  @$internal
  @override
  $FutureProviderElement<List<BankPickItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<BankPickItem>> create(Ref ref) {
    return bankPickList(ref);
  }
}

String _$bankPickListHash() => r'21409c2e2c32bdcf0649a8c0574d569fb71797c2';
