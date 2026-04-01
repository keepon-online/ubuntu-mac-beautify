# reapply.sh GDM Integration Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `reapply.sh` automatically reapply the project custom GDM theme on GNOME, with an opt-out flag matching `install.sh` semantics.

**Architecture:** Reuse the existing `run_project_gdm_beautify` helper from `lib/common.sh`, add a `--skip-gdm` flag to `reapply.sh`, invoke the helper only for GNOME when GDM reapply is enabled, and refresh docs/tests so the behavior is discoverable and verified.

**Tech Stack:** Bash, shell tests, sudo, GDM3

---

## Chunk 1: Test First

### Task 1: Extend the GDM test to cover reapply.sh integration

**Files:**
- Modify: `tests/gdm_theme_scripts_test.sh`
- Modify: `reapply.sh`

- [ ] **Step 1: Write the failing test**

Add assertions that `reapply.sh` supports `--skip-gdm` in help text and calls `run_project_gdm_beautify` in the GNOME branch.

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/gdm_theme_scripts_test.sh`
Expected: FAIL because `reapply.sh` does not yet expose the new flag or helper call.

## Chunk 2: Reapply Flow

### Task 2: Wire GDM into reapply.sh

**Files:**
- Modify: `reapply.sh`

- [ ] **Step 1: Add `--skip-gdm` parsing and help text**
- [ ] **Step 2: Add GNOME-only call to `run_project_gdm_beautify`**
- [ ] **Step 3: Keep the GDM step non-fatal and report summary status**

## Chunk 3: Docs And Verification

### Task 3: Sync docs and verify

**Files:**
- Modify: `README.md`
- Modify: `docs/gdm-login-beautify.md`

- [ ] **Step 1: Update README examples and notes**
- [ ] **Step 2: Update GDM doc so it mentions `reapply.sh` behavior**
- [ ] **Step 3: Run verification**

Run: `bash tests/gdm_theme_scripts_test.sh && bash ./check.sh && git status --short`
Expected: PASS for tests and checks, with only expected docs/script changes in the diff.
