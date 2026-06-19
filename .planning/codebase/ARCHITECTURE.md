# Architecture

## Architectural Pattern: Feature-first Clean Architecture (lightweight)

```
lib/
├── core/          # Shared infrastructure (paths, theme) — depends on nothing
├── data/          # Data layer (drift DB + tables + DAOs) — depends on core/
├── domain/        # Domain models (Phase 2+ freezed sealed classes) — depends on nothing
├── features/      # UI features (each feature is self-contained under presentation/)
│   ├── home/
│   ├── bank_detail/
│   ├── bookmarks/
│   ├── import/
│   ├── quiz/
│   └── stats/
├── routing/       # GoRouter config — depends on features/
└── main.dart      # App entry point + Riverpod ProviderScope
```

**Dependency flow:** `features/` → `data/` → `core/`  (features never import each other directly; navigation via GoRouter)

## Key Architectural Decisions

### D-03: Riverpod 3.x State Management

All application state is managed through Riverpod providers with `@riverpod` codegen. No `StatefulWidget` — all screens are `StatelessWidget` + `ConsumerWidget`.

- Normal providers: `@riverpod` annotation → `riverpod_generator` codegen
- Keep-alive providers: `PathResolver`, `AppDatabase` (singletons, never disposed)
- `main()` uses `ProviderScope(overrides: [...])` to inject pre-resolved `PathResolver`

### D-15: Singleton PathResolver

All file paths flow through `PathResolver` — no other class imports `path_provider`. This ensures:
1. Single point of truth for directory layout
2. Testability: mock `PathResolver` in tests instead of mocking platform channels
3. Late-init avoidance: resolved in `main()` before `runApp()`, eliminating async race conditions

### D-14: drift ORM with WAL + FK Enforcement

- `schemaVersion = 1` — migration strategy defined for `onCreate`, `onUpgrade`, `beforeOpen`
- WAL mode: concurrent reads + single-threaded writes
- Foreign keys: explicitly enabled via `PRAGMA foreign_keys = ON` in `beforeOpen`
- Two factory methods: `openAppDatabase(path)` for production, `openInMemoryDatabase()` for tests

### GoRouter declarative routing

Six routes defined in `lib/routing/router.dart`:
- `/` → `HomeScreen`
- `/bank/:id` → `BankDetailScreen`
- `/quiz/:bankId/:mode` → `QuizScreen`
- `/stats` → `StatsScreen`
- `/bookmarks` → `BookmarksScreen`
- `/import` → `ImportScreen`

No nested navigation — flat route table with path parameters. Error builder catches unknown routes.

### DynamicColorBuilder → ThemeData

`lib/core/theme.dart` provides `buildAppTheme(Brightness, ColorScheme?)`:
- Platform dynamic color when available (Android)
- Falls back to `ColorScheme.fromSeed(Colors.red)` — "红" (red) as brand seed
- Auto dark mode via `ThemeMode.system`

### Platform-Conditional UI

UI branching uses `Platform.isWindows || Platform.isLinux` for desktop-specific code paths (e.g., file drag-drop, FAB behavior). This is an explicit architectural choice — two branches (desktop/mobile), not per-platform.

## Data Flow

```
User Action → GoRouter navigation → Feature Screen (StatelessWidget)
  → Riverpod provider (watch/read) → drift DAO → SQLite (WAL)
  → Stream<List<T>> (reactive) → Widget rebuild
```

## Current State

- **Phase 1 complete:** All screens are placeholder `Scaffold` + `Center` + `Text` except `HomeScreen` (full M3 layout)
- **7 drift tables** defined but no DAO queries beyond auto-generated CRUD
- **No domain layer yet** — `lib/domain/.gitkeep` is empty, waiting for Phase 2+ freezed models
- **No business logic** — Phase 2 (file parsing) will be the first logic-heavy phase
