# Requirements: RedClass (红课复习)

**Defined:** 2025-01-14
**Core Value:** 把"老师发的题库文件"零摩擦地变成"可立刻投入复习的结构化题库",让本地刷题体验比任何在线刷题网站都更顺手——**离线可用、零配置、解析即用**。

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Import (题库导入与解析)

- [ ] **IMP-01**: User can select a `.docx` file from local filesystem and import it as a question bank
- [ ] **IMP-02**: User can select a `.pdf` file from local filesystem and import it as a question bank
- [ ] **IMP-03**: App invokes a local on-device small LLM to parse raw text into structured questions (stem / options / answer)
- [ ] **IMP-04**: Parse process shows progress and failure reasons; user can retry on failure
- [ ] **IMP-05**: Imported questions are persisted to local database for long-term reuse

### Storage (持久化)

- [ ] **STOR-01**: App uses a local SQLite database for all question/attempt/ledger/bookmark data (no backend)
- [ ] **STOR-02**: Wrong-question ledger, bookmarks, and statistics are all locally accessible from both Windows and Android

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

### Platform (桌面与移动端)

- [ ] **PLT-01**: Windows build can be packaged as a `.exe` (single-file or portable)
- [ ] **PLT-02**: Android build can be packaged as a `.apk` (debug or release)
- [ ] **PLT-03**: A single Flutter codebase serves both platforms, with UI that adapts to window size and touch/mouse input
- [ ] **PLT-04**: Local SQLite database file is accessible and stable on both Windows and Android

### UI (用户界面)

- [ ] **UI-01**: UI is consistent, professional, and restrained — focused on distraction-free studying (per `ui-ux-pro-max` reference)
- [ ] **UI-02**: Home screen shows bank list + entries for the three review modes + statistics entry
- [ ] **UI-03**: Quiz screen presents clear stems, tappable options, immediate submission feedback, and explicit correct/incorrect display

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Import v2

- **IMP-06**: Scanned PDF OCR support (out of v1 — high complexity, low immediate value)
- **IMP-07**: Rich-text / image / formula extraction and rendering (out of v1)

### Question Types v2

- **QST-04**: Fill-in-blank / true-false / short-answer question types (out of v1 — scoring complexity)
- **QST-05**: Chapter / knowledge-point filtering (out of v1 — banks may lack labels)

### Statistics v2

- **STAT-03**: Slow-answer list and per-bank trend visualization (out of v1)
- **STAT-04**: Question search across all banks (out of v1 — trigger at >1000 questions)

### Platform v2

- **PLT-05**: iOS / macOS / Linux targets (out of v1 — explicit Windows+Android only)
- **PLT-06**: Cloud sync / multi-device (out of v1 — explicit local-only, no backend)

### UI v2

- **UI-04**: Dark/light theme switching (out of v1 — Material 3 default only)
- **UI-05**: Font-size adjustment (out of v1 — default + platform zoom only)

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Cloud sync / multi-device sync | Personal/small-group tool, no backend, single-device simplest |
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

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| IMP-01 | Phase 2 | Pending |
| IMP-02 | Phase 2 | Pending |
| IMP-03 | Phase 3 | Pending |
| IMP-04 | Phase 2 | Pending |
| IMP-05 | Phase 1 | Pending |
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
| PLT-03 | Phase 1 | Pending |
| PLT-04 | Phase 1 | Pending |
| UI-01 | Phase 6 | Pending |
| UI-02 | Phase 1 | Pending |
| UI-03 | Phase 4 | Pending |

**Coverage:**
- v1 requirements: 27 total
- Mapped to phases: 27
- Unmapped: 0 ✓

---
*Requirements defined: 2025-01-14*
*Last updated: 2025-01-14 after initial definition*
