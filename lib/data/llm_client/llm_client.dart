// lib/data/llm_client/llm_client.dart
// ── LlmClient 抽象接口 + LlmMode 枚举 ──
// 解析管道代码只依赖此接口，永远不依赖具体实现类。
// 具体实现：StubLlmClient (03-02), HttpLlmClient (03-03), FfiLlmClient (03-08)

import 'package:redclass/features/import/parsing/parse_candidate.dart';

/// LLM 客户端模式——控制使用哪一个 [LlmClient] 实现。
///
/// [stub]: 使用预置 fixture 数据，用于开发/CI。
/// [http]:  通过 HTTP POST 到本地 llama.cpp 服务器。
/// [ffi]:   通过 dart:ffi 直接绑定 llama.cpp 共享库，无需独立服务器进程。
enum LlmMode { stub, http, ffi }

/// LLM 客户端抽象接口。
///
/// 所有解析管道代码应引用此接口，而非任何具体实现。
/// 通过 [LlmMode] 和 Riverpod provider 在运行时切换实现。
abstract interface class LlmClient {
  /// 解析原始题目文本为结构化候选。
  ///
  /// 参数：
  ///   [rawText]: 待解析的原始题目文本块。
  ///   [bankName]: 题库名称（可选），用于 LLM 提示词上下文。
  ///
  /// 返回一个 [ParseCandidate]，包含解析后的题目、选项、答案和置信度。
  ///
  /// 可能抛出：
  ///   - [LlmTimeoutException]: 请求超时
  ///   - [LlmJsonParseException]: LLM 输出 JSON 格式错误
  ///   - [LlmRetryExhaustedException]: 多次重试后仍失败
  ///   - [LlmConnectionException]: 无法连接到 LLM 服务
  Future<ParseCandidate> parse(String rawText, {String? bankName});
}
