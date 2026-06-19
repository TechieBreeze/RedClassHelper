# Requirements: RedClass (红课复习)

**Defined:** 2025-01-14
**Core Value:** 把"老师发的题库文件"零摩擦地变成"可立刻投入复习的结构化题库",让本地刷题体验比任何在线刷题网站都更顺手——**离线可用、零配置、解析即用、桌面解析、移动轻量**。

> **平台差异说明**：v1 五端共享一套代码。**LLM 解析能力仅在桌面端（Windows / macOS / Linux）启用**；移动端（Android / iOS）只通过"导入 JSON 文件"获得题库。导入页 UI 按平台分支渲染（桌面端三入口，移动端一入口）。这是显式的工程取舍，已记入 PROJECT.md 的 Key Decisions。

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Import (题库导入与解析)

- [ ] **IMP-01**: Desktop user can select a `.docx` file from local filesystem and import it as a question bank
- [ ] **IMP-02**: Desktop user can select a `.pdf` file from local filesystem and import it as a question bank
- [ ] **IMP-03**: Desktop app invokes a local on-device small LLM to parse raw text into structured questions (stem / options / answer)
- [ ] **IMP-04**: Parse process shows progress and failure reasons; user can retry on failure
- [ ] **IMP-05**: Imported questions are persisted to local database for long-term reuse
- [ ] **IMP-06**: Desktop user can export a parsed question bank as a standard JSON file (public format, see `doc/question-bank-json.md`)
- [ ] **IMP-07**: Mobile user can select a `.json` file from local filesystem and import it as a question bank (LLM not invoked)

### Storage (持久化)

- [ ] **STOR-01**: App uses a local SQLite database for all question/attempt/ledger/bookmark data (no backend)
- [ ] **STOR-02**: Wrong-question ledger, bookmarks, and statistics are all locally accessible from Windows / macOS / Linux / Android / iOS

### Question Types (题目类型)

- [ ] **QST-01**: App supports single-choice questions (one correct option)
- [ ] **QST-02**: App supports multiple-choice questions (all correct options must be selected to score)
- [ ] **QST-03**: Single-choice and multiple-choice questions are correctly labeled in the bank list and during display

### Review (复习模式)

- [ ] **REV-01**: User can use 乱序抽题 (random quiz) mode — questions are randomly drawn from the bank and graded immediately after submission
- [ ] **REV-02**: Questions answered incorrectly in 乱序抽题 mode are automatically added to the wrong-question ledger
- [ ] **REV-03**: User can use 错题复习 (wrong-question review) mode — only questions from the wrong-question ledger are presented
- [ ] **REV-04**: In 错题复习 mode, a correctly-answered question (with no partial/missing selection) is marked as 已掌握 (mastered) and removed from the wrong-question ledger
- [ ] **REV-05**: User can use 错题抽查 (wrong-question spot-check) mode — a small random sample is drawn from the current wrong-question ledger for quick self-test
- [ ] **REV-06**: 错题抽查 mode never draws questions that have been marked as 已掌握

### Bookmark (收藏)

- [ ] **BMK-01**: User can bookmark a single question while answering
- [ ] **BMK-02**: User can enter a unified bookmark view to review or inspect all bookmarked questions

### Statistics (统计)

- [ ] **STAT-01**: App records each answer attempt (question id, correct/incorrect, elapsed time, mode, timestamp)
- [ ] **STAT-02**: User can view answer statistics: correct rate, wrong-question distribution, per-mode aggregation

### Platform (跨平台)

- [ ] **PLT-01**: Windows build can be packaged as a `.exe` (single-file or portable)
- [ ] **PLT-02**: macOS build can be packaged as a `.app` / `.dmg`
- [ ] **PLT-03**: Linux build can be packaged as an executable + `.AppImage` / `.deb`
- [ ] **PLT-04**: Android build can be packaged as a `.apk` (arm64-v8a mandatory, x86_64 optional)
- [ ] **PLT-05**: iOS build can be packaged as a `.ipa` (requires Apple Developer account; source-level support at minimum)
- [ ] **PLT-06**: A single Flutter codebase serves all five platforms, with UI that adapts to window size and touch/mouse input
- [ ] **PLT-07**: Local SQLite database file is accessible and stable on all five platforms
- [ ] **PLT-08**: JSON question-bank file is portable across all five platforms (desktop exports → mobile imports)

### UI (用户界面)

- [ ] **UI-01**: UI is consistent, professional, and restrained — focused on distraction-free studying (per `ui-ux-pro-max` reference)
- [ ] **UI-02**: Home screen shows bank list + entries for the three review modes + statistics entry
- [ ] **UI-03**: Quiz screen presents clear stems, tappable options, immediate submission feedback, and explicit correct/incorrect display
- [ ] **UI-04**: Import page branches by platform: desktop shows `.docx` / `.pdf` / `.json` entries; mobile shows only `.json` entry. LLM parse UI is hidden on mobile.

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Import v2

- **IMP-08**: Scanned PDF OCR support (out of v1 — high complexity, low immediate value)
- **IMP-09**: Rich-text / image / formula extraction and rendering (out of v1)
- **IMP-10**: Cross-device wrong-question ledger / bookmark sync via JSON exchange (v1 is single-direction bank import only)

### Question Types v2

- **QST-04**: Fill-in-blank / true-false / short-answer question types (out of v1 — scoring complexity)
- **QST-05**: Chapter / knowledge-point filtering (out of v1 — banks may lack labels)

### Statistics v2

- **STAT-03**: Slow-answer list and per-bank trend visualization (out of v1)
- **STAT-04**: Question search across all banks (out of v1 — trigger at >1000 questions)

### Platform v2

- **PLT-09**: Web target (out of v1 — explicit desktop + mobile only)
- **PLT-10**: Multi-device sync (out of v1 — explicit local-only, no backend)

### UI v2

- **UI-05**: Dark/light theme switching (out of v1 — Material 3 default only)
- **UI-06**: Font-size adjustment (out of v1 — default + platform zoom only)

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Cloud sync / multi-device sync | Personal/small-group tool, no backend; JSON file is the user's transmission protocol |
| Multi-user login / registration | No account needed, out-of-box usage, lower complexity |
| Image / formula rendering in questions | Question banks are primarily text; image handling would require OCR + asset management, out of v1 |
| Chapter / knowledge-point filtering | Question bank structure may not have clean chapter labels, forcing user annotation creates friction |
| Image extraction from questions | Paired with the previous item |
| Fill-in-blank / true-false / short-answer | Parsing complexity and grading logic out of v1 scope |
| Online question-bank sharing community | Closed-source, no social/sharing module |
| Dark/light theme switching | Material 3 default is sufficient; theme switching is v2 |
| Font-size adjustment | Default font size + platform-native zoom support is sufficient |
| Cloud-based LLM / online inference | Violates "本地离线" hard constraint in PROJECT.md |
| AI-generated questions | Quality unstable, hard to evaluate, not core value |
| Quiz marketplace / community | Conflicts with "BYO question bank" positioning |
| Streak / gamification | Anti-feature; study tool not a retention game |
| Anki-style spaced repetition (SRS) | Out of scope; wrong-question ledger already covers ~80% of benefit |
| Timed exam mode | Different product; this is review, not test-taking |
| Social features / leaderboards | Closed-source single-user tool |
| Mobile LLM parsing | 1-3B models unreliable on Android/iOS in v1; JSON file transfer is the cross-device path |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| IMP-01 | Phase 2 | Pending |
| IMP-02 | Phase 2 | Pending |
| IMP-03 | Phase 3 | Pending |
| IMP-04 | Phase 2 | Pending |
| IMP-05 | Phase 1 | Pending |
| IMP-06 | Phase 5 | Pending |
| IMP-07 | Phase 5 | Pending |
| STOR-01 | Phase 1 | Pending |
| STOR-02 | Phase 1 | Pending |
| QST-01 | Phase 4 | Pending |
| QST-02 | Phase 5 | Pending |
| QST-03 | Phase 2 | Pending |
| REV-01 | Phase 4 | Pending |
| REV-02 | Phase 4 | Pending |
| REV-03 | Phase 4 | Pending |
| REV-04 | Phase 4 | Pending |
| REV-05 | Phase 4 | Pending |
| REV-06 | Phase 4 | Pending |
| BMK-01 | Phase 5 | Pending |
| BMK-02 | Phase 5 | Pending |
| STAT-01 | Phase 4 | Pending |
| STAT-02 | Phase 5 | Pending |
| PLT-01 | Phase 7 | Pending |
| PLT-02 | Phase 7 | Pending |
| PLT-03 | Phase 7 | Pending |
| PLT-04 | Phase 7 | Pending |
| PLT-05 | Phase 7 | Pending |
| PLT-06 | Phase 1 | Pending |
| PLT-07 | Phase 1 | Pending |
| PLT-08 | Phase 5 | Pending |
| UI-01 | Phase 6 | Pending |
| UI-02 | Phase 1 | Pending |
| UI-03 | Phase 4 | Pending |
| UI-04 | Phase 2 | Pending |

**Coverage:**
- v1 requirements: 33 total
- Mapped to phases: 33
- Unmapped: 0 ✓

---

*Requirements defined: 2025-01-14*
*Last updated: 2025-01-14 after platform-scope expansion (5 platforms, mobile-LLM disabled, JSON export)*
