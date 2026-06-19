// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paths.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pathResolver)
final pathResolverProvider = PathResolverProvider._();

final class PathResolverProvider
    extends
        $FunctionalProvider<
          AsyncValue<PathResolver>,
          PathResolver,
          FutureOr<PathResolver>
        >
    with $FutureModifier<PathResolver>, $FutureProvider<PathResolver> {
  PathResolverProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pathResolverProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pathResolverHash();

  @$internal
  @override
  $FutureProviderElement<PathResolver> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PathResolver> create(Ref ref) {
    return pathResolver(ref);
  }
}

String _$pathResolverHash() => r'163d1adb650a6ef9545e4053106a601e321c6d9f';
