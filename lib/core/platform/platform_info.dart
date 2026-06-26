// lib/core/platform/platform_info.dart
import 'dart:io' show Platform;
import 'package:flutter/widgets.dart';

enum AppPlatform { android, ios, windows, linux, macos, web, fuchsia, unknown }

enum FormFactor { compact, medium, expanded }

class PlatformInfo {
  const PlatformInfo({required this.platform, required this.shortestSide});
  factory PlatformInfo.forTesting({
    required AppPlatform platform,
    required double shortestSide,
  }) => PlatformInfo(platform: platform, shortestSide: shortestSide);

  factory PlatformInfo.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return PlatformInfo(platform: _detect(), shortestSide: size.shortestSide);
  }

  static AppPlatform _detect() {
    if (Platform.isAndroid) return AppPlatform.android;
    if (Platform.isIOS) return AppPlatform.ios;
    if (Platform.isWindows) return AppPlatform.windows;
    if (Platform.isLinux) return AppPlatform.linux;
    if (Platform.isMacOS) return AppPlatform.macos;
    return AppPlatform.web;
  }

  final AppPlatform platform;
  final double shortestSide;

  FormFactor get formFactor {
    if (shortestSide < 600) return FormFactor.compact;
    if (shortestSide < 840) return FormFactor.medium;
    return FormFactor.expanded;
  }

  bool get isMobile =>
      platform == AppPlatform.android || platform == AppPlatform.ios;
  bool get isDesktop =>
      platform == AppPlatform.windows ||
      platform == AppPlatform.linux ||
      platform == AppPlatform.macos;
  bool get supportsLlm => isDesktop;
  bool get isCompact => formFactor == FormFactor.compact;
  bool get isExpanded => formFactor == FormFactor.expanded;
}
