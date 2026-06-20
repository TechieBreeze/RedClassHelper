---
phase: 3
slug: desktop-llm-integration-parse-quality
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-19
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test + dart:test |
| **Config file** | none — flutter test uses default |
| **Quick run command** | `flutter test` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | IMP-03 | T-03-01 / — | Platform gate prevents LLM on Android | unit | `flutter test test/unit/llm/` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/unit/llm/` — test stubs for LlmClient implementations
- [ ] `test/unit/llm/llm_client_test.dart` — abstract interface contract tests
- [ ] `test/unit/llm/stub_llm_client_test.dart` — stub fixture tests
- [ ] `test/unit/llm/http_llm_client_test.dart` — HTTP client tests (mock server)
- [ ] `test/unit/llm/canonicalization_test.dart` — answer normalization tests

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| LLM parsing end-to-end with real model | IMP-03 | Requires running llama.cpp server with actual GGUF model | 1. Start llama-server with Qwen2.5-1.5B 2. Import doc/example/ PDF 3. Verify parse results correct 4. Verify source badges on summary screen |
| Model download with resume | IMP-03 | Network condition variability | 1. Start model download 2. Kill app mid-download 3. Restart app and verify resume |
| Model management page UX | IMP-03 | Visual verification | 1. Open /settings/models 2. Verify installed/catalog/custom sections 3. Download a model and verify progress bar |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
