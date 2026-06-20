// lib/features/models/presentation/settings_screen.dart
// ── Settings screen ──
// Shows quiz settings toggles (desktop-only) and model management entry.
// Android shows minimal placeholder (full settings in Phase 6).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../quiz/models/quiz_settings.dart';
import '../../quiz/providers/quiz_settings_provider.dart';

/// Settings screen.
///
/// Desktop: shows "答题设置" section with submit/advance toggles +
/// "模型管理" ListTile navigating to /settings/models.
/// Android: placeholder (Phase 6 will add more entries).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = Platform.isWindows || Platform.isLinux;
    final settings = ref.watch(quizSettingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final EdgeInsets padding;
          final double? maxWidth;
          if (width < 600) {
            padding = const EdgeInsets.symmetric(horizontal: 16);
            maxWidth = null;
          } else if (width < 840) {
            padding = const EdgeInsets.symmetric(horizontal: 24);
            maxWidth = null;
          } else {
            padding = const EdgeInsets.symmetric(horizontal: 32);
            maxWidth = 720;
          }
          return Center(
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: maxWidth ?? double.infinity),
              child: ListView(
                padding: padding,
                children: [
                  if (isDesktop) ...[
                    // Quiz settings section (D-07)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '答题设置',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('点击即提交'),
                      subtitle: const Text('关闭后需点击提交按钮确认答案'),
                      value:
                          settings.submitMode == QuizSubmitMode.instant,
                      onChanged: (value) {
                        ref
                            .read(quizSettingsNotifierProvider.notifier)
                            .setSubmitMode(
                              value
                                  ? QuizSubmitMode.instant
                                  : QuizSubmitMode.confirm,
                            );
                      },
                    ),
                    SwitchListTile(
                      title: const Text('自动翻题'),
                      subtitle: const Text('关闭后需手动点击或按键跳转下一题'),
                      value: settings.advanceMode == QuizAdvanceMode.auto,
                      onChanged: (value) {
                        ref
                            .read(quizSettingsNotifierProvider.notifier)
                            .setAdvanceMode(
                              value
                                  ? QuizAdvanceMode.auto
                                  : QuizAdvanceMode.manual,
                            );
                      },
                    ),
                    const Divider(height: 32),
                    ListTile(
                      leading: const Icon(Icons.psychology),
                      title: const Text('模型管理'),
                      subtitle: const Text('查看已安装模型、下载推荐模型'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/settings/models'),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
