// lib/features/home/presentation/home_screen.dart
// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 主页 (UI-SPEC §Layout — Home Screen)
/// Phase 1 状态: 题库空态 + 3 模式入口 + 数据统计入口
/// 所有 mode tile 的 CTA "开始" 按钮在 Phase 1 是 disabled (onPressed: null)
/// 整张卡片 tap 区域用 InkWell 包裹, 触发 context.go 跳转
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('红课复习'),
        actions: [
          // 设置入口 — Phase 2 实现 SettingsScreen
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
            tooltip: '设置',
          ),
        ],
      ),
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
                    const _BankEmptyStateCard(),
                    const SizedBox(height: 24), // lg (section gap)
                    const _SectionHeader(title: '复习模式'),
                    const SizedBox(height: 16), // md
                    const _ModeTile(
                      title: '乱序抽题',
                      subtitle: '随机抽题，立刻判分',
                      icon: Icons.shuffle,
                      mode: 'random',
                    ),
                    const SizedBox(height: 12), // sm (between tiles)
                    const _ModeTile(
                      title: '错题复习',
                      subtitle: '从错题本复习，答对即掌握',
                      icon: Icons.replay_outlined,
                      mode: 'review',
                    ),
                    const SizedBox(height: 12),
                    const _ModeTile(
                      title: '错题抽查',
                      subtitle: '从错题本随机抽 10 题自测',
                      icon: Icons.bolt_outlined,
                      mode: 'spotcheck',
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
  const _BankEmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.go('/import'),
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
              // CTA disabled in Phase 1 (UI-SPEC §Disabled button — M3 native)
              FilledButton.tonal(
                onPressed: null,
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
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String mode;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.go('/quiz/new/$mode'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // md x md
          child: Row(
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 16), // md
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4), // xs
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              FilledButton.tonal(
                onPressed: null, // disabled in Phase 1
                child: const Text('开始'),
              ),
            ],
          ),
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
        onTap: () => context.go('/stats'),
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
