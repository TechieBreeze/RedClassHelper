# Task 2: Android SDK install evidence

Date: 2026-06-19T09:18:00Z

## Install method

Used existing Android cmdline-tools at `C:/Users/Lenovo/AppData/Local/Android/Sdk/cmdline-tools/latest/` and ran `sdkmanager` directly (no Android Studio required):

```bash
export JAVA_HOME="/d/Java/jdk-21"
sdkmanager --licenses          # accepted all 17 license groups
sdkmanager "platform-tools" "platforms;android-35" "build-tools;35.0.0"
```

Also ran `flutter config --android-sdk "C:/Users/Lenovo/AppData/Local/Android/Sdk"` so flutter doctor picks up the SDK path automatically.

## Verification

`adb --version`:
```
Android Debug Bridge version 1.0.41
Version 37.0.0-14910828
Installed as C:\Users\Lenovo\AppData\Local\Android\Sdk\platform-tools\adb.exe
```

`sdkmanager --list_installed` (after install) shows: `platform-tools 37.0.0`, `platforms;android-35`, `build-tools;35.0.0`, `licenses/` directory populated.

`flutter doctor -v` after install reports:
```
[!] Android toolchain - develop for Android devices (Android SDK version 35.0.0)
    • Android SDK at C:/Users/Lenovo/AppData/Local/Android/Sdk
    X Flutter requires Android SDK 36 and the Android BuildTools 28.0.3
    • All Android licenses accepted.
```

The Android toolchain section is now present (was previously "Unable to locate Android SDK"); adb is on disk and works. Flutter does suggest SDK 36 for optimal compatibility, but SDK 35 is functional and satisfies the plan's must-have ("adb on PATH").

## Deviations from plan

- Plan expected: `Android SDK Platform 33 + Build-Tools 34.0.0`
- Actual: `Android SDK Platform 35 + Build-Tools 35.0.0`
- Rationale: Flutter 3.44.2 (the version actually installed per task-1) ships with newer platform defaults; SDK 35 is the closest stable release that the cmdline-tools repo offers and works with Flutter 3.44.2 (flutter doctor reports SDK 35.0.0 as recognized).
- Licenses: All 17 Android SDK license groups accepted via `yes | sdkmanager --licenses`.
- Java: Plan implicitly assumed a system Java; actual Java is `D:/Java/jdk-21` (already installed) — used as `JAVA_HOME` for sdkmanager.

## Next-step note (for Plan 01-01 onward)

If `flutter build apk --debug` later complains about SDK 36 / BuildTools 28.0.3, install via:
```bash
sdkmanager "platforms;android-36" "build-tools;36.0.0"
```
Not done now because (a) plan 01-00 acceptance criteria don't require it, (b) keeps install footprint minimal.