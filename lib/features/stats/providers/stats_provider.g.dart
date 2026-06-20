// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Returns aggregated per-bank statistics with per-mode breakdown.
///
/// Recomputes on each visit (no keepAlive) to ensure freshness after
/// quiz answers modify attempt data.

@ProviderFor(bankStatsList)
final bankStatsListProvider = BankStatsListProvider._();

/// Returns aggregated per-bank statistics with per-mode breakdown.
///
/// Recomputes on each visit (no keepAlive) to ensure freshness after
/// quiz answers modify attempt data.

final class BankStatsListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BankStats>>,
          List<BankStats>,
          FutureOr<List<BankStats>>
        >
    with $FutureModifier<List<BankStats>>, $FutureProvider<List<BankStats>> {
  /// Returns aggregated per-bank statistics with per-mode breakdown.
  ///
  /// Recomputes on each visit (no keepAlive) to ensure freshness after
  /// quiz answers modify attempt data.
  BankStatsListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bankStatsListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bankStatsListHash();

  @$internal
  @override
  $FutureProviderElement<List<BankStats>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<BankStats>> create(Ref ref) {
    return bankStatsList(ref);
  }
}

String _$bankStatsListHash() => r'abeb598c9a98a302f16d1bdb0670bd7e1d45b5d2';
