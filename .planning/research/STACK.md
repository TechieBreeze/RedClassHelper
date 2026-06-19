# Stack Research

**Domain:** Local cross-platform Flutter desktop+mobile study/review tool with on-device LLM parsing
**Researched:** 2026-06-19
**Confidence:** HIGH (Flutter, sqflite/drift, go_router, Material 3, file_picker, llm.cpp packaging) / MEDIUM (on-device LLM on low-end Android, docx parsing)

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Flutter SDK | 3.35.7 stable (2025-12-04) | UI framework, single codebase → Windows + Android | Latest stable channel as of Dec 2025; ships with Dart 3.9.2; first-class Windows + Android targets; 2026 release cadence is roughly quarterly (3.36 in Feb, 3.37 in May, etc.) so upgrading forward is painless. |
| Dart | 3.9.2 (bundled) | Language runtime | Required by Flutter 3.35.x; no-decision. |
| Material 3 (built-in) | bundled | UI component system | `useMaterial3: true` is the default since Flutter 3.16; gives modern look without extra packages. |

### State Management & Routing

| Library | Version | Purpose | Why Recommended |
|---------|---------|---------|-----------------|
| `flutter_riverpod` | ^3.3.2 | State management + DI | Compile-safe provider graph, built-in `AsyncValue` (ideal for LLM parsing progress / DB queries), no `BuildContext` lookups, easy to share the wrong-question ledger across the three review modes via a `StateNotifier`/`AsyncNotifier`. Riverpod 3.x removed the `ConsumerWidget.context` inheritance confusion. |
| `riverpod_annotation` + `riverpod_generator` | latest | Code generation for `@riverpod` providers | Reduces boilerplate; pair with `build_runner` (latest, 2.5.x line). |
| `go_router` | ^17.3.0 | Declarative routing | Officially maintained by `flutter.dev`, Flutter Favorite, currently in stability/bug-fix mode (feature-complete). More than enough for ~6–8 screens (Home, BankList, Quiz, WrongReview, Stats, Bookmarks, Import). URL/deep-link support is free for free. |
| `freezed` + `freezed_annotation` | ^3.x | Immutable state classes / unions for `QuestionType` and `ReviewMode` | The three review modes + single/multiple-choice are a natural `sealed class` / discriminated-union pattern; `freezed` gives exhaustive `when`/`switch` checks. |
| `json_serializable` + `json_annotation` | latest | JSON parsing for the LLM response | The LLM returns structured JSON; type-safe deserialization prevents runtime parse errors. |

### Persistence

| Library | Version | Purpose | Why Recommended |
|---------|---------|---------|-----------------|
| `drift` | ^2.34.0 | Type-safe SQLite ORM | Flutter Favorite, **reactive** streams (`Stream<List<Question>>`) — fits perfectly with Riverpod's `StreamProvider` for the wrong-question ledger. Generated types catch schema mismatches at build time; complex joins and migrations are first-class. Cross-platform: Android, iOS, Windows, macOS, Linux, Web. |
| `drift_dev` | matching version | Code generator for drift | Required dev-dep. |
| `sqlite3_flutter_libs` | latest | Bundles native SQLite on platforms without a system lib | Provides prebuilt SQLite for Android (armv7/arm64/x86/x64) and Windows (x64/x86/arm64) so drift doesn't need a separate `sqlite3.dll` shipping step. |
| `path_provider` | ^2.1.6 | Resolve the writable app directory | Cross-platform path helpers for both Windows (`getApplicationDocumentsDirectory()` → `%LOCALAPPDATA%`) and Android (`getApplicationDocumentsDirectory()` → app-private). |
| `shared_preferences` | ^2.5.5 | Tiny key-value settings (theme, last-active bank ID) | Only for non-question settings; questions live in drift. Use the new `SharedPreferencesAsync` API (legacy `SharedPreferences` will be deprecated). |

### Document Parsing

| Library | Version | Purpose | Why Recommended |
|---------|---------|---------|-----------------|
| `file_picker` | ^11.0.2 | Native file/directory picker | Confirmed Windows + Android support; `pickFiles()` with `allowedExtensions: ['pdf', 'docx']` and `type: FileType.custom` is exactly what the import flow needs. |
| `pdfx` | ^2.9.2 | Render + text-extract PDFs | Officially supports **Windows** (via PDFium), Android (PdfRenderer), iOS, macOS, Web. Run `flutter pub run pdfx:install_windows` once after `pub get` to wire PDFium into `CMakeLists.txt`. Lazy page-by-page text extraction is a good match for the streaming-parser use case. |
| `syncfusion_flutter_pdf` | ^33.2.13+1 | **Alternative** PDF parser (text-only) | Pure-Dart text extraction via `PdfTextExtractor`. Caveat: Syncfusion positions the package as "mobile and web"; Windows desktop text extraction *works in principle* but is not officially guaranteed — must be smoke-tested before committing. **Requires** a Syncfusion Community Licence (free for small orgs) — license cost is a real consideration. |
| `archive` | ^4.0.9 | Unzip `.docx` (which is a ZIP) | `.docx` is a ZIP of XML parts (`word/document.xml`, `word/header*.xml`, `word/footer*.xml`). `archive` reads those parts into bytes; pair with `xml` (^6.x) to walk the WordprocessingML tree. |
| `xml` | ^6.5.0 | Parse WordprocessingML XML | The Dart-team XML parser; supports the streaming/cursor API needed for large docx without loading the whole tree. |
| `cross_file` | (transitive via file_picker) | Cross-platform `XFile` abstraction | Already pulled in by `file_picker`; just use it. |

> **Honest note on .docx:** As of mid-2026 there is **no mature, widely-adopted pure-Dart `.docx` reader package on pub.dev** — the names `docx` and `dart_docx` 404; `docx_template` only writes templates and is templated-control-tag-specific. The `archive + xml` combo is the realistic path. A future option is a sidecar helper that uses the OS to convert `.docx → .pdf` or `.docx → plaintext` and then re-uses the PDF parser, but that adds platform-channel code and is **out of scope for v1**.

### On-Device LLM

| Component | Recommendation | Why |
|-----------|---------------|-----|
| Inference engine | **llama.cpp** (the `ggml-org/llama.cpp` repo, current release b9717+) via **`dart:ffi`** | The only realistic cross-platform (Windows + Android + macOS + iOS) engine with prebuilt GGUF loaders and active maintenance. Prebuilt binaries ship for **Windows x64 CPU/Vulkan/CUDA** and **Android arm64** as official release assets — we can `AssetManager` the model and `DynamicLibrary.open('libllama.so')` on Android, and `DynamicLibrary.open('llama.dll')` on Windows. |
| Flutter binding strategy | **No maintained wrapper exists for both Windows + Android simultaneously.** `flutter_llama` 1.1.2 only supports Android/iOS/macOS. Roll our own thin FFI wrapper over llama.cpp's `llama.h` C API. | Realistic on-device LLM on Flutter is genuinely hard — confidence here is **MEDIUM**. The Dart side declares the FFI signatures (`@Native` or `package:ffi`), loads the right `.dll`/`.so` from app assets, and wraps `llama_load_model`, `llama_new_context`, `llama_tokenize`, `llama_decode`, `llama_sampling_*`, and the streaming sampler. |
| Default model (Android, low-end) | **Qwen2.5-1.5B-Instruct, Q4_K_M quant (~1.1 GB)** or **Phi-3.5-mini (3.8B), Q4_K_M quant (~2.3 GB)**, or **Gemma-2-2B-it, Q4_K_M (~1.6 GB)** | Qwen2.5-1.5B has the best Chinese/English instruction-following at its size and handles JSON output reliably enough for question parsing — critical because Chinese university exam stems are in Chinese. Use Q4_K_M; Q5/Q8 rarely worth the RAM cost on a phone. |
| Default model (Windows desktop) | Same GGUF, Q5_K_M or Q8_0 quant | Desktop has RAM to spare; higher quant = better parsing accuracy on gnarly formatting. |
| Streaming UX | Wrap `llama_sampling_accept` + per-token `llama_decode`; expose as `Stream<String>` from the FFI layer and surface through a Riverpod `AsyncNotifier` (parsing progress + partial text). | Lets the UI show "已解析 23/100 题" without blocking the isolate. |
| Alternative if FFI proves too brittle | **Qwen2.5-1.5B ONNX** + `onnxruntime` 1.4.1 (Android/iOS/Windows supported) or **`tflite_flutter` 0.12.1** (also Android/iOS/Windows supported, but Windows needs a manual `libtensorflowlite_c-win.dll` build step). | TFLite/ONNX inference is slightly easier than llama.cpp, but converting chat-tuned models to ONNX for chat-quality outputs is non-trivial — if you go this route pick a model that has published ONNX exports. |

> **Realism check (Android):** a phone with **4 GB RAM cannot reliably run a 7B model** even at Q4. The 1.5B/2B/3.8B tier is the realistic envelope. On 8 GB phones with Vulkan, the 3.8B Q4_K_M will work but slow (single-digit tokens/sec). Document this in the user-facing model-picker UI: "Recommended / Fast / Experimental" tiers.

### UI

| Library | Version | Purpose | Why Recommended |
|---------|---------|---------|-----------------|
| Material 3 (`flutter/material.dart`) | bundled | Components | Default M3 widgets, `useMaterial3: true`, no extra deps. |
| `flex_color_scheme` | ^8.4.0 | M3 theme polish | Optional but worth it if the user wants seeded ColorScheme, surface blends, and consistent component themes without writing a `ThemeData` from scratch. Skip it if sticking with stock M3 is preferred. |
| `intl` | ^0.20.2 | Date/time formatting | For "答题于 3 天前" / stats date labels. |

### Dev Tooling

| Tool | Purpose | Notes |
|------|---------|-------|
| `flutter doctor` | Environment validation | Run after installing Flutter + Android SDK + Visual Studio 2022 (Windows desktop). |
| `build_runner` | Code generation for `freezed`, `json_serializable`, `drift`, `riverpod_generator` | One dev-dep runs them all. Watch mode: `dart run build_runner watch --delete-conflicting-outputs`. |
| `very_good_analysis` (optional) | Lint rules | Tighter than `flutter_lints`. Optional — pick whatever lint set the user is comfortable with. |
| `flutter_test` + `integration_test` | Testing | `integration_test` for end-to-end on a real Android device + Windows runner. |

---

## Installation

```bash
# One-time setup
flutter doctor                          # confirm Android SDK + Visual Studio present
flutter config --enable-windows-desktop # enable Windows target on Linux/macOS dev (no-op on Windows)

# Create the project
flutter create --platforms=windows,android --org com.redclass redclass
cd redclass

# Runtime deps
flutter pub add flutter_riverpod \
  riverpod_annotation \
  go_router \
  freezed_annotation \
  json_annotation \
  drift \
  sqlite3_flutter_libs \
  path_provider \
  shared_preferences \
  file_picker \
  pdfx \
  archive \
  xml \
  intl

# Dev deps
flutter pub add --dev build_runner \
  riverpod_generator \
  freezed \
  json_serializable \
  drift_dev

# Post-install one-shot
flutter pub run pdfx:install_windows    # patches windows/CMakeLists.txt for PDFium
dart run build_runner build --delete-conflicting-outputs
```

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| `flutter_riverpod` 3.x | `flutter_bloc` 9.1.1 | Bloc is great for explicit event-sourced state machines, but for this app (mode-driven, shared wrong-question ledger) Riverpod's `AsyncNotifier` + `StreamProvider` is more direct. Bloc shines when you need a formal audit trail of events (e.g. replayable logs) — not the case here. |
| `flutter_riverpod` 3.x | `provider` 6.x | Provider is fine but lacks compile-time safety and first-class async value semantics; for a 2026 greenfield project, Riverpod is the stronger default. |
| `drift` 2.34 | `sqflite` + `sqflite_common_ffi` 2.4.2 | sqflite is the conservative choice (no codegen, raw SQL, easy to learn) and works on Android (native) + Windows (FFI). Use it if the team is allergic to build_runner. The trade-off: no reactive streams, hand-written SQL, no compile-time schema check. |
| `drift` 2.34 | `isar` / `hive` | Both are NoSQL key-value/document stores — wrong fit for the wrong-question ledger, which is fundamentally relational (questions × attempts × bookmarks × stats). Skip. |
| `go_router` 17.x | `auto_route` 11.1.0 | auto_route has stronger typing and nested-router ergonomics, but requires `build_runner` (we already need it for drift/freezed). Worth considering if the navigation graph grows to ~15+ screens. For RedClass's ~6 screens, go_router's lower ceremony wins. |
| `pdfx` 2.9.2 | `syncfusion_flutter_pdf` 33.2.13+1 | Syncfusion's pure-Dart text extraction is appealing, but: (a) requires a Syncfusion Community License (free for orgs under $1M, but it is a license obligation), (b) Windows desktop text extraction is not officially advertised. Pick pdfx for v1. Reconsider Syncfusion only if pdfx's PDFium rendering hits a real blocker on Windows. |
| `pdfx` 2.9.2 | `pdf_text` 0.5.0 | Older, mobile-only (Android/iOS), no Windows support — disqualified. |
| `archive` 4.0.9 + `xml` 6.x | None — there's no real alternative | This is the only realistic pure-Dart path for `.docx` text extraction in mid-2026. |
| llama.cpp via FFI | `flutter_llama` 1.1.2 | Officially supports Android/iOS/macOS — **no Windows**. Since Windows is a first-class target for RedClass, this rules out the wrapper. Roll our own thin FFI shim. |
| llama.cpp via FFI | Cloud-hosted LLM API | Violates the "本地离线" hard constraint in `PROJECT.md`. Hard no. |
| llama.cpp via FFI | Bundled Python + `transformers` / `llama-cpp-python` via subprocess | Process management across Windows + Android from Flutter is doable but fragile, breaks the "no backend, no extra installs" promise, and Android subprocess is restricted. Hard no. |
| llama.cpp via FFI | ONNX Runtime (`onnxruntime` 1.4.1) | Supported on Windows + Android; reasonable fallback if the FFI work on llama.cpp proves too time-consuming. Slightly easier API, but chat-tuned model availability in ONNX is narrower than GGUF. |
| llama.cpp via FFI | TFLite (`tflite_flutter` 0.12.1) | Cross-platform including Windows — but Windows setup requires **manually building `libtensorflowlite_c-win.dll` via Bazel or CMake** and copying it into `blobs/`. That's a real friction cost. Use only if ONNX/llama.cpp both fail. |
| Material 3 built-in | `flex_color_scheme` 8.4.0 | Stock M3 is fine; add flex_color_scheme only if the user wants seeded-color theming polish. |
| Stock `Intl` for dates | `timeago` | Skip — `intl` covers it; `timeago` adds a dep for marginal benefit. |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `docx` / `dart_docx` (404 on pub.dev) | These packages do not exist as of 2026-06; community history of abandonment. | `archive` 4.0.9 + `xml` 6.x for `.docx` parsing. |
| `docx_template` 0.4.0 | Only generates `.docx` from Microsoft Word content-control templates — does not read arbitrary `.docx`. | `archive` + `xml`. |
| `pdf_text` 0.5.0 (last updated 2021) | Mobile-only, no Windows support, stale. | `pdfx` 2.9.2. |
| `flutter_llama` 1.1.2 as the *only* LLM binding | No Windows support. | Build a thin llama.cpp FFI shim; or fall back to `onnxruntime`. |
| `isar` / `hive` | NoSQL; wrong fit for relational data (questions × attempts × bookmarks). | `drift` on SQLite. |
| `path_provider` `getApplicationSupportDirectory()` for user-visible files | On Windows lands in `%APPDATA%` (hidden), bad UX for a desktop app. | `getApplicationDocumentsDirectory()` on both platforms. |
| `SharedPreferences` legacy API | Will be deprecated; on Android multi-isolate edge cases cache stale values. | `SharedPreferencesAsync` / `SharedPreferencesWithCache`. |
| Hard-coded `libllama.so` / `llama.dll` paths | Each platform needs a different relative path inside the app bundle. | Use `path_provider` + a small per-platform resolver, and load with `DynamicLibrary.open(...)`. |
| Bundling the LLM model inside the APK | Bumps APK to 1+ GB; many users can't install. | Download the GGUF on first launch into `getApplicationDocumentsDirectory()/models/`, with a "Download model" UI and resume support. **Windows installer**: optionally bundle a smaller "starter" Q4_K_M GGUF alongside the `.exe`. |
| Running a 7B model on Android by default | Crashes on 4 GB phones; bad first impression. | Default-suggest Qwen2.5-1.5B Q4_K_M; expose "Advanced model" picker for 3.8B / Q5. |
| `MaterialApp.router` *without* `go_router` | Hand-rolled `Navigator 2.0` is a maintenance trap. | `go_router`. |
| Calling FFI calls on the UI isolate | Janks the UI thread during multi-second LLM token generation. | Run the FFI loop in a `compute()` isolate or in a long-lived `Isolate.spawn` and stream tokens back over a `SendPort`. |
| MSIX-signed installer as the only Windows distributable | Adds Partner Center overhead and blocks non-store distribution. | Default: plain `flutter build windows --release` producing `build/windows/x64/runner/Release/redclass.exe` (portable). Add `--store` only when publishing to Microsoft Store. |

---

## Stack Patterns by Variant

**If user is on a 4 GB Android phone:**
- Default-suggest **Qwen2.5-1.5B-Instruct Q4_K_M** (~1.1 GB RAM at load).
- Recommend "Fast mode" in the UI — reduce `n_ctx` to 1024 and `n_threads` to 2.
- Because: 7B Q4 needs ~5 GB resident; 3.8B Q4 needs ~2.5 GB and is borderline.

**If user is on a 6–8 GB Android phone:**
- Default-suggest **Qwen2.5-3B-Instruct Q4_K_M** or **Phi-3.5-mini Q4_K_M** (~2–2.3 GB).
- Because: still fits in physical RAM with headroom for the Flutter app and OS.

**If user is on Windows desktop:**
- Default-suggest **Qwen2.5-3B Q5_K_M** or **Qwen2.5-7B Q4_K_M** (~4.5 GB at Q4).
- Because: desktop has RAM to spare and parsing accuracy on gnarly Chinese formatting matters more than speed.

**If user wants zero model download:**
- Ship a **regex/heuristic parser** as the v0 fallback: numbered questions, "A./B./C./D." option lines, "答案: X" or "【答案】X" markers. Document its ~70% accuracy ceiling, and gate LLM behind an explicit opt-in download step.

**If the team pushes back on FFI / native libs:**
- Drop to **ONNX Runtime (`onnxruntime` 1.4.1)** with a Qwen2.5-1.5B ONNX export. Loses some model-zoo flexibility (GGUF is wider) but reduces custom FFI code by ~80%.

**If the .docx parsing accuracy is unacceptable with `archive + xml`:**
- Add a one-time "convert via OS" flow on Windows only: shell out to `soffice --headless --convert-to txt <file>` (LibreOffice). Skip on Android — no LibreOffice port and `Process` is heavily restricted. Fall back to "请把题库另存为 .pdf 或 .txt 后再导入" UI message.

---

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| Flutter 3.35.7 | Dart 3.9.2 (bundled) | Don't try to pin Dart separately — `flutter` ships it. |
| `drift` ^2.34.0 | `sqlite3` >=3.1.5 (transitive), `drift_dev` matching version | Pin drift and drift_dev to the same `^2.x`. |
| `drift` ^2.34.0 | `sqlite3_flutter_libs` latest | Provides prebuilt SQLite for Android/Windows so no manual `.dll` shipping. |
| `flutter_riverpod` ^3.3.2 | `riverpod_annotation` + `riverpod_generator` latest | The annotation/generator pair has its own versioning line; pin both together. |
| `freezed` ^3.x | `freezed_annotation` 3.x, `analyzer` ^8.x | freezed 3.x raised the analyzer floor — make sure `build_runner` matches. |
| `go_router` ^17.3.0 | Flutter >= 3.27 | Read the [v17 migration guide](https://flutter.dev/go/go-router-v17-breaking-changes) before upgrading from <17. |
| `pdfx` ^2.9.2 | Flutter >= 3.10 | After `pub get`, run `flutter pub run pdfx:install_windows` exactly once to patch the CMakeLists. |
| `file_picker` ^11.0.2 | All platforms | `clearTemporaryFiles()` is Android/iOS-only — don't call on Windows. |
| llama.cpp b9717 | N/A — vendored as `.dll` / `.so` from `ggml-org/llama.cpp` GitHub releases | Match ABI: rebuild the FFI shim if you bump llama.cpp. Prefer keeping llama.cpp pinned for the lifetime of v1. |
| `onnxruntime` 1.4.1 | Flutter >= 3.10 | Includes prebuilt `libonnxruntime.so` for Android; Windows requires manual `libonnxruntime.dll` placement. |

---

## Sources

- **Flutter 3.35.7 stable release** — `docs.flutter.dev/release/archive` (verified 2026-06-19): x64 Windows build 2025-12-04, Dart 3.9.2, ~quarterly cadence with 2026 schedule (3.36 Feb, 3.37 May, 3.38 Aug, 3.39 Nov).
- **Riverpod 3.3.2** — `pub.dev/packages/flutter_riverpod` (verified 2026-06-19, published by `dash-overflow.net`, Flutter Favorite, 2.88k likes, 2.31M monthly downloads).
- **drift 2.34.0** — `pub.dev/packages/drift` (verified 2026-06-19, Flutter Favorite, 882k monthly downloads, "Drift works on Android, iOS, macOS, Windows, Linux, and the web").
- **sqflite_common_ffi 2.4.2** — `pub.dev/packages/sqflite_common_ffi` (verified 2026-06-19, "Works on Linux, macOS and Windows on both Flutter and Dart VM", 125k weekly downloads).
- **sqlite3 3.3.3** — `pub.dev/packages/sqlite3` (verified 2026-06-19, Windows x64/x86/arm64 prebuilt via Dart hooks, 1.43M monthly downloads).
- **go_router 17.3.0** — `pub.dev/packages/go_router` (verified 2026-06-19, published by `flutter.dev`, Flutter Favorite, "feature-complete; primary focus on stability and bug fixes").
- **auto_route 11.1.0** — `pub.dev/packages/auto_route` (verified 2026-06-19, last published Dec 2025; LeanBuilder support added).
- **file_picker 11.0.2** — `pub.dev/packages/file_picker` (verified 2026-06-19, `pickFiles()` confirmed on both Windows + Android).
- **path_provider 2.1.6** — `pub.dev/packages/path_provider` (verified 2026-06-19, Windows 10+ support, `getApplicationDocumentsDirectory()` available).
- **shared_preferences 2.5.5** — `pub.dev/packages/shared_preferences` (verified 2026-06-19, `SharedPreferencesAsync` is the future-proof API).
- **pdfx 2.9.2** — `pub.dev/packages/pdfx` (verified 2026-06-19, Windows uses PDFium; `install_windows` script required).
- **pdf_text 0.5.0** — `pub.dev/packages/pdf_text` (verified 2026-06-19, last published 2021, **mobile only**).
- **syncfusion_flutter_pdf 33.2.13+1** — `pub.dev/packages/syncfusion_flutter_pdf` (verified 2026-06-19, Community License required, Windows text extraction caveat).
- **archive 4.0.9** — `pub.dev/packages/archive` (verified 2026-06-19, ZIP/Tar/ZLib/GZip/BZip2/XZ support).
- **flutter_llama 1.1.2** — `pub.dev/packages/flutter_llama` (verified 2026-06-19, **Android/iOS/macOS only**, no Windows — key reason for the custom FFI recommendation).
- **onnxruntime 1.4.1** — `pub.dev/packages/onnxruntime` (verified 2026-06-19, supports Android API 21+, iOS/Linux/macOS/Windows consistent with Flutter, Isolate-safe inference).
- **tflite_flutter 0.12.1** — `pub.dev/packages/tflite_flutter` (verified 2026-06-19, Windows supported but **requires manual `libtensorflowlite_c-win.dll` build**).
- **llama.cpp b9717 release** — `github.com/ggml-org/llama.cpp/releases` (verified 2026-06-19, prebuilt `llama-b9717-bin-android-arm64.tar.gz` 73.2 MB, `llama-b9717-bin-win-cpu-x64.zip`, Vulkan/CUDA/SYCL/HIP variants for Windows).
- **flex_color_scheme 8.4.0** — `pub.dev/packages/flex_color_scheme` (verified 2026-06-19, Flutter Favorite, BSD-3, M3 by default).
- **intl 0.20.2** — `pub.dev/packages/intl` (verified 2026-06-19, published by `dart.dev`, BSD-3).
- **flutter_bloc 9.1.1** — `pub.dev/packages/flutter_bloc` (verified 2026-06-19, Flutter Favorite, Bloc alternative context).
- **Flutter Windows deployment docs** — `docs.flutter.dev/deployment/windows` (verified 2026-06-19, MSIX is optional, plain `flutter build windows` is supported).

**Confidence notes:**
- HIGH confidence on Flutter SDK version, drift, sqflite_common_ffi, sqlite3, go_router, file_picker, path_provider, shared_preferences, pdfx, archive, Material 3, flutter_bloc.
- MEDIUM confidence on the on-device LLM story: the practical path (llama.cpp via custom FFI shim, Qwen2.5-1.5B Q4_K_M default) is realistic and well-trodden, but no pub.dev wrapper covers both Windows + Android, so we accept ~1–2 weeks of FFI shim work. Recommend prototyping the FFI shim in a spike before committing to the architecture.
- MEDIUM confidence on .docx parsing: the `archive + xml` path is feasible but requires walking WordprocessingML by hand. Recommend budgeting a parser utility layer with unit tests against a handful of real Chinese university `.docx` files.

---

*Stack research for: RedClass — local closed-source Flutter university exam review tool (Windows .exe + Android .apk, on-device LLM parsing).*
*Researched: 2026-06-19.*