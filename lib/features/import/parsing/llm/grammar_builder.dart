// lib/features/import/parsing/llm/grammar_builder.dart
// ── 语法构建器 ──
// 生成 LLM 输出约束用的 JSON Schema 和 GBNF 回退语法。
// JSON Schema 通过 llama.cpp 的 json_schema 参数约束采样。
// GBNF 回退用于不支持 json_schema 的旧版 llama.cpp 服务器。

/// 生成题目解析用的 JSON Schema。
///
/// 该 Schema 约束 LLM 输出为有效的题目 JSON，
/// 包含标题、类型、选项、答案和解析字段。
/// 答案字段通过正则 `^[A-H]+$` 限制为仅大写字母。
Map<String, dynamic> buildQuestionJsonSchema() {
  return {
    'type': 'object',
    'properties': {
      'title': {
        'type': 'string',
        'minLength': 1,
        'description': 'Question stem text',
      },
      'type': {
        'type': 'string',
        'enum': ['single', 'multiple', 'truefalse', 'unknown'],
      },
      'options': {
        'type': 'array',
        'items': {'type': 'string'},
        'minItems': 2,
        'maxItems': 8,
      },
      'answer': {
        'type': 'string',
        'minLength': 1,
        'pattern': r'^[A-H]+$',
        'description': 'Correct answer letter(s), uppercase, e.g. A or ABC',
      },
      'explanation': {
        'type': 'string',
        'description': 'Optional explanation text',
      },
    },
    'required': ['title', 'type', 'options', 'answer'],
    'additionalProperties': false,
  };
}

/// 将 JSON Schema 转换为 GBNF 语法字符串。
///
/// 生成一个简化的 GBNF 语法，用于在不支持 `json_schema` 参数的
/// 旧版 llama.cpp 服务器上约束 LLM 输出格式。
///
/// 注意：这是简化版 GBNF，约束强度低于自动转换的 GBNF。
/// 仅作为回退方案使用。
String jsonSchemaToGbnf(Map<String, dynamic> schema) {
  final buf = StringBuffer();

  // Root production rule
  buf.writeln('root ::= object');

  // Define the JSON object structure
  buf.writeln('object ::= "{" ws '
      '"\\"title\\"" ws ":" ws string ws "," ws '
      '"\\"type\\"" ws ":" ws type-value ws "," ws '
      '"\\"options\\"" ws ":" ws array ws "," ws '
      '"\\"answer\\"" ws ":" ws answer-string ws '
      '("," ws "\\"explanation\\"" ws ":" ws explanation-string ws)? '
      '"}"');

  // Whitespace
  buf.writeln('ws ::= [ \\t\\n]*');

  // String rule (simplified — any characters except unescaped quotes)
  buf.writeln('string ::= "\\"" ([^"\\\\] | "\\\\" .)* "\\""');

  // Answer string (constrained to A-H letters only)
  buf.writeln('answer-string ::= "\\"" [A-H]+ "\\""');
  buf.writeln('explanation-string ::= "\\"" ([^"\\\\] | "\\\\" .)* "\\""');

  // Type enum values
  buf.writeln(
    'type-value ::= '
    '"\\"single\\"" | "\\"multiple\\"" | '
    '"\\"truefalse\\"" | "\\"unknown\\""',
  );

  // Array rule (list of strings)
  buf.writeln(
    'array ::= "[" ws (string ws '
    '("," ws string ws)*)? "]"',
  );

  return buf.toString();
}
