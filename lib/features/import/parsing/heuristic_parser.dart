// lib/features/import/parsing/heuristic_parser.dart
// ── 启发式正则解析器 ──
// 使用多层正则表达式将提取的文本拆分为题目候选。
// 零 AI 依赖，仅在置信度 <0.5 时标记为人工复核。

import 'parse_candidate.dart';

/// 启发式解析器：将纯文本拆分为 [ParseCandidate] 列表。
///
/// 算法概述：
/// 1. 按空行分段
/// 2. 在每个段落内用题号正则定位题目起始
/// 3. 在题目块内匹配选项标签（A./A、）
/// 4. 在相邻块中匹配答案行和解析行
/// 5. 根据匹配到的模式组合计算置信度
class HeuristicParser {
  // ── 核心正则 ──

  /// 题号模式：匹配 "1." "21" "1、" "（1）" 等
  static final RegExp _questionNumberRE = RegExp(
    r'^[（(]?\s*(\d{1,4})\s*[）).、\s]',
    multiLine: true,
  );

  /// 选择题标签：A. B. C. D. 或 A、B、C、D、
  static final RegExp _choiceLabelRE = RegExp(
    r'(?:^|\n)\s*([A-H])[.、．]\s*(.+?)(?=\n\s*[A-H][.、．]|\n\s*(?:答案|参考|正确|解析|解释)|$)',
    multiLine: true,
    dotAll: true,
  );

  /// 答案行：答案：A / 参考答案：ABC / 标准答案: C
  static final RegExp _answerLineRE = RegExp(
    r'(?:答案|参考答[案案]|正确答[案案]|标准答[案案])\s*[：:]\s*([A-Ha-h、,，\s]+)',
    multiLine: true,
  );

  /// 解析行：解析：xxx / 解释：xxx / 答案解析：xxx
  static final RegExp _explanationLineRE = RegExp(
    r'(?:解析|解释|答案[解解]析)\s*[：:]\s*(.+?)(?=\n(?:\d{1,4}[）.、]|\s*(?:答案|参考|正确|解析|解释)|$))',
    multiLine: true,
    dotAll: true,
  );

  /// 判断题关键词
  static final RegExp _trueFalseRE = RegExp(
    r'[（(]\s*[✓✗×√×✔✘✅❌TF对错是非]\s*[）)]',
  );

  /// 简答题特征：无选项标签但有较长的问题文本
  static final RegExp _shortAnswerRE = RegExp(
    r'(?:简述|简答|论述|分析|说明|概述|什么是|如何|怎样|为什么)',
  );

  // ── 解析入口 ──

  /// 从纯文本解析题目候选列表。
  ///
  /// [rawText] 为 docx_extractor 或 pdf_extractor 的输出。
  /// [bankName] 用于存储到候选的 metadata 中。
  List<ParseCandidate> parse(String rawText, {String bankName = ''}) {
    if (rawText.trim().isEmpty) return [];

    final lines = rawText.split('\n');
    final blocks = _splitIntoBlocks(lines);

    final candidates = <ParseCandidate>[];
    var lineOffset = 0;

    for (final block in blocks) {
      if (block.isEmpty) {
        lineOffset++;
        continue;
      }

      final candidate = _parseBlock(block, lineOffset, lines);
      if (candidate != null) {
        final enriched = candidate.copyWith(
          metadata: {
            ...candidate.metadata,
            if (bankName.isNotEmpty) 'bankName': bankName,
          },
        );
        candidates.add(enriched);
      }

      lineOffset += block.length;
    }

    return candidates;
  }

  // ── 块拆分：按空行 ──

  List<List<String>> _splitIntoBlocks(List<String> lines) {
    final blocks = <List<String>>[];
    var current = <String>[];

    for (final line in lines) {
      if (line.trim().isEmpty) {
        if (current.isNotEmpty) {
          blocks.add(current);
          current = [];
        }
        blocks.add([]); // 空行也保留
      } else {
        current.add(line);
      }
    }
    if (current.isNotEmpty) blocks.add(current);

    return blocks;
  }

  // ── 单块解析 ──

  ParseCandidate? _parseBlock(
    List<String> block,
    int lineOffset,
    List<String> allLines,
  ) {
    final blockText = block.join('\n').trim();
    if (blockText.isEmpty) return null;

    // 检查是否以题号开头
    final numberMatch = _questionNumberRE.firstMatch(blockText);
    if (numberMatch == null) {
      // 可能是前一题的延续（答案/解析行），跳过
      return null;
    }

    final title = _extractTitle(blockText, numberMatch);
    final candidateType = _determineType(blockText, block, lineOffset, allLines);
    final options = _extractOptions(blockText);
    final answer = _extractAnswer(blockText, block, lineOffset, allLines);
    final explanation = _extractExplanation(blockText, block, lineOffset, allLines);
    final confidence = _calculateConfidence(
      candidateType, options, answer, explanation,
    );

    return ParseCandidate(
      rawText: blockText,
      candidateType: candidateType,
      title: title,
      options: options,
      answer: answer,
      explanation: explanation,
      confidence: confidence,
      startLine: lineOffset,
      endLine: lineOffset + block.length - 1,
    );
  }

  // ── 子提取方法 ──

  String _extractTitle(String blockText, Match numberMatch) {
    // 去除题号后的内容作为标题
    final afterNumber = blockText.substring(numberMatch.end).trim();
    // 截取第一行非选项的内容
    final lines = afterNumber.split('\n');
    final titleLines = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) break;
      // 如果遇到选项标签，停止
      if (RegExp(r'^[A-H][.、．]').hasMatch(trimmed)) break;
      // 如果遇到答案行，停止
      if (_answerLineRE.hasMatch(trimmed)) break;
      titleLines.add(trimmed);
    }

    return titleLines.join(' ').trim();
  }

  CandidateType _determineType(
    String blockText,
    List<String> block,
    int lineOffset,
    List<String> allLines,
  ) {
    // 检查当前块 + 相邻块中的选项
    final combinedText = _getExtendedText(block, lineOffset, allLines);

    final hasChoices = _choiceLabelRE.hasMatch(combinedText);
    final hasTrueFalse = _trueFalseRE.hasMatch(combinedText);
    final hasShortAnswer = _shortAnswerRE.hasMatch(combinedText);

    if (hasTrueFalse) {
      return CandidateType.trueFalse;
    }

    if (hasChoices) {
      // 统计选项数
      final choiceMatches = _choiceLabelRE.allMatches(combinedText).toList();
      final uniqueLabels = choiceMatches
          .map((m) => m.group(1))
          .whereType<String>()
          .toSet();
      if (uniqueLabels.length >= 4) {
        // A-D 及以上 → 单选题或多选题
        // 检查答案是否含多个字母来区分
        final answer = _extractAnswer(blockText, block, lineOffset, allLines);
        if (answer.length > 1 && answer.replaceAll(RegExp(r'[A-Ha-h]'), '').isEmpty) {
          return CandidateType.multiChoice;
        }
        return CandidateType.singleChoice;
      }
      // 2-3 个选项 → 判断题变体或单选题
      return CandidateType.singleChoice;
    }

    if (hasShortAnswer) {
      return CandidateType.shortAnswer;
    }

    return CandidateType.unknown;
  }

  List<String> _extractOptions(String blockText) {
    final matches = _choiceLabelRE.allMatches(blockText).toList();
    if (matches.isEmpty) return [];

    return matches.map((m) {
      final label = m.group(1) ?? '';
      final text = (m.group(2) ?? '').trim();
      return '$label. $text';
    }).toList();
  }

  String _extractAnswer(
    String blockText,
    List<String> block,
    int lineOffset,
    List<String> allLines,
  ) {
    // 先在当前块查找
    final match = _answerLineRE.firstMatch(blockText);
    if (match != null) {
      return (match.group(1) ?? '').trim().toUpperCase();
    }

    // 在相邻块中查找（向前后各2个块）
    final extendedText = _getExtendedText(block, lineOffset, allLines);
    final extMatch = _answerLineRE.firstMatch(extendedText);
    if (extMatch != null) {
      return (extMatch.group(1) ?? '').trim().toUpperCase();
    }

    return '';
  }

  String _extractExplanation(
    String blockText,
    List<String> block,
    int lineOffset,
    List<String> allLines,
  ) {
    // 先在当前块查找
    final match = _explanationLineRE.firstMatch(blockText);
    if (match != null) {
      return (match.group(1) ?? '').trim();
    }

    // 在相邻块中查找
    final extendedText = _getExtendedText(block, lineOffset, allLines);
    final extMatch = _explanationLineRE.firstMatch(extendedText);
    if (extMatch != null) {
      return (extMatch.group(1) ?? '').trim();
    }

    return '';
  }

  double _calculateConfidence(
    CandidateType type,
    List<String> options,
    String answer,
    String explanation,
  ) {
    if (type == CandidateType.unknown) return 0.1;

    double confidence = 0.0;

    // 题型已识别：+0.3
    confidence += 0.3;

    // 有选项：+0.2
    if (options.isNotEmpty) confidence += 0.2;

    // 有答案：+0.3
    if (answer.isNotEmpty) confidence += 0.3;

    // 有解析：+0.1
    if (explanation.isNotEmpty) confidence += 0.1;

    // 判断题额外加分
    if (type == CandidateType.trueFalse && answer.isNotEmpty) {
      confidence += 0.1;
    }

    return confidence.clamp(0.0, 1.0);
  }

  /// 获取当前块前后各2个块的扩展文本
  String _getExtendedText(
    List<String> block,
    int lineOffset,
    List<String> allLines,
  ) {
    final startLine = (lineOffset - 4).clamp(0, allLines.length - 1);
    final endLine = (lineOffset + block.length + 4).clamp(0, allLines.length);

    return allLines.sublist(startLine, endLine).join('\n');
  }
}
