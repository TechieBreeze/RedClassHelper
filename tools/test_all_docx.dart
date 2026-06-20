import 'dart:io';
import '../lib/features/import/extraction/docx_extractor.dart';
import '../lib/features/import/parsing/heuristic_parser.dart';

void main() async {
  final parser = HeuristicParser();
  final dir = Directory('doc/example');
  final docxFiles = dir.listSync().where((f) => f.path.endsWith('.docx')).toList();

  for (final file in docxFiles) {
    final name = file.path.split(RegExp(r'[/\\]')).last;
    print('═' * 60);
    print('  $name');
    print('═' * 60);

    final text = await extractDocxText(file.path);
    final candidates = parser.parse(text);

    final typeCounts = <String, int>{};
    for (final c in candidates) {
      final t = c.candidateType.name;
      typeCounts[t] = (typeCounts[t] ?? 0) + 1;
    }

    final withAns = candidates.where((c) => c.answer.isNotEmpty).length;
    final withExpl = candidates.where((c) => c.explanation.isNotEmpty).length;
    final noAns = candidates.where((c) => c.answer.isEmpty && c.options.isNotEmpty).length;

    print('文本: ${text.length}字符, ${text.split('\n').length}行 → ${candidates.length}题');
    print('题型: ${typeCounts.entries.map((e) => '${e.key}:${e.value}').join(', ')}');
    print('有答案: $withAns/${candidates.length}  有解析: $withExpl  缺答案: $noAns');
    if (candidates.isNotEmpty) {
      final avg = candidates.map((c) => c.confidence).reduce((a, b) => a + b) / candidates.length;
      print('平均置信度: ${avg.toStringAsFixed(2)}');
    }

    // 前5题详情
    for (var i = 0; i < candidates.length && i < 5; i++) {
      final c = candidates[i];
      final t = c.title.length > 45 ? '${c.title.substring(0, 45)}...' : c.title;
      print('  [$i] ${c.candidateType.name} ans="${c.answer}" opts=${c.options.length}');
      print('       "$t"');
    }

    // 缺答案的题
    if (noAns > 0) {
      print('  --- 缺答案 ---');
      for (final c in candidates.where((c) => c.answer.isEmpty && c.options.isNotEmpty).take(3)) {
        print('       "${c.title.length > 50 ? c.title.substring(0, 50)+"..." : c.title}"');
      }
    }

    print('');
  }
}
