// lib/core/platform/responsive.dart
import 'package:flutter/material.dart';
import 'platform_info.dart';

class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({super.key, required this.builder});
  final Widget Function(BuildContext, PlatformInfo) builder;
  @override
  Widget build(BuildContext context) => builder(context, PlatformInfo.fromContext(context));
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
