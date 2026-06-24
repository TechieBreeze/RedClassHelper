// lib/features/home/presentation/home_screen.dart
// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../../quiz/providers/bank_pick_provider.dart';
import '../../quiz/providers/wrong_questions_provider.dart';

/// 主页 — 大卡片 + 渐变 Hero + 视觉层次分明
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  bool get _isDesktop => !kIsWeb && (Platform.isWindows || Platform.isLinux);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('红课复习'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
            tooltip: '设置',
          ),
        ],
      ),
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
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                        horizontal: hPad, vertical: 20),
                    sliver: SliverList.list(
                      children: [
                        // ── Hero Banner ──
                        Consumer(
                          builder: (context, ref, _) {
                            final banks =
                                ref.watch(bankPickListProvider).value ?? [];
                            final wrong =
                                ref.watch(wrongQuestionsProvider).value ?? 0;
                            final totalQ = banks.fold<int>(
                                0, (s, b) => s + b.totalQuestions);
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

                        // ── 题库 ──
                        _SectionTitle(
                          title: '我的题库',
                          action: '导入',
                          onAction: () => context.push('/import'),
                        ),
                        const SizedBox(height: 12),
                        Consumer(
                          builder: (context, ref, _) {
                            final banksAsync =
                                ref.watch(bankPickListProvider);
                            return banksAsync.when(
                              loading: () => _LoadingBanks(),
                              error: (e, _) => _ErrorBanks(
                                msg: e.toString(),
                                onRetry: () =>
                                    ref.invalidate(bankPickListProvider),
                              ),
                              data: (banks) {
                                if (banks.isEmpty) {
                                  return _EmptyBank(
                                      isDesktop: _isDesktop);
                                }
                                return Column(
                                  children: [
                                    for (final b in banks) ...[
                                      _BankRow(item: b),
                                      const SizedBox(height: 8),
                                    ],
                                  ],
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // ── 统计入口 ──
                        _StatTile(onTap: () => context.push('/stats')),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
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
          colors: [
            cs.primary,
            cs.tertiary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '继续加油 💪',
            style: tt.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '每天复习一点点，考试轻松过',
            style: tt.bodyMedium?.copyWith(
              color: Colors.white.withAlpha(200),
            ),
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
    final cards = [
      _ActionCardData(
        title: '乱序抽题',
        subtitle: '随机出题 · 即时判分',
        icon: Icons.shuffle_rounded,
        gradient: [cs.primary, cs.primary.withAlpha(200)],
        mode: 'random',
      ),
      _ActionCardData(
        title: '错题复习',
        subtitle: wrongCount > 0 ? '$wrongCount 题待攻克' : '暂无错题',
        icon: Icons.replay_rounded,
        gradient: [cs.tertiary, cs.tertiary.withAlpha(200)],
        mode: 'review',
        badge: wrongCount,
      ),
      _ActionCardData(
        title: '错题抽查',
        subtitle: wrongCount > 0 ? '随机 10 题自测' : '暂无错题',
        icon: Icons.bolt_rounded,
        gradient: [cs.secondary, cs.secondary.withAlpha(200)],
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/quiz/pick/${data.mode}'),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: data.gradient,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Stack(
            children: [
              // 半透明大图标背景
              Positioned(
                right: -8,
                top: -8,
                child: Icon(
                  data.icon,
                  size: 80,
                  color: Colors.white.withAlpha(25),
                ),
              ),
              // 内容
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(data.icon,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            data.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data.subtitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Colors.white.withAlpha(200),
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (data.badge != null && data.badge! > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
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
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white70, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Section Title
// ══════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.action,
    this.onAction,
  });
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const Spacer(),
        if (action != null && onAction != null)
          TextButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add, size: 18),
            label: Text(action!),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  题库卡片
// ══════════════════════════════════════════════════════════════

class _BankRow extends StatelessWidget {
  const _BankRow({required this.item});
  final BankPickItem item;

  @override
  Widget build(BuildContext context) {
    final bank = item.bank;
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: () => context.push('/bank/${bank.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                child: Icon(Icons.menu_book_rounded,
                    size: 22, color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bank.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.totalQuestions} 题 · ${p.basename(bank.source)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.onSurface.withAlpha(150)),
                    ),
                  ],
                ),
              ),
              if (item.activeWrongCount > 0)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item.activeWrongCount} 错',
                    style: TextStyle(
                      color: cs.onErrorContainer,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Icon(Icons.chevron_right_rounded,
                  color: cs.outline, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBank extends StatelessWidget {
  const _EmptyBank({required this.isDesktop});
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: () => context.push('/import'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Icon(Icons.library_add_rounded,
                  size: 44, color: cs.outline),
              const SizedBox(height: 12),
              Text('还没有题库',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                '导入 .docx / .pdf / .json 开始复习',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withAlpha(150),
                    ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed:
                    isDesktop ? () => context.push('/import') : null,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('导入题库'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingBanks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (var i = 0; i < 2; i++) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            width: 140,
                            height: 14,
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            )),
                        const SizedBox(height: 8),
                        Container(
                            width: 100,
                            height: 11,
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ErrorBanks extends StatelessWidget {
  const _ErrorBanks({required this.msg, required this.onRetry});
  final String msg;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.error_outline,
                size: 32, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 8),
            Text('加载失败',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(msg,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('重试'),
            ),
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
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cs.secondaryContainer,
                      cs.secondary.withAlpha(60),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.insights_rounded,
                    size: 22, color: cs.onSecondaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '数据统计',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '查看正确率与错题分布',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: cs.onSurface.withAlpha(150),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: cs.outline, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
