// lib/data/llm_client/http_llm_client.dart
// ── HttpLlmClient: POSTs to llama.cpp server with retry, timeout, and
// structured error handling ──
//
// Sends question blocks to the llama.cpp native /completion endpoint
// constrained by json_schema (auto-converted to GBNF by the server).
// Retries up to maxRetries times on timeout and connection errors.
// Does NOT retry on JSON parse failures (the LLM output is non-JSON
// despite GBNF — retrying won't help).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:redclass/features/import/parsing/parse_candidate.dart';

import 'llm_client.dart';
import 'llm_error.dart';

class HttpLlmClient implements LlmClient {
  /// Base URL of the llama.cpp server (default: http://localhost:8080).
  final String serverUrl;

  /// Per-request timeout (default: 30 seconds).
  final Duration timeout;

  /// Maximum number of parse attempts before giving up (default: 3).
  final int maxRetries;

  const HttpLlmClient({
    this.serverUrl = 'http://localhost:8080',
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
  });

  @override
  Future<ParseCandidate> parse(String rawText, {String? bankName}) async {
    String lastError = '';
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await _attemptParse(rawText, bankName: bankName);
      } on LlmTimeoutException {
        lastError = 'timeout on attempt $attempt';
        if (attempt == maxRetries) {
          throw LlmRetryExhaustedException(
            attempts: maxRetries,
            lastError: lastError,
          );
        }
      } on LlmJsonParseException {
        // JSON parse failure is NOT retried — retrying won't fix malformed
        // LLM output.
        rethrow;
      } on LlmConnectionException {
        // Connection failure IS retried — server may be restarting.
        lastError = 'connection refused on attempt $attempt';
        if (attempt == maxRetries) {
          throw LlmRetryExhaustedException(
            attempts: maxRetries,
            lastError: lastError,
          );
        }
      }
    }
    throw LlmRetryExhaustedException(
      attempts: maxRetries,
      lastError: lastError,
    );
  }

  /// Performs a single POST to the llama.cpp /completion endpoint.
  ///
  /// Throws [LlmTimeoutException], [LlmConnectionException], or
  /// [LlmJsonParseException] on failure.
  Future<ParseCandidate> _attemptParse(
    String rawText, {
    String? bankName,
  }) async {
    final uri = Uri.parse('$serverUrl/completion');

    final body = jsonEncode(<String, dynamic>{
      'prompt': _buildPrompt(rawText),
      'n_predict': 512,
      'temperature': 0.0,
      'seed': 42,
      'json_schema': _buildJsonSchema(),
      'stop': ['<|im_end|>'],
      'stream': false,
      'cache_prompt': false,
    });

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        final errorSnippet = response.body.length > 200
            ? response.body.substring(0, 200)
            : response.body;
        throw LlmConnectionException(
          serverUrl: serverUrl,
          originalError: 'HTTP ${response.statusCode}: $errorSnippet',
        );
      }

      return _parseResponse(response.body, rawText, bankName);
    } on TimeoutException {
      throw LlmTimeoutException(timeout: timeout, serverUrl: serverUrl);
    } on FormatException catch (e) {
      throw LlmJsonParseException(
        rawResponse: e.source?.toString() ?? '',
        parseError: e.message,
      );
    } on SocketException catch (e) {
      throw LlmConnectionException(
        serverUrl: serverUrl,
        originalError: e.message,
      );
    } on HttpException catch (e) {
      throw LlmConnectionException(
        serverUrl: serverUrl,
        originalError: e.message,
      );
    } on http.ClientException catch (e) {
      throw LlmConnectionException(
        serverUrl: serverUrl,
        originalError: e.message,
      );
    }
  }

  /// Parses the llama.cpp response JSON into a [ParseCandidate].
  ///
  /// The llama.cpp /completion response format:
  /// ```json
  /// { "content": "{...question JSON...}", "stop": true, ... }
  /// ```
  ///
  /// The inner `content` string is the LLM's JSON output matching our schema.
  /// This method extracts and validates it.
  ParseCandidate _parseResponse(
    String body,
    String rawText,
    String? bankName,
  ) {
    // Step 1: Parse the llama.cpp wrapper JSON
    final Map<String, dynamic> wrapper;
    try {
      wrapper = jsonDecode(body) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw LlmJsonParseException(
        rawResponse: body,
        parseError: 'Failed to parse llama.cpp wrapper JSON: ${e.message}',
      );
    }

    // Step 2: Extract the content string (LLM's output)
    final content = wrapper['content'];
    if (content is! String || content.trim().isEmpty) {
      throw LlmJsonParseException(
        rawResponse: body,
        parseError: 'Response content is empty or missing',
      );
    }

    // Step 3: Parse the LLM's output as JSON
    final Map<String, dynamic> llmJson;
    try {
      llmJson = jsonDecode(content.trim()) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw LlmJsonParseException(
        rawResponse: content,
        parseError: e.message,
      );
    }

    // Step 4: Map LLM field names to ParseCandidate field names
    final candidateJson = <String, dynamic>{
      'rawText': rawText,
      'candidateType': _mapCandidateType(
        llmJson['type'] as String? ?? 'unknown',
      ),
      'title': llmJson['title'] as String? ?? '',
      'options':
          (llmJson['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      'answer': llmJson['answer'] as String? ?? '',
      'explanation': llmJson['explanation'] as String? ?? '',
    };

    // Step 5: Create ParseCandidate via fromJson
    final candidate = ParseCandidate.fromJson(candidateJson);

    // Step 6: Add metadata
    return candidate.copyWith(
      metadata: {
        'source': 'llm',
        if (bankName != null) 'bankName': bankName,
      },
    );
  }

  /// Maps LLM type field values to ParseCandidate candidateType enum values.
  String _mapCandidateType(String llmType) {
    return switch (llmType) {
      'single' => 'single_choice',
      'multiple' => 'multi_choice',
      'truefalse' => 'true_false',
      'short_answer' => 'short_answer',
      _ => 'unknown',
    };
  }

  /// Builds the Qwen2.5 chat-template prompt.
  ///
  /// Uses `<|im_start|>` / `<|im_end|>` tokens for the Qwen2.5 family.
  /// The system message instructs the model to output ONLY valid JSON
  /// matching the schema.
  String _buildPrompt(String rawText) {
    return '<|im_start|>system\n'
        'Extract the following Chinese exam question into JSON.\n'
        'Output ONLY valid JSON matching the schema. '
        'No prose. No markdown fences. End with }.<|im_end|>\n'
        '<|im_start|>user\n'
        '$rawText<|im_end|>\n'
        '<|im_start|>assistant\n';
  }

  /// Builds the JSON Schema for question extraction.
  ///
  /// llama.cpp auto-converts this to GBNF grammar to constrain LLM output.
  Map<String, dynamic> _buildJsonSchema() {
    return const {
      'type': 'object',
      'properties': {
        'title': {'type': 'string', 'minLength': 1},
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
        'answer': {'type': 'string', 'minLength': 1},
        'explanation': {'type': 'string'},
      },
      'required': ['title', 'type', 'options', 'answer'],
      'additionalProperties': false,
    };
  }
}
