// test/data/llm_client/llm_client_test.dart
// ── Unit tests for LlmClient interface and LlmError types ──

import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/data/llm_client/llm_client.dart';
import 'package:redclass/data/llm_client/llm_error.dart';

void main() {
  group('LlmMode enum', () {
    test('LlmMode.values contains exactly stub and http', () {
      expect(LlmMode.values, orderedEquals([LlmMode.stub, LlmMode.http]));
      expect(LlmMode.values.length, 2);
    });
  });

  group('LlmTimeoutException', () {
    test('stores constructor fields and formats message correctly', () {
      final timeout = const Duration(seconds: 30);
      const serverUrl = 'http://localhost:8080';
      final ex = LlmTimeoutException(timeout: timeout, serverUrl: serverUrl);

      expect(ex.timeout, timeout);
      expect(ex.serverUrl, serverUrl);
      expect(
        ex.message,
        'LLM request to $serverUrl timed out after ${timeout.inSeconds}s',
      );
      expect(ex.toString(), ex.message);
    });
  });

  group('LlmJsonParseException', () {
    test('stores rawResponse and parseError and formats message correctly', () {
      const rawResponse = '{"bad json"';
      const parseError = 'Unexpected end of input';
      final ex = LlmJsonParseException(
        rawResponse: rawResponse,
        parseError: parseError,
      );

      expect(ex.rawResponse, rawResponse);
      expect(ex.parseError, parseError);
      expect(ex.message, 'Failed to parse LLM JSON output: $parseError');
      expect(ex.toString(), ex.message);
    });
  });

  group('LlmRetryExhaustedException', () {
    test('stores attempts and lastError and formats message correctly', () {
      const attempts = 3;
      const lastError = 'Connection refused';
      final ex = LlmRetryExhaustedException(
        attempts: attempts,
        lastError: lastError,
      );

      expect(ex.attempts, attempts);
      expect(ex.lastError, lastError);
      expect(
        ex.message,
        'LLM parsing failed after $attempts retries. Last error: $lastError',
      );
      expect(ex.toString(), ex.message);
    });

    test('attempts=0 is constructable (no validation in constructor)', () {
      final ex = LlmRetryExhaustedException(attempts: 0, lastError: 'test');
      expect(ex.attempts, 0);
      // Constructor allows 0; convention is callers pass >= 1
    });
  });

  group('LlmConnectionException', () {
    test(
      'stores serverUrl and originalError; formats message when originalError is null',
      () {
        const serverUrl = 'http://localhost:8080';
        final exNullError = LlmConnectionException(serverUrl: serverUrl);

        expect(exNullError.serverUrl, serverUrl);
        expect(exNullError.originalError, isNull);
        expect(
          exNullError.message,
          'Cannot connect to LLM server at $serverUrl: connection refused',
        );
        expect(exNullError.toString(), exNullError.message);
      },
    );

    test('formats message correctly when originalError is provided', () {
      const serverUrl = 'http://localhost:8080';
      const originalError = 'Connection refused (OS Error: 111)';
      final ex = LlmConnectionException(
        serverUrl: serverUrl,
        originalError: originalError,
      );

      expect(ex.serverUrl, serverUrl);
      expect(ex.originalError, originalError);
      expect(
        ex.message,
        'Cannot connect to LLM server at $serverUrl: $originalError',
      );
      expect(ex.toString(), ex.message);
    });
  });
}
