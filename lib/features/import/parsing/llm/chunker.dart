// lib/features/import/parsing/llm/chunker.dart
// ── 题目文本分块器 ──
// 按题号将原始文本拆分为单个题目块，每块独立送入 LLM。
// 这防止 LLM 截断长文本，并隔离单题解析失败。

/// 匹配中文/英文题号开头：
/// "1." "1、" "1)" "（1）" "1）" "①" 等。
///
/// 支持：
/// - 英文数字 + 标点：`1.` `21)` `3、`
/// - 中文括号数字：`（1）` `（21）`
/// - 中文圈号数字：`①②③④⑤⑥⑦⑧⑨⑩`
final _questionBreakRE = RegExp(
  r'^\s*(?:\d{1,4}[.、）\)．]\s*|（\d{1,4}）|[①②③④⑤⑥⑦⑧⑨⑩])',
  multiLine: true,
);

/// 将原始文本按题号拆分为题目块列表。
///
/// 每一块代表一个独立的题目（包含题干、选项、答案行和解析行）。
/// 如果输入文本没有匹配的题号前缀，整个文本作为单个块返回。
///
/// [rawText] 为提取后的纯文本（可能包含多个题目）。
/// 返回 [List<String>] 每个元素为一个题目块。
List<String> splitIntoQuestionBlocks(String rawText) {
  if (rawText.trim().isEmpty) return [];

  final lines = rawText.split('\n');
  final blocks = <List<String>>[];
  var current = <String>[];

  for (final line in lines) {
    if (_questionBreakRE.hasMatch(line.trimLeft()) && current.isNotEmpty) {
      blocks.add(List<String>.from(current));
      current = [line];
    } else {
      current.add(line);
    }
  }
  if (current.isNotEmpty) blocks.add(List<String>.from(current));

  return blocks
      .map((b) => b.join('\n').trim())
      .where((b) => b.isNotEmpty)
      .toList();
}
