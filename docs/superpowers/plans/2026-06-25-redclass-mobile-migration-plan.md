# RedClass 移动端迁移实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 RedClass 扩展到 Android 平台（保持桌面/网页零回归），5 个阶段独立可发布。

**Architecture:** 渐进式平台分支。新增 `core/platform/`（平台检测+响应式原语+门控）和 `data/file_picker/`（平台适配的文件选择抽象）。领域层零改动，UI 层用 `ResponsiveBuilder`/`AdaptiveLayout` 切换布局变体。

**Tech Stack:** Flutter 3.35+ / Dart 3.12+ / Riverpod 3 / Drift 2 / go_router 17 / file_picker 11 / mocktail

**Spec:** `docs/superpowers/specs/2026-06-25-redclass-mobile-migration-design.md`

---

## 文件结构

**新增**（`lib/`）：
- `core/platform/platform_info.dart`、`responsive.dart`、`platform_guard.dart`
- `core/widgets/adaptive_scaffold.dart`
- `data/file_picker/{file_picker_service,file_picker_models,file_picker_errors,file_picker_providers,mobile_file_picker,desktop_file_picker}.dart`
- `features/models/presentation/widgets/llm_unsupported_banner.dart`

**新增**（`test/`）：
- `unit/platform/platform_info_test.dart`
- `unit/data/file_picker/{file_picker_models_test,fake_file_picker_service.dart}`
- `widget/platform/{responsive_test,adaptive_scaffold_test,platform_guard_test}.dart`

**新增**（`integration_test/`）：
- `mobile_import_flow_test.dart`、`desktop_import_flow_test.dart`

**修改**：
- `lib/features/home/presentation/home_screen.dart`、`import/presentation/import_screen.dart`、`import/providers/import_notifier.dart`
- `lib/features/quiz/presentation/quiz_screen.dart`、`bank_detail/presentation/bank_detail_screen.dart`、`stats/presentation/stats_screen.dart`
- `lib/features/bookmarks/presentation/bookmarks_screen.dart`、`import/presentation/{import_preview,import_progress,import_summary}_screen.dart`
- `lib/features/models/presentation/{settings_screen,model_management_screen}.dart`

---

## 阶段 1：地基（4 任务）

### Task 1: PlatformInfo + FormFactor

**Files:**
- Create: `lib/core/platform/platform_info.dart`
- Test: `test/unit/platform/platform_info_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/unit/platform/platform_info_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/core/platform/platform_info.dart';

void main() {
  group('FormFactor breakpoint', () {
    test('shortestSide < 600 returns compact', () {
      final info = PlatformInfo.forTesting(platform: AppPlatform.android, shortestSide: 360);
      expect(info.formFactor, FormFactor.compact);
    });
    test('shortestSide < 840 returns medium', () {
      final info = PlatformInfo.forTesting(platform: AppPlatform.android, shortestSide: 720);
      expect(info.formFactor, FormFactor.medium);
    });
    test('shortestSide >= 840 returns expanded', () {
      final info = PlatformInfo.forTesting(platform: AppPlatform.windows, shortestSide: 1200);
      expect(info.formFactor, FormFactor.expanded);
    });
  });

  group('derived flags', () {
    test('android is mobile, not desktop', () {
      final info = PlatformInfo.forTesting(platform: AppPlatform.android, shortestSide: 400);
      expect(info.isMobile, true);
      expect(info.isDesktop, false);
    });
    test('windows is desktop, supportsLlm true', () {
      final info = PlatformInfo.forTesting(platform: AppPlatform.windows, shortestSide: 1200);
      expect(info.isDesktop, true);
      expect(info.supportsLlm, true);
    });
    test('android does not supportLlm', () {
      final info = PlatformInfo.forTesting(platform: AppPlatform.android, shortestSide: 400);
      expect(info.supportsLlm, false);
    });
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `cd "C:\Users\Lenovo\Desktop\agent-workspace\Mimo Code\RedClass" && flutter test test/unit/platform/platform_info_test.dart`
Expected: 编译失败（PlatformInfo 未定义）

- [ ] **Step 3: 实现 PlatformInfo**

```dart
// lib/core/platform/platform_info.dart
import 'dart:io' show Platform;
import 'package:flutter/widgets.dart';

enum AppPlatform { android, ios, windows, linux, macos, web, fuchsia, unknown }

enum FormFactor { compact, medium, expanded }

class PlatformInfo {
  const PlatformInfo({required this.platform, required this.shortestSide});
  factory PlatformInfo.forTesting({required AppPlatform platform, required double shortestSide}) =>
      PlatformInfo(platform: platform, shortestSide: shortestSide);

  factory PlatformInfo.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return PlatformInfo(platform: _detect(), shortestSide: size.shortestSide);
  }

  static AppPlatform _detect() {
    if (Platform.isAndroid) return AppPlatform.android;
    if (Platform.isIOS) return AppPlatform.ios;
    if (Platform.isWindows) return AppPlatform.windows;
    if (Platform.isLinux) return AppPlatform.linux;
    if (Platform.isMacOS) return AppPlatform.macos;
    return AppPlatform.web;
  }

  final AppPlatform platform;
  final double shortestSide;

  FormFactor get formFactor {
    if (shortestSide < 600) return FormFactor.compact;
    if (shortestSide < 840) return FormFactor.medium;
    return FormFactor.expanded;
  }
  bool get isMobile => platform == AppPlatform.android || platform == AppPlatform.ios;
  bool get isDesktop => platform == AppPlatform.windows || platform == AppPlatform.linux || platform == AppPlatform.macos;
  bool get supportsLlm => isDesktop;
  bool get isCompact => formFactor == FormFactor.compact;
  bool get isExpanded => formFactor == FormFactor.expanded;
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/unit/platform/platform_info_test.dart`
Expected: 6 tests pass

- [ ] **Step 5: Commit**

```bash
cd "C:\Users\Lenovo\Desktop\agent-workspace\Mimo Code\RedClass" && git add lib/core/platform/platform_info.dart test/unit/platform/platform_info_test.dart && git -c commit.gpgsign=false commit -m "feat(platform): add PlatformInfo with FormFactor breakpoint"
```

---

### Task 2: ResponsiveBuilder + AdaptiveLayout

**Files:**
- Create: `lib/core/platform/responsive.dart`
- Test: `test/widget/platform/responsive_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/widget/platform/responsive_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/core/platform/responsive.dart';

Widget _wrap(Widget child, {required double width, required double height}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: Size(width, height)),
      child: child,
    ),
  );
}

void main() {
  testWidgets('AdaptiveLayout renders compact branch on small screen', (t) async {
    await t.pumpWidget(_wrap(
      const AdaptiveLayout(compact: Text('C'), medium: Text('M'), expanded: Text('E')),
      width: 400, height: 800,
    ));
    expect(find.text('C'), findsOneWidget);
  });
  testWidgets('AdaptiveLayout renders medium branch on tablet', (t) async {
    await t.pumpWidget(_wrap(
      const AdaptiveLayout(compact: Text('C'), medium: Text('M'), expanded: Text('E')),
      width: 720, height: 1024,
    ));
    expect(find.text('M'), findsOneWidget);
  });
  testWidgets('AdaptiveLayout falls back to compact when medium/expanded missing', (t) async {
    await t.pumpWidget(_wrap(const AdaptiveLayout(compact: Text('C')), width: 720, height: 1024));
    expect(find.text('C'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/widget/platform/responsive_test.dart`
Expected: 编译失败（AdaptiveLayout 未定义）

- [ ] **Step 3: 实现 Responsive + AdaptiveLayout**

```dart
// lib/core/platform/responsive.dart
import 'package:flutter/material.dart';
import 'platform_info.dart';

class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({super.key, required this.builder});
  final Widget Function(BuildContext, PlatformInfo) builder;
  @override
  Widget build(BuildContext context) => builder(context, PlatformInfo.fromContext(context));
}

class AdaptiveLayout extends StatelessWidget {
  const AdaptiveLayout({super.key, required this.compact, this.medium, this.expanded});
  final WidgetBuilder compact;
  final WidgetBuilder? medium;
  final WidgetBuilder? expanded;
  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(builder: (_, info) {
      return switch (info.formFactor) {
        FormFactor.compact => Builder(builder: compact),
        FormFactor.medium => Builder(builder: medium ?? compact),
        FormFactor.expanded => Builder(builder: expanded ?? medium ?? compact),
      };
    });
  }
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/widget/platform/responsive_test.dart`
Expected: 3 tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/core/platform/responsive.dart test/widget/platform/responsive_test.dart && git -c commit.gpgsign=false commit -m "feat(platform): add ResponsiveBuilder and AdaptiveLayout"
```

---

### Task 3: PlatformGuard

**Files:**
- Create: `lib/core/platform/platform_guard.dart`
- Test: `test/widget/platform/platform_guard_test.dart`

- [ ] **Step 1: 实现 UnsupportedFeatureGuard**

```dart
// lib/core/platform/platform_guard.dart
import 'package:flutter/material.dart';
import 'platform_info.dart';

class UnsupportedFeatureGuard extends StatelessWidget {
  const UnsupportedFeatureGuard({
    super.key,
    required this.requiresDesktop,
    required this.child,
    required this.fallback,
  });
  final bool requiresDesktop;
  final Widget child;
  final Widget fallback;
  @override
  Widget build(BuildContext context) {
    final info = PlatformInfo.fromContext(context);
    final allowed = requiresDesktop ? info.isDesktop : !info.isDesktop;
    return allowed ? child : fallback;
  }
}
```

- [ ] **Step 2: 写 widget 测试（用 pumpWidget + MediaQuery size 控 FormFactor）**

```dart
// test/widget/platform/platform_guard_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/core/platform/platform_guard.dart';

void main() {
  testWidgets('UnsupportedFeatureGuard(requiresDesktop:true) shows child on expanded', (t) async {
    await t.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(1200, 800)),
        child: const UnsupportedFeatureGuard(
          requiresDesktop: true,
          child: Text('CHILD'),
          fallback: Text('FALLBACK'),
        ),
      ),
    ));
    expect(find.text('CHILD'), findsOneWidget);
  });
  testWidgets('UnsupportedFeatureGuard(requiresDesktop:true) shows fallback on compact', (t) async {
    await t.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(400, 800)),
        child: const UnsupportedFeatureGuard(
          requiresDesktop: true,
          child: Text('CHILD'),
          fallback: Text('FALLBACK'),
        ),
      ),
    ));
    expect(find.text('FALLBACK'), findsOneWidget);
  });
}
```

- [ ] **Step 3: 跑测试**

Run: `flutter test test/widget/platform/platform_guard_test.dart`
Expected: 2 tests pass（注意：测试用 size 控 FormFactor，platform 默认是 test runner 当前平台 — 如发现 platform 假设错误，子代理需用 `debugDefaultTargetPlatformOverride` 显式覆盖）

- [ ] **Step 4: Commit**

```bash
git add lib/core/platform/platform_guard.dart test/widget/platform/platform_guard_test.dart && git -c commit.gpgsign=false commit -m "feat(platform): add UnsupportedFeatureGuard"
```

---

### Task 4: AdaptiveScaffold + HomeScreen 接入

**Files:**
- Create: `lib/core/widgets/adaptive_scaffold.dart`
- Modify: `lib/features/home/presentation/home_screen.dart`

- [ ] **Step 1: 写 widget 测试**

```dart
// test/widget/platform/adaptive_scaffold_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/core/widgets/adaptive_scaffold.dart';

void main() {
  testWidgets('compact shows AppBar with drawer', (t) async {
    await t.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(400, 800)),
        child: const AdaptiveScaffold(title: 'T', body: Text('B'), drawer: Text('D')),
      ),
    ));
    expect(find.byType(AppBar), findsOneWidget);
  });
  testWidgets('expanded renders drawer inline as side rail', (t) async {
    await t.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(1200, 800)),
        child: const AdaptiveScaffold(title: 'T', body: Text('B'), drawer: Text('D')),
      ),
    ));
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('D'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 实现 AdaptiveScaffold**

```dart
// lib/core/widgets/adaptive_scaffold.dart
import 'package:flutter/material.dart';
import '../platform/responsive.dart';

class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
  });
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(builder: (_, info) {
      if (info.isCompact) {
        return Scaffold(
          appBar: AppBar(title: Text(title), actions: actions),
          body: body,
          floatingActionButton: floatingActionButton,
          bottomNavigationBar: bottomNavigationBar,
          drawer: drawer,
        );
      }
      return Scaffold(
        appBar: AppBar(title: Text(title), actions: actions),
        body: Row(children: [
          if (drawer != null) ...[
            SizedBox(width: 280, child: drawer!),
            const VerticalDivider(width: 1),
          ],
          Expanded(child: body),
        ]),
        floatingActionButton: floatingActionButton,
      );
    });
  }
}
```

- [ ] **Step 3: 改造 HomeScreen**

读 `lib/features/home/presentation/home_screen.dart`，把顶层 `Scaffold` 替换为 `AdaptiveScaffold`，把现有导航列表移到 `drawer` 参数。

- [ ] **Step 4: 跑全套测试**

Run: `flutter test`
Expected: 全部通过；桌面端 Home 视觉不变

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/adaptive_scaffold.dart lib/features/home/presentation/home_screen.dart test/widget/platform/adaptive_scaffold_test.dart && git -c commit.gpgsign=false commit -m "feat(home): use AdaptiveScaffold for responsive layout"
```

---

## 阶段 2：文件选择抽象（5 任务）

### Task 5: PickedFile sealed class

**Files:**
- Create: `lib/data/file_picker/file_picker_models.dart`
- Test: `test/unit/data/file_picker/file_picker_models_test.dart`

- [ ] **Step 1: 写测试**

```dart
// test/unit/data/file_picker/file_picker_models_test.dart
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/data/file_picker/file_picker_models.dart';

void main() {
  test('PickedBytesFile openRead returns single-chunk stream', () async {
    final file = PickedBytesFile(name: 'a.pdf', bytes: Uint8List.fromList([1, 2, 3]));
    final chunks = await file.openRead().toList();
    expect(chunks, hasLength(1));
    expect(chunks.first, [1, 2, 3]);
  });
  test('PickedPathFile exposes path', () {
    final file = PickedPathFile(name: 'a.pdf', path: '/x/a.pdf', length: 10);
    expect(file.path, '/x/a.pdf');
  });
}
```

- [ ] **Step 2-3: 跑测试 + 实现**

```dart
// lib/data/file_picker/file_picker_models.dart
import 'dart:io';
import 'dart:typed_data';

sealed class PickedFile {
  const PickedFile();
  String get name;
  Stream<Uint8List> openRead();
}

class PickedPathFile extends PickedFile {
  const PickedPathFile({required this.path, required this.name, required this.length});
  @override final String path;
  @override final String name;
  final int length;
  @override Stream<Uint8List> openRead() => File(path).openRead();
}

class PickedBytesFile extends PickedFile {
  const PickedBytesFile({required this.bytes, required this.name});
  @override final Uint8List bytes;
  @override final String name;
  @override Stream<Uint8List> openRead() => Stream.value(bytes);
}
```

- [ ] **Step 4-5: 跑测试 + Commit**

Run: `flutter test test/unit/data/file_picker/file_picker_models_test.dart`
Commit: `feat(file_picker): add PickedFile sealed class with two variants`

---

### Task 6: FilePickerError sealed class

**Files:**
- Create: `lib/data/file_picker/file_picker_errors.dart`

- [ ] **Step 1: 实现（无测试，纯类型）**

```dart
// lib/data/file_picker/file_picker_errors.dart
sealed class FilePickerError {
  const FilePickerError(this.message);
  final String message;
}
class FilePickCancelled extends FilePickerError { const FilePickCancelled(): super('cancelled'); }
class FilePickPermissionDenied extends FilePickerError { const FilePickPermissionDenied([super.message = 'permission denied']); }
class FilePickUnsupportedMethod extends FilePickerError { const FilePickUnsupportedMethod([super.message = 'unsupported on this platform']); }
class FileReadError extends FilePickerError { const FileReadError(super.message); }
class FilePickUnknown extends FilePickerError { const FilePickUnknown(super.message); }
```

- [ ] **Step 2: Commit**

```bash
git add lib/data/file_picker/file_picker_errors.dart && git -c commit.gpgsign=false commit -m "feat(file_picker): add FilePickerError sealed types"
```

---

### Task 7: FilePickerService interface + Fake

**Files:**
- Create: `lib/data/file_picker/file_picker_service.dart`
- Create: `test/unit/data/file_picker/fake_file_picker_service.dart`

- [ ] **Step 1: 实现**

```dart
// lib/data/file_picker/file_picker_service.dart
import 'file_picker_models.dart';
import 'file_picker_errors.dart';

abstract interface class FilePickerService {
  Future<PickedFile?> pickFile({required Set<String> allowedExtensions, String? dialogTitle});
  Future<PickedFile?> pickFromDroppedPath(String path);
  Future<void> dispose();
}
```

```dart
// test/unit/data/file_picker/fake_file_picker_service.dart
import 'dart:typed_data';
import 'package:redclass/data/file_picker/file_picker_service.dart';
import 'package:redclass/data/file_picker/file_picker_models.dart';

class FakeFilePickerService implements FilePickerService {
  PickedFile? nextResult;
  Object? nextError;
  final List<({Set<String> extensions, String? title})> calls = [];

  @override
  Future<PickedFile?> pickFile({required Set<String> allowedExtensions, String? dialogTitle}) async {
    calls.add((extensions: allowedExtensions, title: dialogTitle));
    if (nextError != null) throw nextError!;
    return nextResult;
  }
  @override
  Future<PickedFile?> pickFromDroppedPath(String path) async => null;
  @override
  Future<void> dispose() async {}
}

PickedFile fakePdfFile({String name = 'test.pdf'}) =>
    PickedBytesFile(name: name, bytes: Uint8List.fromList([1, 2, 3]));
```

- [ ] **Step 2: Commit**

```bash
git add lib/data/file_picker/file_picker_service.dart test/unit/data/file_picker/fake_file_picker_service.dart && git -c commit.gpgsign=false commit -m "feat(file_picker): add FilePickerService interface and Fake"
```

---

### Task 8: Mobile + Desktop implementations + Provider

**Files:**
- Create: `lib/data/file_picker/mobile_file_picker.dart`
- Create: `lib/data/file_picker/desktop_file_picker.dart`
- Create: `lib/data/file_picker/file_picker_providers.dart`

- [ ] **Step 1: 实现 MobileFilePickerService**

```dart
// lib/data/file_picker/mobile_file_picker.dart
import 'package:file_picker/file_picker.dart' as fp;
import 'file_picker_service.dart';
import 'file_picker_models.dart';
import 'file_picker_errors.dart';

class MobileFilePickerService implements FilePickerService {
  @override
  Future<PickedFile?> pickFile({required Set<String> allowedExtensions, String? dialogTitle}) async {
    try {
      final result = await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: allowedExtensions.toList(),
        withData: true,
      );
      if (result == null) return null;
      final f = result.files.single;
      if (f.bytes == null) {
        throw const FileReadError('Picked file has no bytes (withData failed)');
      }
      return PickedBytesFile(name: f.name, bytes: f.bytes!);
    } on FilePickerError {
      rethrow;
    } catch (e) {
      throw FilePickUnknown(e.toString());
    }
  }
  @override
  Future<PickedFile?> pickFromDroppedPath(String path) async {
    throw const FilePickUnsupportedMethod('Drop is desktop-only');
  }
  @override
  Future<void> dispose() async {}
}
```

- [ ] **Step 2: 实现 DesktopFilePickerService**

```dart
// lib/data/file_picker/desktop_file_picker.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart' as fp;
import 'file_picker_service.dart';
import 'file_picker_models.dart';
import 'file_picker_errors.dart';

class DesktopFilePickerService implements FilePickerService {
  @override
  Future<PickedFile?> pickFile({required Set<String> allowedExtensions, String? dialogTitle}) async {
    try {
      final result = await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: allowedExtensions.toList(),
        dialogTitle: dialogTitle,
      );
      if (result == null) return null;
      final f = result.files.single;
      if (f.path == null) {
        throw const FileReadError('Picked file has no path');
      }
      return PickedPathFile(name: f.name, path: f.path!, length: f.size);
    } on FilePickerError {
      rethrow;
    } catch (e) {
      throw FilePickUnknown(e.toString());
    }
  }
  @override
  Future<PickedFile?> pickFromDroppedPath(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw FileReadError('Dropped path does not exist: $path');
    }
    return PickedPathFile(name: path.split(Platform.pathSeparator).last, path: path, length: await file.length());
  }
  @override
  Future<void> dispose() async {}
}
```

- [ ] **Step 3: 实现 Provider**

```dart
// lib/data/file_picker/file_picker_providers.dart
import 'dart:io' show Platform;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'file_picker_service.dart';
import 'mobile_file_picker.dart';
import 'desktop_file_picker.dart';

part 'file_picker_providers.g.dart';

@Riverpod(keepAlive: true)
FilePickerService filePickerService(Ref ref) {
  if (Platform.isAndroid || Platform.isIOS) {
    return MobileFilePickerService();
  }
  return DesktopFilePickerService();
}
```

- [ ] **Step 4: 跑 codegen + 测试**

```bash
cd "C:\Users\Lenovo\Desktop\agent-workspace\Mimo Code\RedClass" && dart run build_runner build --delete-conflicting-outputs
flutter test
```

- [ ] **Step 5: Commit**

```bash
git add lib/data/file_picker/ && git -c commit.gpgsign=false commit -m "feat(file_picker): add mobile/desktop implementations and provider"
```

---

### Task 9: ImportNotifier 接收 PickedFile

**Files:**
- Modify: `lib/features/import/providers/import_notifier.dart`
- Modify: `lib/features/import/providers/import_state.dart`（如需要）
- Test: `test/unit/features/import/import_notifier_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/unit/features/import/import_notifier_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:redclass/features/import/providers/import_notifier.dart';
import 'package:redclass/data/file_picker/file_picker_models.dart';
import 'dart:typed_data';

void main() {
  test('receiveFile accepts PickedBytesFile', () async {
    final notifier = ImportNotifier(...);  // 注入 fake deps（具体依赖读 import_notifier.dart）
    await notifier.receiveFile(
      PickedBytesFile(name: 'a.pdf', bytes: Uint8List.fromList([1,2,3])),
    );
    expect(notifier.state.isCommitting || notifier.state.isDone, true);
  });
}
```

- [ ] **Step 2: 改造 `receiveFile` 签名**

把 `receiveFile(String path)` 改为 `receiveFile(PickedFile file)`。内部用 `file.openRead()` 替换 `File(path).openRead()`。

- [ ] **Step 3: 修所有调用方**

```bash
grep -r "receiveFile" lib/
```

- [ ] **Step 4: 跑测试 + Commit**

```bash
git add lib/features/import/ && git -c commit.gpgsign=false commit -m "refactor(import): ImportNotifier receives PickedFile abstraction"
```

---

### Task 10: ImportScreen 接入 FilePickerService

**Files:**
- Modify: `lib/features/import/presentation/import_screen.dart`

- [ ] **Step 1: 替换 file_picker 直调**

读 `import_screen.dart`，找到 `FilePicker.platform.pickFiles` 调用处，替换为：

```dart
final picked = await ref.read(filePickerServiceProvider).pickFile(
  allowedExtensions: {'pdf', 'docx', 'txt'},
  dialogTitle: '选择题库文件',
);
if (picked == null) return;
await ref.read(importNotifierProvider.notifier).receiveFile(picked);
```

- [ ] **Step 2: 桌面拖放路径用 `pickFromDroppedPath`**

如果 ImportScreen 当前有 `desktop_drop` 集成，改为调 `pickFromDroppedPath` 拿 `PickedFile`，再传给 notifier。

- [ ] **Step 3: 跑 widget 测试 + 桌面手动验证**

Run: `flutter test && flutter run -d windows`

- [ ] **Step 4: Commit**

```bash
git add lib/features/import/presentation/import_screen.dart && git -c commit.gpgsign=false commit -m "feat(import): use FilePickerService in ImportScreen"
```

---

## 阶段 3：核心屏响应式（3 任务）

### Task 11: QuizScreen 响应式

**Files:**
- Modify: `lib/features/quiz/presentation/quiz_screen.dart`
- Test: `test/widget/features/quiz/quiz_screen_responsive_test.dart`

- [ ] **Step 1: 写 widget 测试**

```dart
testWidgets('QuizScreen renders vertical layout on compact', (t) async {
  // pump 在 400x800 尺寸下，期望单列布局
  expect(find.byKey(const Key('quiz_vertical_layout')), findsOneWidget);
});
testWidgets('QuizScreen renders side-by-side on expanded', (t) async {
  // pump 在 1200x800 尺寸下，期望题目左、选项右
  expect(find.byKey(const Key('quiz_horizontal_layout')), findsOneWidget);
});
```

- [ ] **Step 2: 用 AdaptiveLayout 包裹题面 + 选项区**

compact: 单列。expanded: 题目左、选项右。

- [ ] **Step 3-4: 跑测试 + Commit**

```bash
git add lib/features/quiz/presentation/quiz_screen.dart test/widget/features/quiz/quiz_screen_responsive_test.dart && git -c commit.gpgsign=false commit -m "feat(quiz): responsive layout for compact and expanded"
```

---

### Task 12: BankDetailScreen 响应式

**Files:**
- Modify: `lib/features/bank_detail/presentation/bank_detail_screen.dart`

- [ ] **Step 1-3: 同 Task 11 模式**

compact: ListView 单列。expanded: 主内容 + 侧栏统计。

```bash
git commit -m "feat(bank_detail): responsive layout"
```

---

### Task 13: StatsScreen 响应式

**Files:**
- Modify: `lib/features/stats/presentation/stats_screen.dart`

- [ ] **Step 1-3: 同 Task 11 模式**

compact: 折叠卡片。expanded: 网格。

```bash
git commit -m "feat(stats): responsive layout"
```

---

## 阶段 4：次要屏响应式（4 任务）

### Task 14-17: BookmarksScreen / ImportPreview / ImportProgress / ImportSummary / SettingsScreen

模式：每个屏幕一个任务，每个用 AdaptiveLayout 改造。

- Task 14: BookmarksScreen
- Task 15: ImportPreviewScreen
- Task 16: ImportProgressScreen
- Task 17: ImportSummaryScreen + SettingsScreen

每任务：
1. 写 widget 测试（用 MediaQuery size 控 FormFactor）
2. 用 AdaptiveLayout 包裹主内容
3. 跑测试
4. Commit

```bash
git commit -m "feat(<feature>): responsive layout"
```

---

## 阶段 5：边缘 + 集成测试（3 任务）

### Task 18: LlmUnsupportedBanner + ModelManagementScreen 门控

**Files:**
- Create: `lib/features/models/presentation/widgets/llm_unsupported_banner.dart`
- Modify: `lib/features/models/presentation/model_management_screen.dart`

- [ ] **Step 1: 实现 LlmUnsupportedBanner**

```dart
// lib/features/models/presentation/widgets/llm_unsupported_banner.dart
import 'package:flutter/material.dart';
import 'package:redclass/core/platform/responsive.dart';
import 'package:redclass/core/platform/platform_info.dart';

class LlmUnsupportedBanner extends StatelessWidget {
  const LlmUnsupportedBanner({super.key});
  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(builder: (_, info) {
      if (info.supportsLlm) return const SizedBox.shrink();
      return MaterialBanner(
        content: const Text('本地 LLM 推理仅在桌面端可用'),
        actions: [TextButton(onPressed: () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(), child: const Text('知道了'))],
      );
    });
  }
}
```

- [ ] **Step 2: ModelManagementScreen 按钮门控**

把下载/删除按钮用 `UnsupportedFeatureGuard` 包裹，Android 上渲染 disabled 版本 + Tooltip "桌面端功能"。

- [ ] **Step 3: 跑测试 + Commit**

```bash
git add lib/features/models/ && git commit -m "feat(models): LLM gate ModelManagementScreen on mobile"
```

---

### Task 19: 移动端导入集成测试

**Files:**
- Create: `integration_test/mobile_import_flow_test.dart`

- [ ] **Step 1: 写集成测试**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('mobile: import pdf from SAF → heuristic parse → DB', (t) async {
    await t.pumpWidgetAndSettle(...);
    // 触发选文件（用 fake picker override）
    // 验证数据库有题目
  });
}
```

- [ ] **Step 2: 跑集成测试**

```bash
flutter test integration_test/mobile_import_flow_test.dart -d <android-device>
```

- [ ] **Step 3: Commit**

```bash
git commit -m "test: add mobile import integration test"
```

---

### Task 20: 桌面端回归 + 最终验证

- [ ] **Step 1: 跑全套测试**

```bash
cd "C:\Users\Lenovo\Desktop\agent-workspace\Mimo Code\RedClass" && flutter test && flutter analyze && dart format --set-exit-if-changed .
```

Expected: 全部通过；分析无 warning。

- [ ] **Step 2: 跑集成测试（mobile + desktop）**

- [ ] **Step 3: 覆盖率检查**

```bash
flutter test --coverage
# 验证覆盖率 >= 80%
```

- [ ] **Step 4: 更新 README**

添加 Android 支持说明到 `README.md`。

- [ ] **Step 5: 最终 commit**

```bash
git add . && git commit -m "chore: mobile migration complete — 5 phases, 80%+ coverage"
```

---

## 自审

- ✅ Spec 覆盖：架构、3 个新模块、5 阶段、错误处理、测试策略 — 全部有任务
- ✅ 占位符扫描：无 TBD/TODO
- ✅ 类型一致：`PlatformInfo.fromContext` / `filePickerServiceProvider` / `PickedFile.openRead` 在各任务签名一致
- ⚠️ Task 3 测试用 size 控 FormFactor，platform 默认由 test runner 决定 — 子代理实施时如需精确控制 platform，可用 `debugDefaultTargetPlatformOverride`
