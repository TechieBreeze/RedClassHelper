// lib/core/platform/responsive.dart
import 'package:flutter/material.dart';
import 'platform_info.dart';

/// Design tokens shared across responsive screens (Tasks 11-15).
///
/// Use these instead of hardcoded numbers so a single PR can tune reading
/// width, wrap gutter, and page padding globally.

/// Maximum content width on medium form factors (tablets, narrow laptops).
/// Matches `AdaptiveLayout`'s medium slot cap.
const double kMediumReadingWidth = 720.0;

/// Maximum content width on expanded form factors (desktops).
/// Matches `AdaptiveLayout`'s expanded slot cap.
const double kExpandedReadingWidth = 960.0;

/// Spacing between items in a `Wrap` (both `spacing` and `runSpacing`).
const double kWrapGutter = 12.0;

/// Standard horizontal page padding (left/right gutters for `ListView` /
/// `SingleChildScrollView` content).
const double kPageHorizontalPadding = 16.0;

/// Standard vertical page padding (top/bottom gutters for scrolling content).
const double kPageVerticalPadding = 8.0;

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
  const AdaptiveLayout({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
  });
  final WidgetBuilder compact;
  final WidgetBuilder? medium;
  final WidgetBuilder? expanded;
  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (_, info) {
        return switch (info.formFactor) {
          FormFactor.compact => Builder(builder: compact),
          FormFactor.medium => Builder(builder: medium ?? compact),
          FormFactor.expanded => Builder(
            builder: expanded ?? medium ?? compact,
          ),
        };
      },
    );
  }
}
