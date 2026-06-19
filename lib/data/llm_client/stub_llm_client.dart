// lib/data/llm_client/stub_llm_client.dart
// ── StubLlmClient: deterministic LlmClient returning canned fixtures ──
// Zero-dependency implementation for CI, widget testing, and local dev.
// No network, no model download, no server process.
//
// Fixtures are lazy-loaded from the asset bundle on first parse() call.
// For testing, pass [fixtures] directly to bypass asset loading.

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'llm_client.dart';
import 'package:redclass/features/import/parsing/parse_candidate.dart';

class StubLlmClient implements LlmClient {
  /// Pre-loaded fixture data for testing. When non-null, asset loading is
  /// skipped entirely.
  final Map<String, dynamic>? _testFixtures;

  /// Lazily-loaded fixture map from asset bundle.
  Map<String, dynamic>? _fixtures;

  /// Creates a [StubLlmClient].
  ///
  /// In production, use the default constructor which loads fixtures from
  /// `assets/fixtures/sample_llm_response.json` via [rootBundle].
  ///
  /// In tests, pass [fixtures] to inject canned data directly:
  /// ```dart
  /// StubLlmClient(fixtures: myTestData);
  /// ```
  StubLlmClient({Map<String, dynamic>? fixtures})
      : _testFixtures = fixtures;

  /// Loads fixtures from the asset bundle (lazy, cached).
  Future<Map<String, dynamic>> _loadFixtures() async {
    if (_fixtures != null) return _fixtures!;
    if (_testFixtures != null) {
      _fixtures = _testFixtures;
      return _fixtures!;
    }
    final jsonStr =
        await rootBundle.loadString('assets/fixtures/sample_llm_response.json');
    _fixtures = jsonDecode(jsonStr) as Map<String, dynamic>;
    return _fixtures!;
  }

  /// Selects a fixture key based on keyword patterns in [rawText].
  ///
  /// - Text containing "以下哪些" / "属于" / "包括" → "multi"
  /// - Text containing "正确" / "错误" / "判断" / "对错" → "truefalse"
  /// - All other text → "default"
  String _selectFixtureKey(String rawText) {
    if (RegExp(r'以下哪些|属于|包括').hasMatch(rawText)) return 'multi';
    if (RegExp(r'正确|错误|判断|对错').hasMatch(rawText)) return 'truefalse';
    return 'default';
  }

  @override
  Future<ParseCandidate> parse(String rawText, {String? bankName}) async {
    final fixtures = await _loadFixtures();
    final key = _selectFixtureKey(rawText);
    final entry = (fixtures[key] ?? fixtures['default']!) as Map<String, dynamic>;

    return ParseCandidate(
      rawText: rawText,
      candidateType: _parseType(entry['type'] as String),
      title: entry['title'] as String,
      options: List<String>.from(entry['options'] as List),
      answer: entry['answer'] as String,
      explanation: (entry['explanation'] as String?) ?? '',
      confidence: 1.0,
      metadata: {
        'source': 'stub',
        if (bankName != null) 'bankName': bankName,
      },
    );
  }

  /// Maps the fixture type string to a [CandidateType] enum value.
  CandidateType _parseType(String typeStr) {
    return switch (typeStr) {
      'single' => CandidateType.singleChoice,
      'multiple' => CandidateType.multiChoice,
      'truefalse' => CandidateType.trueFalse,
      _ => CandidateType.singleChoice,
    };
  }
}
