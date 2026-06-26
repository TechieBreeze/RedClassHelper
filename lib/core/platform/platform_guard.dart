// lib/core/platform/platform_guard.dart
import 'package:flutter/material.dart';
import 'platform_info.dart';

class UnsupportedFeatureGuard extends StatelessWidget {
  const UnsupportedFeatureGuard({
    super.key,
    required this.requiresDesktop,
    required this.fallback,
    required this.child,
    this.info,
  });
  final bool requiresDesktop;
  final Widget child;
  final Widget fallback;

  /// Optional [PlatformInfo] override. When null, the guard reads from
  /// [PlatformInfo.fromContext]. Tests pass an explicit value to avoid
  /// depending on the host platform reported by `dart:io`.
  final PlatformInfo? info;

  @override
  Widget build(BuildContext context) {
    final effective = info ?? PlatformInfo.fromContext(context);
    final allowed = requiresDesktop
        ? effective.isDesktop
        : !effective.isDesktop;
    return allowed ? child : fallback;
  }
}
