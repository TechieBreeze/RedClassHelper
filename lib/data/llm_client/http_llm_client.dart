// lib/data/llm_client/http_llm_client.dart
// ── HttpLlmClient: POSTs to llama.cpp server with retry, timeout, and
// structured error handling ──
// Placeholder stub — tests will fail until full implementation.

import 'llm_client.dart';
import 'package:redclass/features/import/parsing/parse_candidate.dart';

class HttpLlmClient implements LlmClient {
  final String serverUrl;
  final Duration timeout;
  final int maxRetries;

  const HttpLlmClient({
    this.serverUrl = 'http://localhost:8080',
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
  });

  @override
  Future<ParseCandidate> parse(String rawText, {String? bankName}) async {
    throw UnimplementedError('HttpLlmClient not yet implemented');
  }
}
