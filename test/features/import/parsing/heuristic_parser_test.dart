// test/features/import/parsing/heuristic_parser_test.dart
// ── 启发式解析器单元测试 ──
// 使用提取后的真实文本验证解析逻辑。

import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/features/import/parsing/heuristic_parser.dart';
import 'package:redclass/features/import/parsing/parse_candidate.dart';

void main() {
  late HeuristicParser parser;

  setUp(() {
    parser = HeuristicParser();
  });

  group('HeuristicParser', () {
    test('returns empty list for empty input', () {
      expect(parser.parse(''), isEmpty);
      expect(parser.parse('   \n\n  '), isEmpty);
    });

    test('parses single choice question with options and answer', () {
      const input = '''
1. 马克思主义基本原理同中国具体实际相结合的哲学依据是
A. 矛盾的普遍性和特殊性辩证关系
B. 量变和质变的辩证关系
C. 主要矛盾和次要矛盾的关系
D. 事物发展前进性和曲折性的统一
答案：A
解析：矛盾的普遍性和特殊性辩证关系原理是马克思主义基本原理同中国具体实际相结合的哲学依据。
''';

      final candidates = parser.parse(input);
      expect(candidates.length, greaterThanOrEqualTo(1));

      final q = candidates.first;
      expect(q.candidateType, CandidateType.singleChoice);
      expect(q.options.length, 4);
      expect(q.options[0], contains('A.'));
      expect(q.options[1], contains('B.'));
      expect(q.answer, 'A');
      expect(q.explanation, contains('矛盾的普遍性'));
      expect(q.confidence, greaterThan(0.5));
    });

    test('parses true/false question', () {
      const input = '''
21. 党的领导是中国特色社会主义最本质的特征。（√）
答案：√
''';

      final candidates = parser.parse(input);
      expect(candidates, isNotEmpty);

      final q = candidates.first;
      expect(q.candidateType, CandidateType.trueFalse);
    });

    test('parses multiple questions from batch', () {
      const input = '''
1. 单选题示例
A. 选项一
B. 选项二
C. 选项三
D. 选项四
答案：B

2. 第二道单选题
A. 苹果
B. 香蕉
C. 橘子
D. 葡萄
答案：C
解析：这是解析内容。
''';

      final candidates = parser.parse(input);
      expect(candidates.length, greaterThanOrEqualTo(2));

      // 第一题
      expect(candidates[0].candidateType, CandidateType.singleChoice);
      expect(candidates[0].options.length, 4);
      expect(candidates[0].answer, 'B');

      // 第二题
      expect(candidates[1].candidateType, CandidateType.singleChoice);
      expect(candidates[1].answer, 'C');
      expect(candidates[1].explanation, isNotEmpty);
    });

    test('parses multi-choice question', () {
      const input = '''
3. 下列哪些属于社会主义核心价值观的内容
A. 富强
B. 民主
C. 文明
D. 和谐
E. 自由
答案：ABCDE
''';

      final candidates = parser.parse(input);
      expect(candidates, isNotEmpty);

      final q = candidates.first;
      // 多选题检测
      final isMulti = q.candidateType == CandidateType.multiChoice ||
          q.candidateType == CandidateType.singleChoice;
      expect(isMulti, true);
    });

    test('detects short answer question', () {
      const input = '''
5. 简述马克思主义中国化的科学内涵
答案：马克思主义中国化就是把马克思主义基本原理同中国具体实际相结合...
解析：此题考查对基本概念的理解。
''';

      final candidates = parser.parse(input);
      expect(candidates, isNotEmpty);

      final q = candidates.first;
      final isShortAnswer = q.candidateType == CandidateType.shortAnswer ||
          q.candidateType == CandidateType.unknown;
      expect(isShortAnswer, true);
    });

    test('assigns low confidence to unknown questions', () {
      const input = '''这是一段普通的文本，没有题号，没有选项。''';

      final candidates = parser.parse(input);
      expect(candidates, isEmpty);
    });

    test('stores bankName in metadata', () {
      const input = '''
1. 测试题目
A. 选项1
B. 选项2
答案：A
''';

      final candidates = parser.parse(input, bankName: '测试题库');
      expect(candidates, isNotEmpty);
      expect(candidates.first.metadata['bankName'], '测试题库');
    });

    test('confidence near 1.0 for fully matched question', () {
      const input = '''
1. 完整匹配的题目
A. 选项一
B. 选项二
C. 选项三
D. 选项四
答案：B
解析：详细的解析内容。
''';

      final candidates = parser.parse(input);
      expect(candidates, isNotEmpty);
      expect(candidates.first.confidence, greaterThanOrEqualTo(0.8));
    });

    test('handles Chinese punctuation in choices (A、B、)', () {
      const input = '''
1. 使用中文顿号的题目
A、第一选项
B、第二选项
C、第三选项
D、第四选项
答案：C
''';

      final candidates = parser.parse(input);
      expect(candidates, isNotEmpty);
      expect(candidates.first.options.length, 4);
      // 解析器将中文标点规范化为 "A."
      expect(candidates.first.options[0], contains('A'));
    });

    test('handles parenthesized question numbers', () {
      const input = '''
（1）带括号编号的题目
A. 选项A
B. 选项B
C. 选项C
D. 选项D
参考答案：D
''';

      final candidates = parser.parse(input);
      expect(candidates, isNotEmpty);
      expect(candidates.first.candidateType, CandidateType.singleChoice);
    });

    test('strips answer letters from （X）but keeps brackets (mode A)', () {
      const input = '''
1. 社会主义核心价值观在个人层面的价值准则是（D）。
A. 富强、民主、文明、和谐
B. 自由、平等、公正、法治
C. 爱国、敬业、诚信、友善
D. 爱国、敬业、诚信、友善
''';
      final candidates = parser.parse(input);
      expect(candidates, isNotEmpty);
      expect(candidates.first.title, contains('（）'));
      expect(candidates.first.title, isNot(contains('（D）')));
      expect(candidates.first.title, contains('社会主义核心价值观'));
      expect(candidates.first.answer, contains('D'));
    });

    test('strips answer letters from （X）but keeps brackets (inline format)', () {
      const input = '''
一国两制的前提是（A）
A. 坚持一个中国原则
B. 两种制度并存
C. 高度自治
D. 和平统一
''';
      final candidates = parser.parse(input);
      expect(candidates, isNotEmpty);
      expect(candidates.first.title, contains('（）'));
      expect(candidates.first.title, isNot(contains('（A）')));
      expect(candidates.first.title, contains('一国两制的前提是'));
      expect(candidates.first.answer, contains('A'));
    });

    // ── 判断题检测（来自真实 PDF 题库） ──

    test('detects true/false with （对）marker and extracts answer', () {
      const input = '''
1. 资本是能够带来剩余价值的价值。（对）
''';
      final candidates = parser.parse(input);
      expect(candidates, isNotEmpty);
      expect(candidates.first.candidateType, CandidateType.trueFalse);
      expect(candidates.first.answer, contains('对'));
      expect(candidates.first.title, isNot(contains('（对）')));
      expect(candidates.first.title, contains('资本是能够带来剩余价值的价值'));
    });

    test('detects true/false with （错）marker and extracts answer', () {
      const input = '''
1. 运动和发展是唯物辩证法的总特征。（错）
''';
      final candidates = parser.parse(input);
      expect(candidates, isNotEmpty);
      expect(candidates.first.candidateType, CandidateType.trueFalse);
      expect(candidates.first.answer, contains('错'));
      expect(candidates.first.title, isNot(contains('（错）')));
    });

    test('detects true/false with (对) half-width brackets', () {
      const input = '''
1. 阶级性与科学性是不相容的，凡是代表某个阶级利益和愿望的社会理论，就不可能是科学的。(错)
''';
      final candidates = parser.parse(input);
      expect(candidates, isNotEmpty);
      expect(candidates.first.candidateType, CandidateType.trueFalse);
      expect(candidates.first.answer, contains('错'));
      expect(candidates.first.title, isNot(contains('(错)')));
    });

    test('parses multiple true/false questions from batch', () {
      const input = '''
1. 同一性和斗争性是矛盾的两种基本属性，它们都是无条件存在的，绝对的。（错）
2. 运动和发展是唯物辩证法的总特征。（错）
3. 唯物辩证法的实质和核心是对立统一规律。（对）
4. 历史过程是人的主观意志的产物。（错）
5. 任何成功的实践都是真理尺度和价值尺度的统一。（对）
''';
      final candidates = parser.parse(input);
      expect(candidates.length, 5);

      expect(candidates[0].candidateType, CandidateType.trueFalse);
      expect(candidates[0].answer, '错');
      expect(candidates[1].candidateType, CandidateType.trueFalse);
      expect(candidates[1].answer, '错');
      expect(candidates[2].candidateType, CandidateType.trueFalse);
      expect(candidates[2].answer, '对');
      expect(candidates[3].candidateType, CandidateType.trueFalse);
      expect(candidates[3].answer, '错');
      expect(candidates[4].candidateType, CandidateType.trueFalse);
      expect(candidates[4].answer, '对');

      // All titles should not contain answer markers
      for (final c in candidates) {
        expect(c.title, isNot(contains('（对）')));
        expect(c.title, isNot(contains('（错）')));
      }
    });

    test('detects true/false when （X）is the only line content', () {
      // PDF page-break artifact: answer marker on separate line
      const input = '''
1. 习近平新时代中国特色社会主义思想实现了马克思主义中国化时代化新的飞跃。
（对）
''';
      final candidates = parser.parse(input);
      expect(candidates, isNotEmpty);
      expect(candidates.first.candidateType, CandidateType.trueFalse);
      expect(candidates.first.answer, contains('对'));
    });

    test('true/false confidence near 1.0 when answer extracted', () {
      const input = '''
1. 垄断价格是垄断组织在销售或购买商品时，凭借其垄断地位规定的、旨在保证获取最大限度利润的市场价格。（对）
''';
      final candidates = parser.parse(input);
      expect(candidates, isNotEmpty);
      expect(candidates.first.candidateType, CandidateType.trueFalse);
      expect(candidates.first.answer, '对');
      expect(candidates.first.confidence, greaterThanOrEqualTo(0.7));
    });
  });
}
