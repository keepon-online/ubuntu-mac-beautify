# GNOME Desktop Icon Repair Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a standalone GNOME repair command that patches missing `Icon=` and `StartupWMClass=` fields in high-confidence hidden handler desktop entries under the user's local applications directory.

**Architecture:** Keep the user-facing command as a thin shell wrapper and place reusable parsing and repair helpers in `lib/common.sh`. Drive the implementation with shell-level regression tests that operate on temporary desktop entry fixtures, then wire the command into checks and documentation.

**Tech Stack:** Bash, shellcheck, desktop entry utilities (`update-desktop-database` when available)

---

## Chunk 1: Test Harness

### Task 1: Add regression test entrypoint

**Files:**
- Create: `tests/fix_desktop_icons_test.sh`
- Modify: `Makefile`

- [ ] **Step 1: Write the failing test**

Create `tests/fix_desktop_icons_test.sh` with fixture helpers and a first case where a hidden handler desktop file missing `Icon=` and `StartupWMClass=` should inherit them from a matching visible desktop file.

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/fix_desktop_icons_test.sh`
Expected: FAIL because `fix-desktop-icons.sh` and helper functions do not exist yet.

- [ ] **Step 3: Add a convenience target**

Add a `make test-fix-desktop-icons` target that runs `bash tests/fix_desktop_icons_test.sh`.

- [ ] **Step 4: Re-run the test to verify it still fails for the intended reason**

Run: `make test-fix-desktop-icons`
Expected: FAIL because the repair command is still missing.

## Chunk 2: Repair Helpers and Command

### Task 2: Implement minimal desktop entry parsing and repair

**Files:**
- Modify: `lib/common.sh`
- Create: `fix-desktop-icons.sh`

- [ ] **Step 1: Write the next failing tests**

Extend `tests/fix_desktop_icons_test.sh` with:
- a match-by-`Exec` case,
- an ambiguous-match case that must be skipped,
- an already-complete case that must remain unchanged.

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/fix_desktop_icons_test.sh`
Expected: FAIL on missing repair command or missing helper behavior.

- [ ] **Step 3: Write minimal implementation**

In `lib/common.sh`, add helpers to:
- read first-value desktop keys,
- normalize `Exec`, `Name`, and `MimeType`,
- enumerate visible and hidden desktop entries,
- select a unique source entry conservatively,
- back up and patch missing keys.

Create `fix-desktop-icons.sh` to:
- source `lib/common.sh`,
- scan `~/.local/share/applications` or an override directory for tests,
- apply repairs,
- refresh desktop database if possible,
- print a concise summary.

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/fix_desktop_icons_test.sh`
Expected: PASS for all fixture cases.

## Chunk 3: Project Integration

### Task 3: Wire the command into project tooling and docs

**Files:**
- Modify: `check.sh`
- Modify: `README.md`
- Modify: `Makefile`

- [ ] **Step 1: Write a failing integration expectation**

Add assertions to `tests/fix_desktop_icons_test.sh` that the command output includes `fixed`, `skipped`, and `unchanged` summary lines needed by the documentation.

- [ ] **Step 2: Run tests to verify the expectation fails if needed**

Run: `bash tests/fix_desktop_icons_test.sh`
Expected: FAIL until output is aligned.

- [ ] **Step 3: Implement integration changes**

Update:
- `check.sh` to lint the new script,
- `Makefile` to expose a `fix-desktop-icons` target,
- `README.md` with a manual repair section and command examples.

- [ ] **Step 4: Run focused verification**

Run: `bash tests/fix_desktop_icons_test.sh`
Expected: PASS

## Chunk 4: Final Verification

### Task 4: Verify full project status

**Files:**
- Modify: plan checkbox state only if desired during execution

- [ ] **Step 1: Run syntax checks**

Run: `bash ./check.sh`
Expected: existing `SC1091` baseline may remain, but no new syntax or shellcheck issues from the added files.

- [ ] **Step 2: Run regression tests**

Run: `bash tests/fix_desktop_icons_test.sh`
Expected: PASS

- [ ] **Step 3: Review diff**

Run: `git status --short`
Expected: only files related to the repair command, tests, docs, and plan/spec additions are modified or added.

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/specs/2026-03-12-gnome-desktop-icon-repair-design.md \
  docs/superpowers/plans/2026-03-12-gnome-desktop-icon-repair.md \
  tests/fix_desktop_icons_test.sh \
  fix-desktop-icons.sh \
  lib/common.sh \
  check.sh \
  README.md \
  Makefile
git commit -m "feat: add desktop icon repair command"
```

Plan complete and saved to `docs/superpowers/plans/2026-03-12-gnome-desktop-icon-repair.md`. Ready to execute.
