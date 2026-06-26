import 'dart:io';

import '../lib/features/import/extraction/docx_extractor.dart';
import '../lib/features/import/parsing/heuristic_parser.dart';
import '../lib/features/import/parsing/parse_candidate.dart';

void main() async {
  final parser = HeuristicParser();
  final path = 'doc/example/习近平新时代中国特色社会主义思想概论题库（2026年春季学期）5月28日修订.docx';
  final file = File(path);
  if (!await file.exists()) {
    print('Not found: $path');
    return;
  }

  print('═══ DOCX 真实题库: 习近平新时代中国特色社会主义思想概论题库 ═══\n');

  final text = await extractDocxText(path);

  print('提取: ${text.length} 字符, ${text.split('\n').length} 行');
  print('前500字预览:');
  print(text.substring(0, text.length < 500 ? text.length : 500));
  print('');

  final candidates = parser.parse(text);
  print('解析题目: ${candidates.length} 题\n');

  // Stats
  final typeCounts = <CandidateType, int>{};
  for (final c in candidates) {
    typeCounts[c.candidateType] = (typeCounts[c.candidateType] ?? 0) + 1;
  }
  print('── 统计 ──');
  print(
    '题型: ${typeCounts.entries.map((e) => '${e.key.name}:${e.value}').join(', ')}',
  );
  final withAns = candidates.where((c) => c.answer.isNotEmpty).length;
  final withExpl = candidates.where((c) => c.explanation.isNotEmpty).length;
  final withOpts = candidates.where((c) => c.options.isNotEmpty).length;
  final lowConf = candidates.where((c) => c.confidence < 0.5).length;
  print(
    '有答案: $withAns/${candidates.length}  有解析: $withExpl/${candidates.length}  有选项: $withOpts/${candidates.length}',
  );
  print('低置信度: $lowConf/${candidates.length}');
  if (candidates.isNotEmpty) {
    final avg =
        candidates.map((c) => c.confidence).reduce((a, b) => a + b) /
        candidates.length;
    print('平均置信度: ${avg.toStringAsFixed(2)}');
  }

  // Print first 20
  print('\n── 前20题 ──');
  for (var i = 0; i < candidates.length && i < 20; i++) {
    final c = candidates[i];
    final t = c.title.length > 50 ? '${c.title.substring(0, 50)}...' : c.title;
    print(
      '  [$i] ${c.candidateType.name} | ans="${c.answer}" | opts=${c.options.length} | conf=${c.confidence.toStringAsFixed(2)}',
    );
    print('      "$t"');
    if (c.explanation.isNotEmpty) {
      final e = c.explanation.length > 60
          ? '${c.explanation.substring(0, 60)}...'
          : c.explanation;
      print('      解析: "$e"');
    }
  }

  // Print last 5
  if (candidates.length > 20) {
    print('\n── 末5题 ──');
    for (var i = candidates.length - 5; i < candidates.length; i++) {
      final c = candidates[i];
      final t = c.title.length > 50
          ? '${c.title.substring(0, 50)}...'
          : c.title;
      print(
        '  [$i] ${c.candidateType.name} | ans="${c.answer}" | opts=${c.options.length} | conf=${c.confidence.toStringAsFixed(2)}',
      );
      print('      "$t"');
    }
  }

  // Check for issues
  print('\n── 问题检查 ──');
  final noAnswer = candidates
      .where((c) => c.answer.isEmpty && c.options.isNotEmpty)
      .length;
  final noOptions = candidates
      .where(
        (c) =>
            c.options.isEmpty && c.candidateType == CandidateType.singleChoice,
      )
      .length;
  print('有选项无答案: $noAnswer');
  print('单选无选项: $noOptions');
}
