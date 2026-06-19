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

  test('llmClientProvider compiles and is accessible', () {
    // This test verifies the provider exists and compiles.
    // On non-desktop test runner, it will throw UnsupportedError.
    // On desktop, it throws UnimplementedError until Stub/Http are wired.
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // Read the provider — it will throw but we verify it exists.
    // Riverpod wraps provider-internal errors in ProviderException, so
    // the thrown type is ProviderException, not the original error.
    // On non-desktop: UnsupportedError wrapped in ProviderException.
    // On desktop (current): UnimplementedError wrapped in ProviderException.
    expect(
      () => container.read(llmClientProvider),
      throwsA(isA<Exception>()),
    );
  });
}
