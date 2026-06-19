// lib/data/llm_client/providers.dart
// ── LLM 客户端 Riverpod providers ──
// 平台门控：Android/iOS 上访问 llmClientProvider 抛出 UnsupportedError。
// 桌面端根据 LlmMode 切换具体实现（StubLlmClient / HttpLlmClient）。

import 'dart:io' show Platform;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'llm_client.dart';
import 'http_llm_client.dart';
import 'stub_llm_client.dart';
import 'ffi_llm_client.dart';

part 'providers.g.dart';

/// LLM 客户端模式——默认 stub。
///
/// 用户在设置页（Phase 6）切换模式。
/// 此 provider 不执行平台检查——模式的值在所有平台上都可自由读取。
@riverpod
LlmMode llmMode(Ref ref) => LlmMode.stub;

/// LLM 客户端实例——平台门控。
///
/// 在非桌面平台（Android/iOS）上访问此 provider 抛出 [UnsupportedError]。
/// 在桌面平台上根据 [llmModeProvider] 的值切换具体实现：
///   - [LlmMode.stub] → [StubLlmClient] (deterministic, for dev/CI)
///   - [LlmMode.http] → [HttpLlmClient] (local llama-server)
///   - [LlmMode.ffi]  → [FfiLlmClient] (dart:ffi direct binding)
@Riverpod(keepAlive: true)
LlmClient llmClient(Ref ref) {
  if (!(Platform.isWindows || Platform.isLinux)) {
    throw UnsupportedError(
      'LLM is desktop-only; use JSON import on Android',
    );
  }

  final mode = ref.watch(llmModeProvider);
  return switch (mode) {
    LlmMode.stub => StubLlmClient(),
    LlmMode.http => HttpLlmClient(
      serverUrl: 'http://localhost:8080',
      timeout: const Duration(seconds: 30),
    ),
    LlmMode.ffi => FfiLlmClient(
      modelPath: '', // populated from settings/ModelManager in Phase 6
      timeout: const Duration(seconds: 60),
    ),
  };
}
