# Directory Structure

## Root Layout

```
RedClass/
├── lib/                          # All Dart application code
│   ├── main.dart                 # Entry point: main() → ProviderScope → RedClassApp
│   ├── core/                     # Shared infrastructure
│   │   ├── .gitkeep
│   │   ├── paths.dart            # PathResolver + pathResolverProvider
│   │   ├── paths.g.dart          # Generated provider (riverpod_generator)
│   │   ├── theme.dart            # buildAppTheme() — ThemeData factory
│   │   └── theme.g.dart          # Generated provider
│   ├── data/                     # Data layer
│   │   ├── .gitkeep
│   │   └── db/
│   │       ├── database.dart     # @DriftDatabase — AppDatabase + appDatabaseProvider
│   │       ├── database.g.dart   # Generated (drift_dev)
│   │       └── tables/
│   │           ├── answer_attempts.dart
│   │           ├── bookmarks.dart
│   │           ├── parse_jobs.dart
│   │           ├── parse_logs.dart
│   │           ├── question_banks.dart
│   │           ├── questions.dart
│   │           └── wrong_ledger_entries.dart
│   ├── domain/                   # Domain models (empty — Phase 2+)
│   │   └── .gitkeep
│   ├── features/                 # Feature modules
│   │   ├── .gitkeep
│   │   ├── home/presentation/home_screen.dart       # Full M3 layout (Phase 1)
│   │   ├── bank_detail/presentation/bank_detail_screen.dart  # Placeholder
│   │   ├── bookmarks/presentation/bookmarks_screen.dart      # Placeholder
│   │   ├── import/presentation/import_screen.dart            # Placeholder
│   │   ├── quiz/presentation/quiz_screen.dart                # Placeholder
│   │   └── stats/presentation/stats_screen.dart              # Placeholder
│   └── routing/
│       └── router.dart           # GoRouter configuration (6 routes)
├── test/                         # Unit + widget tests
│   ├── core/
│   │   ├── paths/path_resolver_test.dart
│   │   └── theme/
│   │       ├── dynamic_color_fallback_test.dart
│   │       └── theme_test.dart
│   ├── data/db/migration_test.dart
│   ├── features/home/home_screen_test.dart
│   └── routing/router_test.dart
├── windows/                      # Windows platform (CMake)
│   ├── CMakeLists.txt
│   ├── flutter/                  # Flutter-managed build rules
│   └── runner/                   # Windows entry point + resource files
├── linux/                        # Linux platform (CMake + GTK 3.0)
│   ├── CMakeLists.txt
│   ├── flutter/
│   └── runner/
├── android/                      # Android platform (Gradle + AGP)
│   ├── build.gradle.kts
│   ├── app/
│   └── gradle/
├── ios/                          # iOS (source-level only)
├── macos/                        # macOS (source-level only)
├── .planning/                    # GSD project management
│   ├── PROJECT.md, REQUIREMENTS.md, ROADMAP.md, STATE.md
│   ├── config.json
│   ├── phases/
│   │   ├── 01-foundation-persistence/   (7 plans, 7 summaries)
│   │   └── 02-desktop-file-import-pipeline/ (CONTEXT.md)
│   ├── research/
│   │   ├── ARCHITECTURE.md, FEATURES.md, PITFALLS.md, STACK.md, SUMMARY.md
│   └── codebase/                 # This mapping
├── doc/                          # Reference material
│   └── example/                  # Real Chinese university question files
│       ├── 《纲要》选择题（2026年5月最新修订版）.pdf
│       ├── 《毛概》题库-2025-2026（二）(1).doc
│       ├── 思想道德与法治题库2026年1月版.doc
│       └── 习近平新时代中国特色社会主义思想概论题库.docx
├── pubspec.yaml                  # Dart/Flutter package configuration
├── pubspec.lock                  # Locked dependency versions
├── analysis_options.yaml         # Dart analyzer + linter configuration
└── build/                        # Build output (gitignored)
```

## Key Locations

| What | Where |
|------|-------|
| App entry point | `lib/main.dart` |
| Route definitions | `lib/routing/router.dart` |
| Database entry | `lib/data/db/database.dart` |
| Table schemas | `lib/data/db/tables/*.dart` |
| Path resolution | `lib/core/paths.dart` |
| Theme factory | `lib/core/theme.dart` |
| Full UI screen | `lib/features/home/presentation/home_screen.dart` |
| Placeholder screens | `lib/features/{bank_detail,bookmarks,import,quiz,stats}/presentation/*.dart` |

## File Count

| Category | Files |
|----------|-------|
| Dart source (lib/) | 18 |
| Dart tests (test/) | 6 |
| Platform (windows/ + linux/ + android/) | ~30+ (auto-generated) |
| .planning/ documents | 40+ |
| Total tracked files | ~60 |

## Naming Conventions

- **Files:** `snake_case.dart` (Dart convention)
- **Classes:** `PascalCase` (`HomeScreen`, `PathResolver`, `AppDatabase`)
- **Private widgets:** `_PrefixName` (`_SectionHeader`, `_ModeTile`, `_BankEmptyStateCard`)
- **Providers:** `camelCaseProvider` (`appDatabaseProvider`, `pathResolverProvider`)
- **Directories:** `snake_case` (`bank_detail/`, `question_banks/`)
