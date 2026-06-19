// test/data/llm_client/http_llm_client_test.dart
// ── HttpLlmClient retry, error, and response parsing tests ──
// Uses a local dart:io HttpServer to mock the llama.cpp /completion endpoint.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/data/llm_client/http_llm_client.dart';
import 'package:redclass/data/llm_client/llm_error.dart';
import 'package:redclass/features/import/parsing/parse_candidate.dart';

const _validResponse = {
  'content':
      '{"title":"测试题","type":"single","options":["A. 选项1","B. 选项2"],'
      '"answer":"A","explanation":""}',
  'stop': true,
};

void main() {
  group('HttpLlmClient', () {
    late HttpServer _server;
    late int _port;
    late int _statusCode;
    late Object? _responseBody;
    late int _responseDelayMs;
    late int _requestCount;
    late String? _capturedBody;
    late String? _capturedContentType;
    late String? _capturedPath;

    setUp(() async {
      _statusCode = 200;
      _responseBody = _validResponse;
      _responseDelayMs = 0;
      _requestCount = 0;
      _capturedBody = null;
      _capturedContentType = null;
      _capturedPath = null;
      _server = await HttpServer.bind('localhost', 0);
      _port = _server.port;
      _server.listen((HttpRequest request) async {
        _requestCount++;
        _capturedPath = request.uri.path;
        _capturedContentType = request.headers.contentType?.mimeType;
        final bodyString = await request
            .cast<List<int>>()
            .transform(utf8.decoder)
            .join();
        _capturedBody = bodyString;

        if (request.method == 'POST' && request.uri.path == '/completion') {
          if (_responseDelayMs > 0) {
            await Future<void>.delayed(
              Duration(milliseconds: _responseDelayMs),
            );
          }
          request.response
            ..statusCode = _statusCode
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(_responseBody));
          await request.response.close();
        } else {
          request.response.statusCode = 404;
          await request.response.close();
        }
      });
    });

    tearDown(() async {
      await _server.close(force: true);
    });

    // ── Constructor tests ──

    test('constructs with default serverUrl, timeout, and maxRetries', () {
      final client = HttpLlmClient();
      expect(client.serverUrl, 'http://localhost:8080');
      expect(client.timeout, const Duration(seconds: 30));
      expect(client.maxRetries, 3);
    });

    test('constructs with custom serverUrl, timeout, and maxRetries', () {
      final client = HttpLlmClient(
        serverUrl: 'http://localhost:9999',
        timeout: const Duration(seconds: 10),
        maxRetries: 5,
      );
      expect(client.serverUrl, 'http://localhost:9999');
      expect(client.timeout, const Duration(seconds: 10));
      expect(client.maxRetries, 5);
    });

    // ── POST request tests ──

    test('parse() sends POST to /completion with Content-Type json', () async {
      final client = HttpLlmClient(
        serverUrl: 'http://localhost:$_port',
      );
      await client.parse('test question');
      expect(_capturedPath, '/completion');
      expect(_capturedContentType, 'application/json');
    });

    test('parse() POST body includes all required fields', () async {
      final client = HttpLlmClient(
        serverUrl: 'http://localhost:$_port',
      );
      await client.parse('什么是光合作用？');

      expect(_capturedBody, isNotNull);
      final body = jsonDecode(_capturedBody!) as Map<String, dynamic>;

      // Required POST body fields per RESEARCH.md
      expect(body['prompt'], contains('什么是光合作用？'));
      expect(body['n_predict'], 512);
      expect(body['temperature'], 0.0);
      expect(body['seed'], 42);
      expect(body['stream'], false);
      expect(body['cache_prompt'], false);
      expect(body['stop'], isA<List>());

      // json_schema field
      final schema = body['json_schema'] as Map<String, dynamic>;
      expect(schema['type'], 'object');
      expect(schema['required'], contains('title'));
      expect(schema['additionalProperties'], false);
    });

    // ── Response parsing tests ──

    test('parse() extracts content and creates ParseCandidate', () async {
      final client = HttpLlmClient(
        serverUrl: 'http://localhost:$_port',
      );
      final candidate = await client.parse('测试题：什么是光合作用？');

      expect(candidate.title, '测试题');
      expect(candidate.candidateType, CandidateType.singleChoice);
      expect(candidate.answer, 'A');
      expect(candidate.options, ['A. 选项1', 'B. 选项2']);
      expect(candidate.explanation, '');
    });

    // ── Error handling tests ──

    test(
      'throws LlmRetryExhaustedException on timeout with timeout details',
      () async {
        _responseDelayMs = 5000; // server delays 5 seconds
        final client = HttpLlmClient(
          serverUrl: 'http://localhost:$_port',
          timeout: const Duration(milliseconds: 200),
          maxRetries: 1,
        );

        await expectLater(
          client.parse('test question'),
          throwsA(
            isA<LlmRetryExhaustedException>().having(
              (e) => e.lastError,
              'lastError',
              contains('timeout'),
            ),
          ),
        );
      },
    );

    test(
      'throws LlmRetryExhaustedException on connection refused',
      () async {
        await _server.close(force: true);
        final client = HttpLlmClient(
          serverUrl: 'http://localhost:$_port',
          maxRetries: 1,
        );

        await expectLater(
          client.parse('test question'),
          throwsA(isA<LlmRetryExhaustedException>()),
        );
      },
    );

    test(
      'retries up to 3 times on non-200 then throws '
      'LlmRetryExhaustedException',
      () async {
        _statusCode = 500;
        final client = HttpLlmClient(
          serverUrl: 'http://localhost:$_port',
          timeout: const Duration(seconds: 5),
        );

        await expectLater(
          client.parse('test question'),
          throwsA(isA<LlmRetryExhaustedException>()),
        );
        // Verify exactly 3 attempts were made
        expect(_requestCount, 3);
      },
    );

    test('throws LlmJsonParseException on invalid JSON (no retry)', () async {
      _responseBody = {
        'content': 'this is not valid json at all !!!',
        'stop': true,
      };
      final client = HttpLlmClient(
        serverUrl: 'http://localhost:$_port',
      );

      await expectLater(
        client.parse('test question'),
        throwsA(isA<LlmJsonParseException>()),
      );
      // JSON parse failures are NOT retried — only 1 request
      expect(_requestCount, 1);
    });

    test('throws LlmJsonParseException when content field is missing', () async {
      _responseBody = {'stop': true};
      final client = HttpLlmClient(
        serverUrl: 'http://localhost:$_port',
      );

      await expectLater(
        client.parse('test question'),
        throwsA(isA<LlmJsonParseException>()),
      );
      expect(_requestCount, 1);
    });

    // ── Metadata tests ──

    test('stores source=llm and bankName in metadata if provided', () async {
      final client = HttpLlmClient(
        serverUrl: 'http://localhost:$_port',
      );
      final candidate = await client.parse('test', bankName: '期中题库');

      expect(candidate.metadata['source'], 'llm');
      expect(candidate.metadata['bankName'], '期中题库');
    });

    test('metadata source is llm and bankName absent when not provided',
        () async {
      final client = HttpLlmClient(
        serverUrl: 'http://localhost:$_port',
      );
      final candidate = await client.parse('test');

      expect(candidate.metadata['source'], 'llm');
      expect(candidate.metadata['bankName'], isNull);
    });

    // ── Edge case: content contains extraneous whitespace ──

    test('trims whitespace from LLM JSON content before parsing', () async {
      _responseBody = {
        'content':
            '  \n{"title":"trim test","type":"multiple",'
            '"options":["A","B","C"],"answer":"AB"}\n  ',
        'stop': true,
      };
      final client = HttpLlmClient(
        serverUrl: 'http://localhost:$_port',
      );
      final candidate = await client.parse('test');

      expect(candidate.title, 'trim test');
      expect(candidate.candidateType, CandidateType.multiChoice);
      expect(candidate.answer, 'AB');
    });

    // ── Construct with different retry counts ──

    test('maxRetries=2 retries twice then throws', () async {
      _statusCode = 500;
      final client = HttpLlmClient(
        serverUrl: 'http://localhost:$_port',
        timeout: const Duration(seconds: 5),
        maxRetries: 2,
      );

      await expectLater(
        client.parse('test question'),
        throwsA(isA<LlmRetryExhaustedException>()),
      );
      expect(_requestCount, 2);
    });
  });
}
