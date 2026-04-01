# install.sh GDM Integration Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate the project-maintained custom GDM beautify script into the GNOME branch of `install.sh` without breaking KDE or forcing GDM failures to abort the full install.

**Architecture:** Add a reusable helper in `lib/common.sh` that invokes the project GDM script and can be exercised in tests without root-side effects. Update `install.sh` to call that helper only when `DESKTOP=gnome` and `WITH_GDM=true`, then refresh README and uninstall guidance to match the new behavior.

**Tech Stack:** Bash, shell tests, sudo, GDM3

---

## Chunk 1: Test And Helper

### Task 1: Add a failing test for the project GDM integration helper

**Files:**
- Modify: `tests/gdm_theme_scripts_test.sh`
- Modify: `lib/common.sh`

- [ ] **Step 1: Write the failing test**

Extend `tests/gdm_theme_scripts_test.sh` with assertions for a new helper that, in test mode, reports the project script path and target desktop behavior without touching the system.

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/gdm_theme_scripts_test.sh`
Expected: FAIL because the helper does not exist yet.

- [ ] **Step 3: Implement the minimal helper**

Add a helper to `lib/common.sh` that invokes `scripts/install-custom-gdm-prussiangreen.sh` through `sudo bash`, warns on failure, and supports a test mode path that emits deterministic output.

- [ ] **Step 4: Re-run the test to verify it passes**

Run: `bash tests/gdm_theme_scripts_test.sh`
Expected: PASS

## Chunk 2: Main Flow Integration

### Task 2: Wire the helper into install.sh

**Files:**
- Modify: `install.sh`

- [ ] **Step 1: Add the GNOME-only call site**

After the existing WhiteSur GDM tweak block, call the new helper when `WITH_GDM=true`.

- [ ] **Step 2: Keep failure non-fatal**

Ensure the main install flow continues even if the custom GDM helper fails, with a clear warning.

- [ ] **Step 3: Update final summary output**

Clarify that the GNOME install path now attempts both WhiteSur GDM styling and the project custom GDM theme, and mention the rollback script.

## Chunk 3: Docs And Verification

### Task 3: Sync user-facing docs

**Files:**
- Modify: `README.md`
- Modify: `uninstall.sh`

- [ ] **Step 1: Update README**

Change the README so it states that `install.sh` automatically applies the project GDM beautify step on GNOME unless `--skip-gdm` is used, while the standalone scripts remain available for manual repair and rollback.

- [ ] **Step 2: Update uninstall guidance**

Point the uninstall warning at `scripts/rollback-custom-gdm-prussiangreen.sh`.

- [ ] **Step 3: Run verification**

Run: `bash tests/gdm_theme_scripts_test.sh && bash ./check.sh && git status --short`
Expected: test and check pass; diff limited to `install.sh`, `lib/common.sh`, `README.md`, `uninstall.sh`, and test/doc updates.
