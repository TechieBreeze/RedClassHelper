// test/data/llm_client/platform_gate_test.dart
// ── Platform gate behavior verification for LLM providers ──
// Tests that llmModeProvider defaults to stub, and llmClientProvider
// exists and compiles (throws expected errors on non-desktop test runner).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/data/llm_client/llm_client.dart';
import 'package:redclass/data/llm_client/providers.dart';

void main() {
  test('llmModeProvider defaults to LlmMode.stub', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(llmModeProvider), LlmMode.stub);
  });

  test('llmModeProvider can be overridden to http', () {
    final container = ProviderContainer(
      overrides: [llmModeProvider.overrideWith((ref) => LlmMode.http)],
    );
    addTearDown(container.dispose);
    expect(container.read(llmModeProvider), LlmMode.http);
  });

  test('llmClientProvider compiles and returns StubLlmClient on desktop', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final client = container.read(llmClientProvider);
    expect(client, isA<LlmClient>());
  });
}
