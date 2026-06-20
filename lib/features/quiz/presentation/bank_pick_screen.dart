// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/bank_pick_provider.dart';

/// 题库选择页 —— 每次进入答题前都必须选择题库 (D-08)。
///
/// 显示所有题库的名称、题目总数、错题数。
/// 空题库置灰不可选。仅桌面端可用。
class BankPickerScreen extends ConsumerWidget {
  const BankPickerScreen({super.key, required this.mode});

  /// 复习模式字符串（来自 GoRouter 路径参数）。
  final String mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 平台守卫：仅桌面端可用
    if (!(Platform.isWindows || Platform.isLinux) && !kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text('选择题库')),
        body: const Center(
          child: Text('答题功能仅支持桌面端 (Windows/Linux)'),
        ),
      );
    }

    final bankListAsync = ref.watch(bankPickListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('选择题库')),
      body: _buildBody(context, bankListAsync),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncValue<List<BankPickItem>> bankListAsync,
  ) {
    // 加载中
    if (bankListAsync.isLoading) {
      return const Column(
        children: [
          LinearProgressIndicator(),
          Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      );
    }

    // 错误状态
    if (bankListAsync.hasError) {
      // Show SnackBar for error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('加载题库列表失败: ${bankListAsync.error}'),
              action: SnackBarAction(
                label: '重试',
                onPressed: () {
                  // Invalidate to trigger a rebuild/retry
                  final container = ProviderScope.containerOf(context);
                  container.invalidate(bankPickListProvider);
                },
              ),
            ),
          );
        }
      });
      return const Center(child: Text('加载失败'));
    }

    final banks = bankListAsync.value ?? [];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BankPickSectionHeader(),
                  const SizedBox(height: 16),
                  if (banks.isEmpty) _buildEmptyState(context),
                  if (banks.isNotEmpty)
                    ...banks.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _BankCard(
                          item: item,
                          mode: mode,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('暂无题库', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.go('/import'),
            child: const Text('导入题库'),
          ),
        ],
      ),
    );
  }
}

class _BankPickSectionHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      '选择一个题库',
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }
}

class _BankCard extends StatelessWidget {
  const _BankCard({required this.item, required this.mode});

  final BankPickItem item;
  final String mode;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Opacity(
      opacity: item.isEmpty ? 0.4 : 1.0,
      child: Card(
        child: InkWell(
          onTap: item.isEmpty ? null : () => context.go('/quiz/${item.bank.id}/$mode'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.library_books_outlined, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.bank.name, style: textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        item.isEmpty
                            ? 'N/A'
                            : '${item.totalQuestions} 题    错题: ${item.activeWrongCount}',
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (!item.isEmpty) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.chevron_right),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
