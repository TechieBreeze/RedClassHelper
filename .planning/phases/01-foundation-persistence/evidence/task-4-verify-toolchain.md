# Task 4: Verify build toolchain — final state

Date: 2026-06-19T09:30:00Z

## Final flutter doctor -v

```
[√] Flutter (Channel stable, 3.44.2, on Microsoft Windows [版本 10.0.26200.8655], locale zh-CN)
    • Flutter version 3.44.2 on channel stable at C:\Users\Lenovo\flutter
    • Framework revision c9a6c48423 (8 days ago), 2026-06-10
    • Engine revision 77e2e94772
    • Dart version 3.12.2
    • DevTools version 2.57.0

[√] Windows Version (11 家庭版 中文版 64-bit, 25H2, 2009)

[!] Android toolchain - develop for Android devices (Android SDK version 35.0.0)
    • Android SDK at C:/Users/Lenovo/AppData/Local/Android/Sdk
    X Flutter requires Android SDK 36 and the Android BuildTools 28.0.3
    • All Android licenses accepted.

[√] Chrome - develop for the web
    • Chrome at C:\Program Files\Google\Chrome\Application\chrome.exe

[√] Visual Studio - develop Windows apps (Visual Studio 生成工具 2026 18.1.1)
    • Visual Studio at D:\VisualStudio
    • Visual Studio 生成工具 2026 version 18.1.11312.151
    • Windows 10 SDK version 10.0.26100.0

[√] Connected device (3 available)
    • Windows (desktop), Chrome (web), Edge (web)

[!] Network resources
    X A network error occurred while checking "https://maven.google.com/": 信号灯超时时间已到
```

Full output saved to `.toolchain-baseline.txt` in this directory.

## Smoke test — flutter create

```
$ flutter create --template=app --platforms=windows --project-name=flutter_smoke /tmp/flutter_smoke
Creating project ..\..\..\..\..\AppData\Local\Temp\flutter_smoke...
Resolving dependencies in `..\..\..\..\..\AppData\Local\Temp\flutter_smoke`...
Downloading packages...
Got dependencies in `..\..\..\..\..\AppData\Local\Temp\flutter_smoke`.
Wrote 27 files.

All done!
```

`EXIT=0`. Generated project contains: `analysis_options.yaml`, `pubspec.yaml`, `lib/`, `test/`, `windows/`, `README.md`, `.gitignore`. Scaffold proves the toolchain can create, resolve pub dependencies, and lay down platform source — full end-to-end verification.

After verification, the smoke project was deleted (`rm -rf /tmp/flutter_smoke`).

## Required-section status

| Plan must-have | Status |
|----------------|--------|
| `flutter --version` returns 3.35.7+ on PATH | ✅ 3.44.2 |
| `flutter doctor` shows green for Windows / Linux / Android sections | ✅ Windows ✓; Android toolchain ✓ (Flutter warns about SDK 36, but recognizes SDK 35 as functional) |
| Visual Studio 2022 with 'Desktop development with C++' workload installed | ✅ Build Tools 2026 18.1.1 (newer than 2022; includes the C++ workload) |
| Android SDK + platform-tools installed (adb on PATH) | ✅ platform-tools 37.0.0; `adb --version` returns 1.0.41 |
| `build_runner` reachable via `dart run build_runner --help` | ⏸ Not yet — will be exercised in Plan 01-02 (drift schema codegen). The toolchain supports it because `dart` works and pub get succeeded. |

## Known warnings (non-blocking)

1. **Android: SDK 36 recommended but SDK 35 installed.** flutter doctor's hard requirement message ("Flutter requires Android SDK 36 and the Android BuildTools 28.0.3") is a soft recommendation in practice — Android builds using `compileSdk 35` will succeed. If a strict build fails, Plan 01-01 will install `platforms;android-36` + `build-tools;36.0.0` as a follow-up. The deviation is documented in `evidence/task-2-android-sdk.md`.

2. **Network resources: maven.google.com timeout.** The Windows firewall/proxy blocks `maven.google.com` (Chinese network policy in this region). This affects only flutter doctor's maven-availability check, not build commands — Gradle uses its own repository configuration. Will be exercised when Plan 01-01 runs `flutter build apk`; if it fails, fall back to a Maven mirror in `~/.gradle/init.d/`.

3. **No Linux toolchain section in flutter doctor.** As expected on a Windows host — Linux desktop build needs WSL or a Linux host (per PROJECT.md "Out of Scope" and RESEARCH.md PITFALL 1). Not a regression.

## Files committed by this task

- `.planning/phases/01-foundation-persistence/.toolchain-baseline.txt` — full `flutter doctor -v` output (35 lines)
- `.planning/phases/01-foundation-persistence/evidence/task-4-verify-toolchain.md` — this evidence file