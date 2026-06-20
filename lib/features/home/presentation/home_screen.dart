// lib/features/home/presentation/home_screen.dart
// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../quiz/providers/wrong_questions_provider.dart';

/// 主页 (UI-SPEC §Layout — Home Screen)
/// Phase 2 状态: 桌面端 FAB + 启用按钮；Android 端禁用
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// 是否为桌面端（Windows 或 Linux）
  bool get _isDesktop => !kIsWeb && (Platform.isWindows || Platform.isLinux);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('红课复习'),
        actions: [
          // 设置入口 — Phase 2 实现 SettingsScreen
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
            tooltip: '设置',
          ),
        ],
      ),
      // Phase 2: 桌面端 FAB
      floatingActionButton: _isDesktop
          ? FloatingActionButton(
              onPressed: () => context.push('/import'),
              tooltip: '导入题库',
              child: const Icon(Icons.add),
            )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final EdgeInsets padding;
          final double? maxWidth;
          if (width < 600) {
            // Compact (mobile portrait)
            padding = const EdgeInsets.symmetric(horizontal: 16); // md
            maxWidth = null;
          } else if (width < 840) {
            // Medium (small tablet / narrow desktop)
            padding = const EdgeInsets.symmetric(horizontal: 24); // lg
            maxWidth = null;
          } else {
            // Expanded (desktop / large tablet)
            padding = const EdgeInsets.symmetric(horizontal: 32); // xl
            maxWidth = 720;
          }
          return Center(
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: maxWidth ?? double.infinity),
              child: SingleChildScrollView(
                padding:
                    padding.add(const EdgeInsets.symmetric(vertical: 24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const _SectionHeader(title: '题库'),
                    const SizedBox(height: 16), // md
                    _BankEmptyStateCard(isDesktop: _isDesktop),
                    const SizedBox(height: 24), // lg (section gap)
                    const _SectionHeader(title: '复习模式'),
                    const SizedBox(height: 16), // md
                    Consumer(
                      builder: (context, ref, child) {
                        final wrongCountAsync =
                            ref.watch(wrongQuestionsProvider);
                        final wrongCount = wrongCountAsync.value ?? 0;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _ModeTile(
                              title: '乱序抽题',
                              subtitle: '随机抽题，立刻判分',
                              icon: Icons.shuffle,
                              mode: 'random',
                              enabled: true,
                            ),
                            const SizedBox(height: 12),
                            _ModeTile(
                              title: '错题复习',
                              subtitle: '从错题本复习，答对即掌握',
                              icon: Icons.replay_outlined,
                              mode: 'review',
                              enabled: true,
                              badgeCount: wrongCount,
                            ),
                            const SizedBox(height: 12),
                            _ModeTile(
                              title: '错题抽查',
                              subtitle: '从错题本随机抽 10 题自测',
                              icon: Icons.bolt_outlined,
                              mode: 'spotcheck',
                              enabled: true,
                              badgeCount: wrongCount,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24), // lg
                    const _SectionHeader(title: '数据统计'),
                    const SizedBox(height: 16),
                    const _StatsEntryTile(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    // 24px / Medium (500) per UI-SPEC §Typography Heading
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }
}

class _BankEmptyStateCard extends StatelessWidget {
  const _BankEmptyStateCard({required this.isDesktop});
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/import'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16), // md
          child: Row(
            children: [
              const Icon(Icons.library_books_outlined, size: 32),
              const SizedBox(width: 16), // md
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '还没有题库',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4), // xs
                    Text(
                      '导入一份 .docx、.pdf 或 .json 题库，开始你的复习。',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // CTA: 桌面端启用，Android 禁用
              FilledButton.tonal(
                onPressed: isDesktop ? () => context.push('/import') : null,
                child: const Text('导入题库'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.mode,
    this.enabled = false,
    this.badgeCount,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String mode;
  final bool enabled;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showBadge = badgeCount != null && badgeCount! > 0;

    return Card(
      child: InkWell(
        onTap: () => context.push('/quiz/pick/$mode'),
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              child: Row(
                children: [
                  Icon(icon, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.tonal(
                    onPressed:
                        enabled ? () => context.push('/quiz/pick/$mode') : null,
                    child: const Text('开始'),
                  ),
                ],
              ),
            ),
            if (showBadge)
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: TextStyle(
                      color: colorScheme.onError,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatsEntryTile extends StatelessWidget {
  const _StatsEntryTile();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/stats'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.insights_outlined, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '数据统计',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '查看正确率与错题分布',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
