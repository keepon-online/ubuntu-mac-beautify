# reset.sh And uninstall.sh GDM Rollback Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `reset.sh` and `uninstall.sh` automatically roll back the project custom GDM theme on GNOME, while allowing users to opt out with `--keep-gdm`.

**Architecture:** Add a shared `run_project_gdm_rollback` helper in `lib/common.sh`, test it through the existing shell test harness, and wire it into `reset.sh` and `uninstall.sh` only for GNOME. Keep rollback failures non-fatal and expose the result in script summaries.

**Tech Stack:** Bash, shell tests, sudo, GDM3

---

## Chunk 1: Test First

### Task 1: Extend shell tests for GDM rollback integration

**Files:**
- Modify: `tests/gdm_theme_scripts_test.sh`

- [ ] **Step 1: Write the failing test**

Add assertions that `lib/common.sh` exposes a rollback helper, and that both `reset.sh` and `uninstall.sh` expose `--keep-gdm` and call the rollback helper.

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/gdm_theme_scripts_test.sh`
Expected: FAIL because the rollback helper and CLI flags do not yet exist.

## Chunk 2: Helper And Script Integration

### Task 2: Implement GDM rollback helper and wire it in

**Files:**
- Modify: `lib/common.sh`
- Modify: `reset.sh`
- Modify: `uninstall.sh`

- [ ] **Step 1: Implement `run_project_gdm_rollback`**
- [ ] **Step 2: Add `--keep-gdm` to `reset.sh` and call rollback on GNOME by default**
- [ ] **Step 3: Add `--keep-gdm` to `uninstall.sh` and call rollback on GNOME by default**
- [ ] **Step 4: Keep rollback failures non-fatal and report status in summaries**

## Chunk 3: Docs And Verification

### Task 3: Update docs and verify

**Files:**
- Modify: `README.md`
- Modify: `docs/gdm-login-beautify.md`

- [ ] **Step 1: Document the new reset/uninstall default rollback behavior**
- [ ] **Step 2: Document the `--keep-gdm` opt-out flag**
- [ ] **Step 3: Run verification**

Run: `bash tests/gdm_theme_scripts_test.sh && bash ./check.sh && git status --short`
Expected: PASS for tests and checks, with only the expected script/doc changes in the diff.
