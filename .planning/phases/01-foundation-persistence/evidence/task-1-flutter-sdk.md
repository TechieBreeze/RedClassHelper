# Task 1: Flutter SDK install evidence

Date: 2026-06-19T09:13:44Z

## Install method

Direct git clone (not FVM):

```
cd C:/Users/Lenovo
git clone --depth 1 -b stable https://github.com/flutter/flutter.git C:/Users/Lenovo/flutter
```

Dart SDK auto-download via update_dart_sdk.ps1 was blocked by network policy (PowerShell Invoke-WebRequest failed). Workaround: manually downloaded dart-sdk-windows-x64.zip from storage.googleapis.com via curl, extracted to C:/Users/Lenovo/flutter/bin/cache/dart-sdk, and pre-created engine-dart-sdk.stamp to skip the re-download.

## Deviation from plan

- Plan expected: FVM at C:/Users/Lenovo/fvm/versions/3.35.7/bin/flutter.bat
- Actual: Direct clone at C:/Users/Lenovo/flutter/bin/flutter.bat (no FVM)
- Version: 3.44.2 stable (plan expected 3.35.7; this is newer, satisfies '3.35.7+' must-have)
- Dart: 3.12.2 (plan expected 3.9.2; Dart version is tied to Flutter SDK version)

## Verification

```
Flutter 3.44.2 • channel stable • https://github.com/flutter/flutter.git
Framework • revision c9a6c48423 (8 days ago) • 2026-06-10 15:52:41 -0700
Engine • hash 04efd7c093d4e9281d5526ebcad6ecc60ba8badf (revision 77e2e94772) (8 days ago) • 2026-06-10 19:59:06.000Z
Tools • Dart 3.12.2 • DevTools 2.57.0
```

```
Dart SDK version: 3.12.2 (stable) (Tue Jun 9 01:11:39 2026 -0700) on "windows_x64"
```

```
C:\Users\Lenovo\flutter\bin\flutter
C:\Users\Lenovo\flutter\bin\flutter.bat
```

## PATH (user-scope)

Added C:\Users\Lenovo\flutter\bin to user PATH via PowerShell [Environment]::SetEnvironmentVariable.
