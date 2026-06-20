// lib/features/import/parsing/heuristic_parser.dart
// ── 启发式正则解析器 ──
// 支持两种题库格式：
//   A. 显式题号格式：「数字. 题干 / A.选项 / 答案：X / 解析：...」
//   B. 内联格式：无题号，答案在题干中（X），无独立答案行/解析行

import 'parse_candidate.dart';

class HeuristicParser {
  // ── 模式 A：显式题号格式的正则 ──

  /// 题号：行首 "1." "21" "1、" "（1）" 等
  static final RegExp _questionNumberRE = RegExp(
    r'^\s*[（(]?\s*(\d{1,4})\s*[）).、\s]',
  );

  /// 选项标签：行首 A. / A、/ A． 后跟选项文本
  static final RegExp _choiceLabelRE = RegExp(
    r'^\s*([A-H])\s*[.、．]\s*(.+)$',
  );

  /// 答案行：答案：A / 参考答案：ABC 等
  static final RegExp _answerLineRE = RegExp(
    r'^\s*(?:答案|参考答[案案]|正确答[案案]|标准答[案案])\s*[：:]\s*(.+)$',
  );

  /// 解析行：解析：xxx / 解释：xxx / 答案解析：xxx
  static final RegExp _explanationLineRE = RegExp(
    r'^\s*(?:解析|解释|答案[解解]析)\s*[：:]\s*(.+)$',
  );

  /// 判断题标记：（√）（×）等
  static final RegExp _trueFalseInTitleRE = RegExp(
    r'[（(]\s*[✓✗×√×✔✘✅❌TF对错是非]\s*[）)]',
  );

  /// 简答题特征
  static final RegExp _shortAnswerRE = RegExp(
    r'(?:简述|简答|论述|分析|说明|概述|什么是|如何|怎样|为什么)',
  );

  // ── 模式 B：内联格式的正则 ──

  /// 内联答案：题干中的（A）/（AB）/（C D E）/（ＣD）等
  /// 支持半角/全角字母、空格分隔；可出现在题干任意位置
  static final RegExp _inlineAnswerRE = RegExp(
    r'[（(]\s*([A-Ha-hＡ-Ｈａ-ｈ\s]{1,24})\s*[）)]',
  );

  /// 一行内多个选项：A.xxx  B.xxx  C.xxx  D.xxx
  static final RegExp _inlineChoiceRE = RegExp(
    r'([A-H])\s*[.、．]\s*(.+?)(?=\s*[A-H]\s*[.、．]|$)',
  );

  // ── 解析入口 ──

  List<ParseCandidate> parse(String rawText, {String bankName = ''}) {
    if (rawText.trim().isEmpty) return [];

    final lines = rawText.split('\n');

    // 检测格式：是否有题号行？
    final hasQuestionNumbers = _countQuestionNumbers(lines) >= 1;

    final blocks = hasQuestionNumbers
        ? _splitByQuestionNumbers(lines)
        : _splitByOptionBoundaries(lines);

    final candidates = <ParseCandidate>[];
    for (final block in blocks) {
      final candidate = _parseBlock(block, inlineFormat: !hasQuestionNumbers);
      if (candidate != null) {
        candidates.add(candidate.copyWith(
          metadata: {
            ...candidate.metadata,
            if (bankName.isNotEmpty) 'bankName': bankName,
          },
        ));
      }
    }
    return candidates;
  }

  // ── 格式检测 ──

  int _countQuestionNumbers(List<String> lines) {
    var count = 0;
    for (final line in lines) {
      if (_questionNumberRE.hasMatch(line.trim())) count++;
    }
    return count;
  }

  // ── 块拆分 A：按题号边界 ──

  List<_Block> _splitByQuestionNumbers(List<String> lines) {
    final blocks = <_Block>[];
    var currentLines = <String>[];
    var blockStartLine = 0;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        if (currentLines.isNotEmpty) {
          blocks.add(_Block(currentLines, blockStartLine, i - 1));
          currentLines = [];
        }
        continue;
      }

      if (_questionNumberRE.hasMatch(trimmed) && currentLines.isNotEmpty) {
        blocks.add(_Block(currentLines, blockStartLine, i - 1));
        currentLines = [];
      }

      if (currentLines.isEmpty) blockStartLine = i;
      currentLines.add(line);
    }

    if (currentLines.isNotEmpty) {
      blocks.add(_Block(currentLines, blockStartLine, lines.length - 1));
    }
    return blocks;
  }

  // ── 块拆分 B：按选项边界（无题号时） ──

  List<_Block> _splitByOptionBoundaries(List<String> lines) {
    // 先标记每行的类型
    final tags = <_LineTag>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        tags.add(_LineTag.empty);
      } else if (_choiceLabelRE.hasMatch(trimmed) ||
                 _inlineChoiceRE.hasMatch(trimmed)) {
        tags.add(_LineTag.option);
      } else if (_answerLineRE.hasMatch(trimmed)) {
        tags.add(_LineTag.answer);
      } else if (_explanationLineRE.hasMatch(trimmed)) {
        tags.add(_LineTag.explanation);
      } else {
        tags.add(_LineTag.title);
      }
    }

    // 标记哪些 title 行是真正的题目开头（后面跟着 option 行）
    // 向前看最多4行，如果其中有 option 行，则这是一个题目块的开头
    final isQuestionStart = <bool>[];
    for (var i = 0; i < lines.length; i++) {
      if (tags[i] != _LineTag.title) {
        isQuestionStart.add(false);
        continue;
      }
      // 向前看最多6行，找到 option
      var hasFollowingOption = false;
      for (var j = i + 1; j < lines.length && j <= i + 6; j++) {
        if (tags[j] == _LineTag.option) {
          hasFollowingOption = true;
          break;
        }
        if (tags[j] == _LineTag.title) break; // 下一个 title 阻止
      }
      isQuestionStart.add(hasFollowingOption);
    }

    // 按题目边界分组
    final blocks = <_Block>[];
    var blockStart = -1;

    for (var i = 0; i < lines.length; i++) {
      if (tags[i] == _LineTag.empty) {
        if (blockStart >= 0) {
          blocks.add(_Block(
            lines.sublist(blockStart, i),
            blockStart,
            i - 1,
          ));
          blockStart = -1;
        }
        continue;
      }

      if (isQuestionStart[i]) {
        if (blockStart >= 0) {
          blocks.add(_Block(
            lines.sublist(blockStart, i),
            blockStart,
            i - 1,
          ));
        }
        blockStart = i;
      } else if (blockStart < 0 && tags[i] != _LineTag.empty) {
        // 第一个非空行（可能是 section header "单选题"），跳过
        continue;
      }
    }

    if (blockStart >= 0) {
      blocks.add(_Block(
        lines.sublist(blockStart),
        blockStart,
        lines.length - 1,
      ));
    }

    return blocks;
  }

  // ── 单块解析 ──

  ParseCandidate? _parseBlock(_Block block, {bool inlineFormat = false}) {
    final lines = block.lines;
    if (lines.isEmpty) return null;

    final firstLine = lines[0].trim();

    if (inlineFormat) {
      return _parseInlineBlock(block);
    }

    // 模式 A：显式题号格式
    final numberMatch = _questionNumberRE.firstMatch(firstLine);
    if (numberMatch == null) return null;

    final title = _extractTitle(lines, numberMatch);
    final options = _extractOptions(lines);
    var answer = _extractAnswer(lines);
    // 无显式答案行时，尝试从题干中提取内联答案（X）
    if (answer.isEmpty) {
      answer = _extractInlineAnswer(title);
    }
    final explanation = _extractExplanation(lines);
    final candidateType = _determineType(title, options, answer);
    final confidence = _calculateConfidence(
      candidateType, options, answer, explanation,
    );

    return ParseCandidate(
      rawText: block.text,
      candidateType: candidateType,
      title: title,
      options: options,
      answer: answer,
      explanation: explanation,
      confidence: confidence,
      startLine: block.startLine,
      endLine: block.endLine,
    );
  }

  /// 模式 B：内联格式（无题号，答案在题干括号中）
  ParseCandidate _parseInlineBlock(_Block block) {
    final lines = block.lines;
    final titleLine = lines[0].trim();

    // 提取内联答案
    var answer = '';
    final inlineMatch = _inlineAnswerRE.firstMatch(titleLine);
    String title = titleLine;
    if (inlineMatch != null) {
      answer = inlineMatch.group(1)!.toUpperCase();
      // 从题干中移除答案标记，但不影响内联格式的显示
    }

    // 提取选项（从后续行）
    final options = _extractOptions(lines);

    // 判断题型
    CandidateType type;
    if (_trueFalseInTitleRE.hasMatch(title)) {
      type = CandidateType.trueFalse;
    } else if (options.isNotEmpty) {
      final cleanAnswer = answer.replaceAll(RegExp(r'[^A-Ha-h]'), '');
      if (cleanAnswer.length > 1) {
        type = CandidateType.multiChoice;
      } else {
        type = CandidateType.singleChoice;
      }
    } else if (_shortAnswerRE.hasMatch(title)) {
      type = CandidateType.shortAnswer;
    } else {
      type = CandidateType.unknown;
    }

    // 内联格式无独立解析行
    final confidence = _calculateConfidence(type, options, answer, '');

    return ParseCandidate(
      rawText: block.text,
      candidateType: type,
      title: title,
      options: options,
      answer: answer,
      explanation: '',
      confidence: confidence,
      startLine: block.startLine,
      endLine: block.endLine,
    );
  }

  // ── 标题提取（模式 A） ──

  String _extractTitle(List<String> lines, Match numberMatch) {
    final firstLine = lines[0].trim();
    final afterNumber = firstLine.substring(numberMatch.end).trim();
    final titleLines = <String>[];
    if (afterNumber.isNotEmpty) titleLines.add(afterNumber);

    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      if (_choiceLabelRE.hasMatch(line)) break;
      if (_answerLineRE.hasMatch(line)) break;
      if (_explanationLineRE.hasMatch(line)) break;
      titleLines.add(line);
    }
    return titleLines.join(' ').trim();
  }

  // ── 选项提取（共用） ──

  List<String> _extractOptions(List<String> lines) {
    final options = <String>[];
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      // 先尝试单行多选格式：A.xxx  B.xxx  C.xxx  D.xxx
      final inlineMatches = _inlineChoiceRE.allMatches(line).toList();
      if (inlineMatches.length >= 2) {
        for (final m in inlineMatches) {
          final label = m.group(1) ?? '';
          final text = (m.group(2) ?? '').trim();
          options.add('$label. $text');
        }
        continue;
      }

      // 标准单选项格式：A.xxx
      final m = _choiceLabelRE.firstMatch(line);
      if (m != null) {
        final label = m.group(1) ?? '';
        final text = (m.group(2) ?? '').trim();
        options.add('$label. $text');
        continue;
      }

      // 选项跨行延续（紧跟前一行非选项标签的行，且不是答案/解析/标题）
      if (options.isNotEmpty &&
          !_answerLineRE.hasMatch(line) &&
          !_explanationLineRE.hasMatch(line) &&
          !RegExp(r'^\d').hasMatch(line)) {
        // Append to last option
        options[options.length - 1] =
            '${options[options.length - 1]} $line';
      }
    }
    return options;
  }

  // ── 答案提取（模式 A） ──

  String _extractAnswer(List<String> lines) {
    for (final line in lines) {
      final m = _answerLineRE.firstMatch(line.trim());
      if (m != null) {
        return (m.group(1) ?? '').trim().toUpperCase();
      }
    }
    return '';
  }

  // ── 解析提取（模式 A） ──

  String _extractExplanation(List<String> lines) {
    for (final line in lines) {
      final m = _explanationLineRE.firstMatch(line.trim());
      if (m != null) {
        return (m.group(1) ?? '').trim();
      }
    }
    return '';
  }

  /// 从题干中提取内联答案，如 "会议是（D）" → "D"
  /// 支持半角/全角字母、空格分隔的答案
  String _extractInlineAnswer(String title) {
    final m = _inlineAnswerRE.firstMatch(title);
    if (m == null) return '';
    var raw = m.group(1)!.toUpperCase();
    // 全角字母转半角（U+FF21-U+FF3A → A-Z, U+FF41-U+FF5A → a-z）
    final buf = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final ch = raw.codeUnitAt(i);
      if (ch >= 0xFF21 && ch <= 0xFF3A) {
        buf.writeCharCode('A'.codeUnitAt(0) + ch - 0xFF21);
      } else if (ch >= 0xFF41 && ch <= 0xFF5A) {
        buf.writeCharCode('A'.codeUnitAt(0) + ch - 0xFF41);
      } else {
        buf.writeCharCode(ch);
      }
    }
    raw = buf.toString();
    // 去除空格及不可见字符，只保留有效答案字母
    raw = raw.replaceAll(RegExp(r'[^A-H]'), '');
    return raw;
  }

  // ── 题型判定（模式 A） ──

  CandidateType _determineType(
    String title,
    List<String> options,
    String answer,
  ) {
    if (_trueFalseInTitleRE.hasMatch(title)) {
      return CandidateType.trueFalse;
    }

    if (options.isNotEmpty) {
      final optionLabels = options.map((o) => o.substring(0, 1)).toSet();
      if (optionLabels.length >= 4) {
        final cleanAnswer = answer.replaceAll(RegExp(r'[^A-Ha-h]'), '');
        if (cleanAnswer.length > 1) return CandidateType.multiChoice;
        return CandidateType.singleChoice;
      }
      return CandidateType.singleChoice;
    }

    if (_shortAnswerRE.hasMatch(title)) return CandidateType.shortAnswer;

    if (answer.isNotEmpty &&
        RegExp(r'^\s*[✓✗×√×✔✘✅❌TF对错是非]\s*$').hasMatch(answer)) {
      return CandidateType.trueFalse;
    }

    return CandidateType.unknown;
  }

  // ── 置信度 ──

  double _calculateConfidence(
    CandidateType type,
    List<String> options,
    String answer,
    String explanation,
  ) {
    if (type == CandidateType.unknown) return 0.1;

    double confidence = 0.3;
    if (options.isNotEmpty) confidence += 0.2;
    if (answer.isNotEmpty) confidence += 0.3;
    if (explanation.isNotEmpty) confidence += 0.1;
    if (type == CandidateType.trueFalse && answer.isNotEmpty) confidence += 0.1;

    return confidence.clamp(0.0, 1.0);
  }
}

// ── 内部类型 ──

enum _LineTag { empty, title, option, answer, explanation }

class _Block {
  final List<String> lines;
  final int startLine;
  final int endLine;
  const _Block(this.lines, this.startLine, this.endLine);
  String get text => lines.join('\n');
}
