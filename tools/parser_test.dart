import '../lib/features/import/parsing/heuristic_parser.dart';
import '../lib/features/import/parsing/parse_candidate.dart';

void main() {
  final parser = HeuristicParser();

  // Test 1: Multi-choice with Chinese punctuation in answer
  _test(parser, '多选 · 中文顿号分隔答案', '''
1. 下列哪些属于社会主义核心价值观的内容
A. 富强
B. 民主
C. 文明
D. 和谐
E. 自由
答案：A、B、C、D、E
''');

  // Test 2: Multi-choice comma-separated
  _test(parser, '多选 · 逗号分隔答案', '''
2. 马克思主义的三个组成部分
A. 马克思主义哲学
B. 马克思主义政治经济学
C. 科学社会主义
D. 空想社会主义
答案：A, B, C
''');

  // Test 3: Multi-choice no separator
  _test(parser, '多选 · 连续字母答案', '''
3. 以下哪些属于中国四大发明
A. 造纸术
B. 指南针
C. 火药
D. 印刷术
E. 地动仪
答案：ABCD
''');

  // Test 4: No blank lines between questions with multi-choice
  _test(parser, '无空行分隔 · 单选+多选连排', '''
1. 矛盾的普遍性是指
A. 矛盾无处不在
B. 矛盾只存在于社会
C. 矛盾只存在于自然界
D. 矛盾是主观的
答案：A
2. 量变和质变的辩证关系正确的有
A. 量变是质变的基础
B. 质变是量变的结果
C. 二者无关
D. 质变不需要量变
答案：AB
''');

  // Test 5: Mixed types without blank lines
  _test(parser, '无空行 · 单选+判断+多选混排', '''
1. 马克思主义中国化的科学内涵
A. 把马克思主义同中国实际相结合
B. 照搬马克思主义
C. 否定马克思主义
D. 完全本土化
答案：A
21 中国特色社会主义进入新时代。（√）
答案：√
3. 新时代我国社会主要矛盾
A. 人民日益增长的美好生活需要和不平衡不充分的发展之间的矛盾
B. 人民日益增长的物质文化需要同落后的社会生产之间的矛盾
C. 无产阶级和资产阶级的矛盾
D. 社会主义和资本主义的矛盾
答案：A
''');

  // Test 6: Parenthesized numbers
  _test(parser, '括号编号 · 两题连排', '''
（1）唯物主义和唯心主义的根本区别在于
A. 是否承认世界是可知的
B. 是否承认物质是世界的本原
C. 是否承认世界是运动的
D. 是否承认世界是联系的
答案：B
（2）辩证法的实质和核心是
A. 对立统一规律
B. 质量互变规律
C. 否定之否定规律
D. 联系和发展的观点
答案：A
''');

  // Test 7: 参考答案 prefix
  _test(parser, '参考答案前缀', '''
1. 社会存在决定社会意识是
A. 历史唯物主义观点
B. 历史唯心主义观点
C. 辩证唯物主义观点
D. 形而上学观点
参考答案：A
解析：历史唯物主义认为社会存在决定社会意识。
''');

  // Test 8: Short answer
  _test(parser, '简答题', '''
1. 简述实践是检验真理的唯一标准
答案：实践是检验真理的唯一标准，是由真理的本性和实践的特点决定的。
''');

  // Test 9: Multi-line stem
  _test(parser, '多行题干', '''
1. "两个必然"和"两个决不会"的关系是什么？
"两个必然"指资本主义必然灭亡、社会主义必然胜利。
A. 二者相互矛盾
B. 二者辩证统一
C. 前者否定后者
D. 后者否定前者
答案：B
''');

  // Test 11: Failing unit test — explanation extraction
  _test(parser, '现有测试 · 解析提取', '''
1. 马克思主义基本原理同中国具体实际相结合的哲学依据是
A. 矛盾的普遍性和特殊性辩证关系
B. 量变和质变的辩证关系
C. 主要矛盾和次要矛盾的关系
D. 事物发展前进性和曲折性的统一
答案：A
解析：矛盾的普遍性和特殊性辩证关系原理是马克思主义基本原理同中国具体实际相结合的哲学依据。
''');

  // Test 10: Only blank line separation (original format)
  _test(parser, '空行分隔 · 标准格式', '''
1. 单选题示例
A. 选项一
B. 选项二
C. 选项三
D. 选项四
答案：B

2. 第二道多选题
A. 苹果
B. 香蕉
C. 橘子
D. 葡萄
答案：BCD

3. 判断题
答案：√
''');
}

void _test(HeuristicParser parser, String label, String input) {
  final candidates = parser.parse(input);
  print('═══════ $label ═══════');
  print('题目数: ${candidates.length}');
  for (var i = 0; i < candidates.length; i++) {
    final c = candidates[i];
    final typeStr = c.candidateType.name;
    final mark = _passFail(c);
    print(
      '  [$i] $mark 类型=$typeStr 答案="${c.answer}" 选项数=${c.options.length} 置信度=${c.confidence.toStringAsFixed(2)}',
    );
    final title = c.title.length > 50
        ? '${c.title.substring(0, 50)}...'
        : c.title;
    print('      题干="$title"');
    if (c.explanation.isNotEmpty) {
      final expl = c.explanation.length > 60
          ? '${c.explanation.substring(0, 60)}...'
          : c.explanation;
      print('      解析="$expl"');
    }
  }
  print('');
}

String _passFail(ParseCandidate c) {
  // Simple heuristic: if we have a sensible answer and type, it's likely correct
  if (c.candidateType == CandidateType.unknown) return '✗';
  if (c.answer.isEmpty && c.options.isNotEmpty) return '△';
  return '✓';
}
