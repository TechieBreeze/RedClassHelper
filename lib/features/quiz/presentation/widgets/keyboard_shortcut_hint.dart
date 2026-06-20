import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Desktop keyboard shortcut hint -- D-06.
///
/// Shows semi-transparent text at the bottom of the quiz screen:
/// "快捷键: A B C D 选择 · 空格 提交 · → 下一题"
///
/// Only visible on desktop platforms (Windows/Linux).
/// Returns SizedBox.shrink on non-desktop.
class KeyboardShortcutHint extends StatelessWidget {
  const KeyboardShortcutHint({super.key});

  bool get _isDesktop => !kIsWeb && (Platform.isWindows || Platform.isLinux);

  @override
  Widget build(BuildContext context) {
    if (!_isDesktop) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Text(
        '快捷键: A~H 选择 · 空格 提交 · ← 上一题 · → 下一题',
        textAlign: TextAlign.center,
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    );
  }
}
