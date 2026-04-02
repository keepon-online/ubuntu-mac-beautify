# GDM Login Minimal Redesign Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rework the bundled GDM login resource so the login screen reads as a clearly visible macOS-like minimal dark design while preserving the existing install and rollback flow.

**Architecture:** Extract the current GDM resource contents, write a failing content-level regression test for the desired style markers, update only the login-related CSS to a darker and more neutral visual language, then rebuild the bundled `gnome-shell-theme.gresource`. Keep all system integration logic unchanged and verify via both resource assertions and existing GDM workflow tests.

**Tech Stack:** Bash, GNOME Shell gresource, glib-compile-resources, CSS, Markdown

---

## Chunk 1: Resource Inspection And Regression Tests

### Task 1: Add a failing resource-style regression test

**Files:**
- Create: `tests/gdm_theme_resource_style_test.sh`
- Test: `tests/gdm_theme_resource_style_test.sh`

- [ ] **Step 1: Write the failing test**

Create a test that extracts the relevant CSS from `assets/gdm/codex-gdm-prussiangreen/gnome-shell-theme.gresource` and asserts the presence of new minimal-dark style markers such as a dedicated redesign comment and updated login-dialog color tokens.

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/gdm_theme_resource_style_test.sh`
Expected: FAIL because the current bundled resource still contains the older style markers.

### Task 2: Keep local checks aware of the new regression test

**Files:**
- Modify: `check.sh`
- Test: `bash ./check.sh`

- [ ] **Step 1: Add the new test script to `check.sh`**

Include `tests/gdm_theme_resource_style_test.sh` in the shell syntax and shellcheck list.

## Chunk 2: Minimal Dark Resource Redesign

### Task 3: Rebuild the GDM resource with stronger login styling

**Files:**
- Modify: `assets/gdm/codex-gdm-prussiangreen/gnome-shell-theme.gresource`
- Modify: supporting extracted resource sources in a temporary build workspace if needed
- Test: `tests/gdm_theme_resource_style_test.sh`

- [ ] **Step 1: Extract the current resource contents**

Use `gresource` to identify the bundled CSS path and export the relevant stylesheet into a temporary build workspace.

- [ ] **Step 2: Write the minimal implementation**

Update only the login-related CSS rules to:

- add a dedicated redesign marker comment
- shift the login dialog to deeper neutral blacks and cool grays
- give the card a clearer glass-panel feel
- make entry fields and buttons more obviously macOS-like and less green
- strengthen backdrop dimming and focus hierarchy

- [ ] **Step 3: Rebuild the bundled resource**

Use `glib-compile-resources` to regenerate `assets/gdm/codex-gdm-prussiangreen/gnome-shell-theme.gresource` from the modified sources.

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/gdm_theme_resource_style_test.sh`
Expected: PASS

## Chunk 3: Docs And Full Verification

### Task 4: Update user-facing documentation

**Files:**
- Modify: `docs/gdm-login-beautify.md`

- [ ] **Step 1: Document the expected visible changes**

Add a short section describing what users should now notice on the login screen after reinstalling or reapplying the custom GDM resource.

### Task 5: Run full verification

**Files:**
- Modify: none

- [ ] **Step 1: Run the resource-style regression test**

Run: `bash tests/gdm_theme_resource_style_test.sh`
Expected: PASS

- [ ] **Step 2: Run the existing GDM workflow regressions**

Run:

- `bash tests/gdm_theme_scripts_test.sh`
- `bash tests/gdm_theme_scripts_portable_test.sh`

Expected: PASS

- [ ] **Step 3: Run the repository checks**

Run: `bash ./check.sh`
Expected: PASS
