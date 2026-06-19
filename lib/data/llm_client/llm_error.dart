// lib/data/llm_client/llm_error.dart
// ── LLM 客户端结构化异常类型 ──
// 所有异常都实现 Exception，包含类型特定的字段和格式化的消息。

/// 请求 LLM 服务超时时抛出。
///
/// 携带超时时长和服务端地址，便于日志记录和用户提示。
class LlmTimeoutException implements Exception {
  LlmTimeoutException({
    required this.timeout,
    required this.serverUrl,
  });

  /// 超时时长
  final Duration timeout;

  /// 请求的目标服务器地址
  final String serverUrl;

  /// 格式化错误消息
  String get message =>
      'LLM request to $serverUrl timed out after ${timeout.inSeconds}s';

  @override
  String toString() => message;
}

/// LLM 输出 JSON 解析失败时抛出。
///
/// 携带原始响应文本和解析错误详情，便于调试。
class LlmJsonParseException implements Exception {
  LlmJsonParseException({
    required this.rawResponse,
    required this.parseError,
  });

  /// LLM 返回的原始文本（格式错误的 JSON）
  final String rawResponse;

  /// JSON 解析器报告的错误
  final String parseError;

  /// 格式化错误消息
  String get message => 'Failed to parse LLM JSON output: $parseError';

  @override
  String toString() => message;
}

/// LLM 解析重试次数耗尽时抛出。
///
/// 携带已尝试次数和最后一次失败的错误信息。
class LlmRetryExhaustedException implements Exception {
  LlmRetryExhaustedException({
    required this.attempts,
    required this.lastError,
  });

  /// 已尝试的解析次数（约定 >= 1，构造器不作强制校验）
  final int attempts;

  /// 最后一次尝试的错误信息
  final String lastError;

  /// 格式化错误消息
  String get message =>
      'LLM parsing failed after $attempts retries. Last error: $lastError';

  @override
  String toString() => message;
}

/// 无法连接到 LLM 服务时抛出。
///
/// 携带目标服务器地址和可选的原始错误信息。
class LlmConnectionException implements Exception {
  LlmConnectionException({
    required this.serverUrl,
    this.originalError,
  });

  /// 请求的目标服务器地址
  final String serverUrl;

  /// 底层连接错误（可为空）
  final String? originalError;

  /// 格式化错误消息
  String get message =>
      'Cannot connect to LLM server at $serverUrl: ${originalError ?? 'connection refused'}';

  @override
  String toString() => message;
}
