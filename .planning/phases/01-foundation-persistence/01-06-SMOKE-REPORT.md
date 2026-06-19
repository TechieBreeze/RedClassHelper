# Phase 1 Smoke Report

Date: 2026-06-19
Phase: 01-foundation-persistence
Plan: 06 (cross-platform smoke)

## Summary

| Platform | Build Command | Status | Evidence |
|----------|-------------|--------|----------|
| Windows | `flutter build windows --debug` | ✅ PASS | `build/windows/x64/runner/Debug/redclass.exe` |
| Android | `flutter build apk --debug` | ⏸️ DEFERRED | NDK 28.2 blocked by disk space (C: 1.1GB free, NDK needs ~2GB) |
| Linux | `flutter build linux --debug` | ⏸️ DEFERRED | No WSL/Linux host |
| iOS | `flutter build ios --debug --no-codesign` | ⏸️ DEFERRED | No macOS host |
| macOS | `flutter build macos --debug` | ⏸️ DEFERRED | No macOS host |

## Static Analysis

- `flutter analyze`: **0 issues** ✅

## Unit & Widget Tests

- `flutter test`: **39/39 passed** ✅
- Test suites: migration (5), path_resolver (6), router (8), theme (4), home_screen (16)

## Acceptance Gates

| Gate | Threshold | Actual | Pass? |
|------|-----------|--------|-------|
| flutter analyze | 0 issues | 0 | ✅ |
| flutter test | 100% pass | 39/39 | ✅ |
| ≥1 native build | 1+ | 1 (Windows) | ✅ |
| Deferred documented | all | 3 documented | ✅ |

## Android Build Detail

**Blocked by:** NDK 28.2.13676358 installation requires ~2 GB free disk space.
C: drive has 1.1 GB free; D: drive has 76 GB free.

**Resolution path:** Migrate `ANDROID_SDK_ROOT` to D: drive, then re-run `sdkmanager --install "ndk;28.2.13676358"`, then `flutter build apk --debug`.

**Commands for migration:**
```bash
# Move SDK to D:
mv /c/Users/Lenovo/AppData/Local/Android/Sdk /d/Android/Sdk
# Update env var (PowerShell admin):
[Environment]::SetEnvironmentVariable('ANDROID_HOME', 'D:\Android\Sdk', 'User')
# Update Flutter config:
flutter config --android-sdk D:/Android/Sdk
# Install NDK:
sdkmanager --install "ndk;28.2.13676358"
# Build:
flutter build apk --debug
```

## Deferred Platform Build Commands

```bash
# Linux (requires WSL or native Linux host)
flutter build linux --debug

# iOS (requires macOS host + Xcode)
flutter build ios --debug --no-codesign

# macOS (requires macOS host)
flutter build macos --debug
```
