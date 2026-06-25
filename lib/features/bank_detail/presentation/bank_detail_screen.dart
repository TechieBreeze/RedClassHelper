import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../../../core/theme.dart';
import '../../../core/widgets/hoverable_card.dart';
import '../../../data/db/database.dart';
import '../../export/services/json_export_service.dart';

/// 题库详情页
class BankDetailScreen extends ConsumerWidget {
  const BankDetailScreen({super.key, required this.bankId});
  final String bankId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return dbAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('题库详情')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('题库详情')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text('数据库加载失败',
                  style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      ),
      data: (db) => _buildContent(context, ref, db),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, AppDatabase db) {
    return FutureBuilder<({QuestionBank bank, List<Question> questions})>(
      future: _loadBankData(db),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('题库详情')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('题库详情')),
            body: const Center(child: Text('题库不存在')),
          );
        }
        final (:bank, :questions) = snapshot.data!;
        return _buildScaffold(context, ref, bank, questions);
      },
    );
  }

  Future<({QuestionBank bank, List<Question> questions})> _loadBankData(
    AppDatabase db,
  ) async {
    final bank = await (db.select(db.questionBanks)
      ..where((b) => b.id.equals(bankId))
    ).getSingle();
    final questions = await (db.select(db.questions)
      ..where((q) => q.bankId.equals(bankId))
    ).get();
    return (bank: bank, questions: questions);
  }

  Scaffold _buildScaffold(
    BuildContext context,
    WidgetRef ref,
    QuestionBank bank,
    List<Question> questions,
  ) {
    final cs = Theme.of(context).colorScheme;

    // Count by type
    final singleCount = questions.where((q) => q.type == 'single').length;
    final multiCount = questions.where((q) => q.type == 'multiple').length;

    return Scaffold(
      appBar: AppBar(
        title: Text(bank.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
            tooltip: '设置',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                children: [
                  // ── Hero banner ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: heroGradient(cs, Theme.of(context).brightness),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withAlpha(50),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bank.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _DetailChip(
                                icon: Icons.description_outlined,
                                text: p.basename(bank.source)),
                            const SizedBox(width: 10),
                            _DetailChip(
                                icon: Icons.quiz_outlined,
                                text: '${questions.length} 题'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Type breakdown ──
                  Text(
                    '题目构成',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _TypeCard(
                          label: '单选题',
                          count: singleCount,
                          total: questions.length,
                          icon: Icons.radio_button_checked,
                          color: cs.primaryContainer,
                          iconColor: cs.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TypeCard(
                          label: '多选题',
                          count: multiCount,
                          total: questions.length,
                          icon: Icons.checklist,
                          color: cs.secondaryContainer,
                          iconColor: cs.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Actions ──
                  Text(
                    '操作',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  HoverableCard(
                    onTap: () =>
                        context.go('/quiz/$bankId/random'),
                    child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [cs.primary, cs.primary.withAlpha(200)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.play_arrow_rounded,
                                  color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('开始复习',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text('乱序抽题，即时判分',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: cs.onSurface.withAlpha(150))),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                color: cs.outline, size: 20),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  HoverableCard(
                    onTap: () => _exportJson(context, ref, bank, questions),
                    child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: cs.secondaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.upload_file_rounded,
                                  color: cs.onSecondaryContainer, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('导出 JSON',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text('分享给其他人导入使用',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: cs.onSurface.withAlpha(150))),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                color: cs.outline, size: 20),
                          ],
                        ),
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

  Future<void> _exportJson(
    BuildContext context,
    WidgetRef ref,
    QuestionBank bank,
    List<Question> questions,
  ) async {
    final safeName = bank.name.replaceAll(RegExp(r'[/\\:]'), '_');
    final outputPath = await FilePicker.saveFile(
      dialogTitle: '导出 JSON 题库',
      fileName: '$safeName.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (outputPath == null || !context.mounted) return;

    try {
      final jsonData = bankToUserJson(bank, questions);
      final file = File(outputPath);
      await file.writeAsString(jsonEncode(jsonData));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已导出到 ${p.basename(outputPath)}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导出失败: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withAlpha(220)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withAlpha(220),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.label,
    required this.count,
    required this.total,
    required this.icon,
    required this.color,
    required this.iconColor,
  });

  final String label;
  final int count;
  final int total;
  final IconData icon;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rate = total > 0 ? (count / total) : 0.0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(height: 10),
            Text(
              '$count',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: rate,
                minHeight: 4,
                backgroundColor: cs.surfaceContainerHighest,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
