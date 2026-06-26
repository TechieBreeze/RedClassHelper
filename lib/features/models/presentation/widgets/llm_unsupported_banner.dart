// lib/features/models/presentation/widgets/llm_unsupported_banner.dart
// ── LlmUnsupportedBanner ──
// Shown on platforms that don't support on-device LLM (Android/iOS/web).
// Returns SizedBox.shrink() on desktop platforms so the layout stays clean.

import 'package:flutter/material.dart';

import '../../../../core/platform/platform_info.dart';

class LlmUnsupportedBanner extends StatelessWidget {
  const LlmUnsupportedBanner({super.key, this.info});

  /// Optional [PlatformInfo] override. When null, the banner reads from
  /// [PlatformInfo.fromContext]. Tests pass an explicit value to avoid
  /// depending on the host platform reported by `dart:io`.
  final PlatformInfo? info;

  @override
  Widget build(BuildContext context) {
    final effective = info ?? PlatformInfo.fromContext(context);
    if (effective.supportsLlm) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return MaterialBanner(
      backgroundColor: scheme.errorContainer,
      leading: Icon(Icons.info_outline, color: scheme.onErrorContainer),
      content: const Text('当前平台不支持本地 LLM 解析。请使用桌面端或回退到启发式解析。'),
      actions: [
        TextButton(
          onPressed: () =>
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
          child: const Text('知道了'),
        ),
      ],
    );
  }
}
