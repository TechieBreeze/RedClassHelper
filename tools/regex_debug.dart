void main() {
  const text = '解析：矛盾的普遍性和特殊性辩证关系原理是马克思主义基本原理同中国具体实际相结合的哲学依据。';

  // Exact original regex from heuristic_parser.dart
  final orig = RegExp(
    r'(?:解析|解释|答案[解解]析)\s*[：:]\s*(.+?)(?=\n(?:\d{1,4}[）.、]|\s*(?:答案|参考|正确|解析|解释)|$))',
    multiLine: true,
    dotAll: true,
  );
  print('Original: ${orig.firstMatch(text) != null}');
  if (orig.firstMatch(text) != null)
    print('  => "${orig.firstMatch(text)!.group(1)}"');

  // Test each part
  print('');
  print('--- Piece-wise ---');

  // Part A: prefix
  final pA = RegExp(r'(?:解析|解释|答案[解解]析)\s*[：:]');
  print('Prefix: ${pA.hasMatch(text)}');

  // Part B: prefix + content
  final pB = RegExp(r'(?:解析|解释|答案[解解]析)\s*[：:]\s*(.+)');
  print('Prefix+content: ${pB.firstMatch(text) != null}');
  if (pB.firstMatch(text) != null)
    print('  => "${pB.firstMatch(text)!.group(1)}"');

  // Part C: with lazy .+? and simple $
  final pC = RegExp(
    r'(?:解析|解释|答案[解解]析)\s*[：:]\s*(.+?)$',
    multiLine: true,
    dotAll: true,
  );
  print('Prefix+content+lazy+\$: ${pC.firstMatch(text) != null}');
  if (pC.firstMatch(text) != null)
    print('  => "${pC.firstMatch(text)!.group(1)}"');

  // Part D: full lookahead
  final lookahead = RegExp(r'(?=\n(?:\d{1,4}[）.、]|\s*(?:答案|参考|正确|解析|解释)|$))');
  print('Lookahead alone: ${lookahead.hasMatch('\n1. next')}');
  print('Lookahead end: ${lookahead.hasMatch('')}');
  print('Lookahead on text: ${lookahead.hasMatch(text)}');

  // Part E: lookahead needs to match at the END of the string
  final pE = RegExp(r'(.+?)(?=$)', multiLine: true, dotAll: true);
  print('.+?\$: ${pE.firstMatch(text)?.group(1) ?? "NO MATCH"}');

  // Part F: the lookahead after prefix
  final pF = RegExp(
    r'(?:解析)\s*[：:]\s*(.+?)(?=$)',
    multiLine: true,
    dotAll: true,
  );
  print('parse .+? \$: ${pF.firstMatch(text)?.group(1) ?? "NO MATCH"}');

  // Part G: try the full lookahead but simplified
  final pG = RegExp(
    r'(?:解析)\s*[：:]\s*(.+?)(?=\n\d|$)',
    multiLine: true,
    dotAll: true,
  );
  print(
    'parse .+? (\\n\\d|\$): ${pG.firstMatch(text)?.group(1) ?? "NO MATCH"}',
  );

  // Part H: the alternation with \s*
  final pH = RegExp(
    r'(?:解析)\s*[：:]\s*(.+?)(?=\n\d|\s*答案|$)',
    multiLine: true,
    dotAll: true,
  );
  print(
    'parse .+? (\\n\\d|\\s*答案|\$): ${pH.firstMatch(text)?.group(1) ?? "NO MATCH"}',
  );

  // What about: the exact alternation?
  final pI = RegExp(
    r'(?:解析)\s*[：:]\s*(.+?)(?=\n(?:\d|\s*(?:答案))|$)',
    multiLine: true,
    dotAll: true,
  );
  print(
    'parse .+? (\\n(?:\\d|\\s*(?:答案))|\$): ${pI.firstMatch(text)?.group(1) ?? "NO MATCH"}',
  );

  // The exact structure: \n followed by (alt1 | alt2 | alt3) or $
  // wait, the original regex has: (?=\n(?:alt1|alt2)|$)
  // Let me check: does the \n grouping matter?
  final pJ = RegExp(
    r'(?:解析)\s*[：:]\s*(.+?)(?=\n(?:\d|答案)|$)',
    multiLine: true,
    dotAll: true,
  );
  print(
    'parse .+? (\\n(?:\\d|答案)|\$): ${pJ.firstMatch(text)?.group(1) ?? "NO MATCH"}',
  );

  // Test the FULL exact regex piece by piece
  final pK = RegExp(
    r'(?:解析|解释|答案[解解]析)\s*[：:]\s*(.+?)(?=\n(?:\d{1,4}[）.、]|\s*(?:答案|参考|正确|解析|解释)|$))',
    multiLine: true,
    dotAll: true,
  );
  // Test on a string that has a newline BEFORE the dollar sign match
  final testText = '解析：test\n1. next';
  print('\npK on text with newline: ${pK.firstMatch(testText) != null}');
  if (pK.firstMatch(testText) != null)
    print('  => "${pK.firstMatch(testText)!.group(1)}"');

  // Test \n in the regex: is it matching something it shouldn't?
  print('\n--- Debug \n ---');
  final nlRe = RegExp(r'\n');
  print('text has newline: ${nlRe.hasMatch(text)}');

  // WAIT: what if the lookahead has \n at the start but there's an alternative at $
  // and the alternation somehow breaks?
  final lookaheadDetailed = RegExp(r'(?=\n(?:x)|$)');
  print('LA \\n x|\$ on empty: ${lookaheadDetailed.hasMatch("")}');
  print('LA \\n x|\$ on x: ${lookaheadDetailed.hasMatch("x")}');
  print('LA \\n x|\$ on \\nx: ${lookaheadDetailed.hasMatch("\nx")}');
}
