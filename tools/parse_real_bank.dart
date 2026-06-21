// tools/parse_real_bank.dart
// ── 真实题库端到端解析验证 ──
// 读取 doc/example/_gangyao_extracted.txt（PDF 提取的真实文本），
// 跑 HeuristicParser，输出每题的 type / options 数 / answer。
// 用途：人工核对真实数据中是否有选项合并/题型错判等 bug。

import 'dart:io';

import '../lib/features/import/parsing/heuristic_parser.dart';
import '../lib/features/import/parsing/parse_candidate.dart';

void main(List<String> args) {
  final path = args.isNotEmpty
      ? args[0]
      : 'doc/example/_gangyao_extracted.txt';
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('ERROR: 文件不存在: $path');
    exit(1);
  }

  final text = file.readAsStringSync();
  final parser = HeuristicParser();
  final candidates = parser.parse(text, bankName: 'gangyao_real');

  var total = 0;
  var suspicious = 0;
  final typeCounts = <CandidateType, int>{};

  for (var i = 0; i < candidates.length; i++) {
    final c = candidates[i];
    total++;
    typeCounts[c.candidateType] = (typeCounts[c.candidateType] ?? 0) + 1;

    // 异常检测：
    // 1. 题目是选择类但选项数 < 4（标准 4 选项结构）
    // 2. 题目是选择类但答案为空
    final isChoice = c.candidateType == CandidateType.singleChoice ||
        c.candidateType == CandidateType.multiChoice;
    final optionCount = c.options.length;
    final isSuspicious = isChoice && (optionCount < 4 || optionCount > 8);
    final missingAnswer = isChoice && c.answer.isEmpty;

    if (isSuspicious || missingAnswer) suspicious++;

    // 标题截断便于阅读
    final title = c.title.replaceAll(RegExp(r'\s+'), ' ');
    final titleShort = title.length > 40 ? '${title.substring(0, 40)}…' : title;
    final flag = isSuspicious ? '⚠' : (missingAnswer ? '?' : ' ');
    print(
        '[$i] $flag type=${c.candidateType.name} opts=$optionCount ans="${c.answer}" title=$titleShort');

    if (c.options.isNotEmpty && (isSuspicious || i < 5)) {
      for (final opt in c.options) {
        final t = opt.replaceAll(RegExp(r'\s+'), ' ');
        final tShort = t.length > 60 ? '${t.substring(0, 60)}…' : t;
        print('     • $tShort');
      }
    }
  }

  print('');
  print('═══════════════════════════════════════════');
  print('总题数: $total');
  print('类型分布:');
  typeCounts.forEach((k, v) => print('  $k: $v'));
  print('异常题目数: $suspicious');
}
