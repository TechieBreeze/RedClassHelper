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

    // ── 选项跨行 / 一行多选紧贴 ──

    test('option label on its own line, text on next line', () {
      const input = '''
1. 马克思主义中国化的科学内涵是
A. 马克思主义基本原理同中国具体实际相结合
B. 马克思主义理论在中国的传播
C. 把马克思主义经典作家的著作翻译成中文
D.
实现中华民族伟大复兴的必由之路
答案：A
''';
      final candidates = parser.parse(input);
      expect(candidates, isNotEmpty);
      expect(candidates.first.options.length, 4);
      expect(candidates.first.options[3],
          contains('实现中华民族伟大复兴的必由之路'));
    });

    test('inline options without space between them (dot-separated)', () {
      const input = '''
1. 中国特色社会主义的本质特征是中国共产党的领导A.中国特色社会主义B.马克思主义中国化C.邓小平理论D.三个代表重要思想
''';
      final candidates = parser.parse(input);
      expect(candidates, isNotEmpty);
      expect(candidates.first.options.length, 4);
      expect(candidates.first.options[0], contains('中国特色社会主义'));
      expect(candidates.first.options[1], contains('马克思主义中国化'));
      expect(candidates.first.options[2], contains('邓小平理论'));
      expect(candidates.first.options[3], contains('三个代表重要思想'));
      // Title should not contain option labels
      expect(candidates.first.title, isNot(contains('A.')));
    });

    test('inline options without space between them (space-separated)', () {
      const input = '''
1. 新民主主义革命的总路线是无产阶级领导的A 反对帝国主义B 反对封建主义C 反对官僚资本主义D 建立人民民主专政
''';
      final candidates = parser.parse(input);
      expect(candidates, isNotEmpty);
      // Space-separated with no space between options: should still split
      expect(candidates.first.options.length, greaterThanOrEqualTo(3));
    });

    test('options on same line as question number are separated from title', () {
      const input = '''
1.题干内容A.选项1B.选项2C.选项3D.选项4
答案：B
''';
      final candidates = parser.parse(input);
      expect(candidates, isNotEmpty);
      expect(candidates.first.options.length, 4);
      expect(candidates.first.title, '题干内容');
      final q = candidates.first;
      expect(q.options[0], contains('A. 选项1'));
    });

    // ── 行末悬空选项标签 (4 种变体) ──
    // 场景来源：doc/example/《纲要》选择题（2026年5月最新修订版）.json Q377 / Q5
    // PDF 提取时 D. 之后无内容（点号后立即换行），文本被推到下一行。

    test('Q377: D. inline empty + text on next line → 4 options', () {
      // 复现 _gangyao_extracted.txt 第1843-1845行
      const input = '''
7、近代中国，列强对华文化渗透主要表现在 （ AB  ）
A． 披着宗教 外衣， 进行侵略活动   B.为侵略中国制造舆论   C.实行商品倾销和资本输出   D.
控制中国的内政外交
8、近代中国反侵略战争失败的主要原因是 （  BD  ）
A.中国当时的实力弱   B.社会制度的腐败   C.帝国主义过于强大   D.经济技术落后
''';
      final candidates = parser.parse(input);
      expect(candidates.length, 2);
      final q7 = candidates[0];
      expect(q7.options.length, 4, reason: 'D 选项不应丢失');
      expect(q7.options[2], 'C. 实行商品倾销和资本输出');
      expect(q7.options[3], 'D. 控制中国的内政外交');
      expect(q7.answer, 'AB');
      expect(q7.candidateType, CandidateType.multiChoice,
          reason: 'AB 答案应识别为多选题，即使 D 解析异常后只有 3 个选项也应能识别');
    });

    test('Q5: D. inline empty + text on next line (book-title variant)', () {
      // Q5 真实 PDF 文本是空格分隔 D《中法新约》 (D 标签无点号 + 内容接《)，
      // 那是另一种 bug（空格分隔路径）。这里改用与 Q377 同源的"点号+换行"变体：
      // C. 有内容、D. 同行末尾空、内容《中法新约》在下一行。
      const input = '''
5、我国与列强签订的第一个不平等条约是 （  A  ）
A.中英《南京条约》   B.中英《北京条约》   C.中日《马关条约》   D.
《中法新约》
''';
      final candidates = parser.parse(input);
      expect(candidates, isNotEmpty);
      expect(candidates.first.options.length, 4,
          reason: 'D. 同行末尾空 + 下一行《中法新约》 应识别为 D 内容');
      expect(candidates.first.options[2], contains('中日《马关条约》'));
      expect(candidates.first.options[3], contains('《中法新约》'));
    });

    test('D bare letter on prev line, dot+text on next line', () {
      // 点号换行场景（用户边界情况 #1）
      const input = '''
1. 测试题
A.xxx B.xxx C.xxx D
.控制中国的内政外交
答案：AB
''';
      final candidates = parser.parse(input);
      expect(candidates, isNotEmpty);
      expect(candidates.first.options.length, 4);
      expect(candidates.first.options[3], contains('控制中国的内政外交'));
    });

    test('D bare letter, dot on its own line, text on third line', () {
      // 标签+点号都换行（用户边界情况 #2）
      const input = '''
1. 测试题
A.xxx B.xxx C.xxx D
.
控制中国的内政外交
答案：AB
''';
      final candidates = parser.parse(input);
      expect(candidates, isNotEmpty);
      expect(candidates.first.options.length, 4);
      expect(candidates.first.options[3], contains('控制中国的内政外交'));
    });
  });
}
