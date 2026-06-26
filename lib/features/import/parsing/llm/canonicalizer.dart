// lib/features/import/parsing/llm/canonicalizer.dart
// ── 答案归一化器 ──
// 将 LLM 的多种答案格式归一化为排序后的单字母列表。
// 处理：AB, A,B, A、B, A和B, ["A","B"], A B 等格式。

import 'dart:convert';

/// 解析来源三向区分（D-09: 追踪每题的解析路径）。
enum ParseSource {
  /// LLM 成功解析
  llm,

  /// 纯启发式解析（用户选"快速解析"）
  heuristic,

  /// LLM 失败后启发式兜底
  fallback,
}

/// 过滤后大写字母的匹配正则（A-H）。
final _letterRE = RegExp(r'[A-Ha-h]');

/// 将 LLM 输出的原始答案归一化为排序后的单字母列表。
///
/// 支持的输入格式：
/// - "AB" → ["A","B"]
/// - "A,B" → ["A","B"]
/// - "A、B" → ["A","B"]
/// - "A和B" → ["A","B"]
/// - '["A","B"]' → ["A","B"]
/// - "A B" → ["A","B"]
/// - "a,b" → ["A","B"] (大小写统一)
/// - "因为A选项正确" → ["A"] (去除非字母字符)
///
/// [rawAnswer] 为 LLM 输出或启发式解析得到的原始答案字符串。
/// 返回排序后的大写单字母列表；不包含 A-H 时返回空列表。
List<String> canonicalizeAnswer(String rawAnswer) {
  if (rawAnswer.isEmpty) return [];

  // 首次尝试：JSON 数组解码 ["A","B"]
  try {
    final decoded = jsonDecode(rawAnswer);
    if (decoded is List) {
      return decoded
          .map((e) => e.toString().toUpperCase().trim())
          .where((e) => e.length == 1 && _letterRE.hasMatch(e))
          .toSet()
          .toList()
        ..sort();
    }
  } catch (_) {
    // 非 JSON 输入 → 走正则提取路径
  }

  // 提取所有单个大写或小写字母 A-H
  final letters =
      _letterRE
          .allMatches(rawAnswer)
          .map((m) => m.group(0)!.toUpperCase())
          .toSet()
          .toList()
        ..sort();

  return letters;
}

/// 将规范化后的字母列表转为显示字符串。
///
/// 例：`['A','B']` → `"AB"`（向后兼容现有数据库存储格式）。
String formatAnswerForDisplay(List<String> canonical) {
  return canonical.join();
}
