import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../../../data/db/database.dart';
import '../../export/services/json_export_service.dart';

/// 题库详情页 — 显示题库元数据、"导出 JSON"按钮、"开始复习"入口 (D-03, D-04, D-14)
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text('数据库加载失败', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(error.toString(), style: Theme.of(context).textTheme.bodyMedium),
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
    return Scaffold(
      appBar: AppBar(title: Text(bank.name)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final double hPad;
          final double? maxWidth;
          if (width < 600) {
            hPad = 16;
            maxWidth = null;
          } else if (width < 840) {
            hPad = 24;
            maxWidth = null;
          } else {
            hPad = 32;
            maxWidth = 720;
          }
          return Center(
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: maxWidth ?? double.infinity),
              child: SingleChildScrollView(
                padding:
                    EdgeInsets.symmetric(horizontal: hPad, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionHeader('题库信息'),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bank.name,
                              style:
                                  Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.description_outlined,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  p.basename(bank.source),
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.quiz_outlined, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '${questions.length} 题',
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _SectionHeader('操作'),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () =>
                          _exportJson(context, ref, bank, questions),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('导出 JSON'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: () => context.push('/quiz/pick/random'),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('开始复习'),
                    ),
                  ],
                ),
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
    // Sanitize filename: strip path separators to prevent path traversal (T-05-04)
    final safeName = bank.name.replaceAll(RegExp(r'[/\\:]'), '_');
    final outputPath = await FilePicker.saveFile(
      dialogTitle: '导出 JSON 题库',
      fileName: '$safeName.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (outputPath == null || !context.mounted) return; // User cancelled

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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.headlineSmall);
  }
}
