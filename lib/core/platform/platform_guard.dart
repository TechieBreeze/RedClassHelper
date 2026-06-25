// lib/core/platform/platform_guard.dart
import 'package:flutter/material.dart';
import 'platform_info.dart';

class UnsupportedFeatureGuard extends StatelessWidget {
  const UnsupportedFeatureGuard({
    super.key,
    required this.requiresDesktop,
    required this.child,
    required this.fallback,
  });
  final bool requiresDesktop;
  final Widget child;
  final Widget fallback;
  @override
  Widget build(BuildContext context) {
    final info = PlatformInfo.fromContext(context);
    final matchesPlatform =
        requiresDesktop ? info.isDesktop : !info.isDesktop;
    final meetsFormFactor = requiresDesktop ? info.isExpanded : true;
    final allowed = matchesPlatform && meetsFormFactor;
    return allowed ? child : fallback;
  }
}