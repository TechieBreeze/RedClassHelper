// lib/core/platform/responsive.dart
import 'package:flutter/material.dart';
import 'platform_info.dart';

class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({super.key, required this.builder, this.info});
  final Widget Function(BuildContext, PlatformInfo) builder;

  /// Optional [PlatformInfo] override. When null, the builder reads from
  /// [PlatformInfo.fromContext]. Tests pass an explicit value to avoid
  /// depending on the host platform reported by `dart:io`.
  final PlatformInfo? info;

  @override
  Widget build(BuildContext context) =>
      builder(context, info ?? PlatformInfo.fromContext(context));
}

class AdaptiveLayout extends StatelessWidget {
  const AdaptiveLayout({super.key, required this.compact, this.medium, this.expanded});
  final WidgetBuilder compact;
  final WidgetBuilder? medium;
  final WidgetBuilder? expanded;
  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(builder: (_, info) {
      return switch (info.formFactor) {
        FormFactor.compact => Builder(builder: compact),
        FormFactor.medium => Builder(builder: medium ?? compact),
        FormFactor.expanded => Builder(builder: expanded ?? medium ?? compact),
      };
    });
  }
}
