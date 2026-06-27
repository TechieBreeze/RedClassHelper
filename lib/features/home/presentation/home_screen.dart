// lib/features/home/presentation/home_screen.dart
// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/adaptive_scaffold.dart';
import '../../../core/widgets/hoverable_card.dart';
import '../../quiz/providers/bank_pick_provider.dart';
import '../../quiz/providers/wrong_questions_provider.dart';

/// 主页 — 大卡片 + 渐变 Hero + 视觉层次分明
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: '红课复习',
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.push('/settings'),
          tooltip: '设置',
        ),
      ],
      drawer: const _HomeNavDrawer(),
      floatingActionButton: null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final double hPad;
          final double? maxW;
          if (width < 600) {
            hPad = 16;
            maxW = null;
          } else if (width < 840) {
            hPad = 24;
            maxW = null;
          } else {
            hPad = 32;
            maxW = 720;
          }
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW ?? double.infinity),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Hero Banner ──
                    Consumer(
                      builder: (context, ref, _) {
                        final banks =
                            ref.watch(bankPickListProvider).value ?? [];
                        final wrong =
                            ref.watch(wrongQuestionsProvider).value ?? 0;
                        final totalQ = banks.fold<int>(
                          0,
                          (s, b) => s + b.totalQuestions,
                        );
                        return _HeroBanner(
                          bankCount: banks.length,
                          questionCount: totalQ,
                          wrongCount: wrong,
                        );
                      },
                    ),
                    const SizedBox(height: 28),

                    // ── 三个模式大卡 ──
                    Consumer(
                      builder: (context, ref, _) {
                        final wrong =
                            ref.watch(wrongQuestionsProvider).value ?? 0;
                        return _ActionCards(wrongCount: wrong);
                      },
                    ),
                    const SizedBox(height: 28),

                    // ── 题库 + 统计 入口 ──
                    Consumer(
                      builder: (context, ref, _) {
                        final banksAsync = ref.watch(bankPickListProvider);
                        final bankCount = banksAsync.value?.length ?? 0;
                        final questionCount = banksAsync.value?.fold<int>(
                              0,
                              (s, b) => s + b.totalQuestions,
                            ) ??
                            0;
                        return Column(
                          children: [
                            _BanksEntryTile(
                              bankCount: bankCount,
                              questionCount: questionCount,
                            ),
                            const SizedBox(height: 12),
                            _StatTile(onTap: () => context.push('/stats')),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),
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

// ══════════════════════════════════════════════════════════════
//  Hero Banner
// ══════════════════════════════════════════════════════════════

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.bankCount,
    required this.questionCount,
    required this.wrongCount,
  });

  final int bankCount;
  final int questionCount;
  final int wrongCount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: heroGradient(cs, Theme.of(context).brightness),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: heroShadowColor(cs, Theme.of(context).brightness),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '继续加油',
                style: tt.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.local_fire_department_rounded,
                color: Colors.white,
                size: 26,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '每天复习一点点，考试轻松过',
            style: tt.bodyMedium?.copyWith(color: Colors.white.withAlpha(200)),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _HeroStat(value: '$bankCount', label: '题库'),
              const SizedBox(width: 24),
              _HeroStat(value: '$questionCount', label: '总题'),
              if (wrongCount > 0) ...[
                const SizedBox(width: 24),
                _HeroStat(
                  value: '$wrongCount',
                  label: '错题',
                  valueColor: Colors.white,
                  highlight: true,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.value,
    required this.label,
    this.valueColor,
    this.highlight = false,
  });

  final String value;
  final String label;
  final Color? valueColor;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: valueColor ?? Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Colors.white.withAlpha(highlight ? 220 : 170),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  三个模式动作卡
// ══════════════════════════════════════════════════════════════

class _ActionCards extends StatelessWidget {
  const _ActionCards({required this.wrongCount});
  final int wrongCount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = cs.primary;
    final cards = [
      _ActionCardData(
        title: '乱序抽题',
        subtitle: '随机出题 · 即时判分',
        icon: Icons.shuffle_rounded,
        gradient: isDark
            ? [p.withAlpha(80), p.withAlpha(60)]
            : [p, p.withAlpha(200)],
        mode: 'random',
      ),
      _ActionCardData(
        title: '错题复习',
        subtitle: wrongCount > 0 ? '$wrongCount 题待攻克' : '暂无错题',
        icon: Icons.replay_rounded,
        gradient: isDark
            ? [p.withAlpha(110), p.withAlpha(80)]
            : [p.withAlpha(200), p.withAlpha(160)],
        mode: 'review',
        badge: wrongCount,
      ),
      _ActionCardData(
        title: '错题抽查',
        subtitle: wrongCount > 0 ? '随机 10 题自测' : '暂无错题',
        icon: Icons.bolt_rounded,
        gradient: isDark
            ? [p.withAlpha(140), p.withAlpha(100)]
            : [p.withAlpha(160), p.withAlpha(120)],
        mode: 'spotcheck',
        badge: wrongCount,
      ),
    ];

    return Column(
      children: [
        for (final c in cards) ...[
          _ActionCard(data: c),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ActionCardData {
  const _ActionCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.mode,
    this.badge,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final String mode;
  final int? badge;
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.data});
  final _ActionCardData data;

  @override
  Widget build(BuildContext context) {
    return HoverableCard(
      onTap: () => context.push('/quiz/pick/${data.mode}'),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: data.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -8,
              top: -8,
              child: Icon(
                data.icon,
                size: 80,
                color: Colors.white.withAlpha(25),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(data.icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          data.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data.subtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.white.withAlpha(200)),
                        ),
                      ],
                    ),
                  ),
                  if (data.badge != null && data.badge! > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${data.badge}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  if (data.badge == null || data.badge == 0)
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white70,
                      size: 16,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  题库入口卡 (主页只显示入口，列表跳转 /banks)
// ══════════════════════════════════════════════════════════════

class _BanksEntryTile extends StatelessWidget {
  const _BanksEntryTile({
    required this.bankCount,
    required this.questionCount,
  });

  final int bankCount;
  final int questionCount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final subtitle = bankCount == 0
        ? '导入题库开始复习'
        : '$bankCount 个题库 · 共 $questionCount 道题';
    return HoverableCard(
      onTap: () => context.push('/banks'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primaryContainer, cs.primary.withAlpha(60)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.library_books_rounded,
                size: 22,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '我的题库',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withAlpha(150),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: cs.outline, size: 20),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  统计入口
// ══════════════════════════════════════════════════════════════

class _StatTile extends StatelessWidget {
  const _StatTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return HoverableCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.secondaryContainer, cs.secondary.withAlpha(60)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.insights_rounded,
                size: 22,
                color: cs.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '数据统计',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '查看正确率与错题分布',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withAlpha(150),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: cs.outline, size: 20),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Navigation drawer / side rail
// ══════════════════════════════════════════════════════════════

class _HomeNavDrawer extends StatelessWidget {
  const _HomeNavDrawer();

  static const _items = <_NavItem>[
    _NavItem(route: '/', icon: Icons.home_outlined, label: '首页'),
    _NavItem(route: '/banks', icon: Icons.library_books_outlined, label: '我的题库'),
    _NavItem(route: '/import', icon: Icons.upload_file_outlined, label: '导入题库'),
    _NavItem(route: '/stats', icon: Icons.insights_outlined, label: '数据统计'),
    _NavItem(route: '/settings', icon: Icons.settings_outlined, label: '设置'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLow,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Text(
                '红课复习',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            for (final item in _items)
              ListTile(
                leading: Icon(item.icon),
                title: Text(item.label),
                onTap: () {
                  if (item.route == '/') {
                    Navigator.of(context).maybePop();
                  } else {
                    context.push(item.route);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.route,
    required this.icon,
    required this.label,
  });
  final String route;
  final IconData icon;
  final String label;
}
