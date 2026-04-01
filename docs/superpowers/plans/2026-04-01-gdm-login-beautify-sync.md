# GDM Login Beautify Sync Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Sync the validated GDM login beautification workflow into the `ubuntu-mac-beautify` project as self-contained documentation, resource assets, and maintenance scripts.

**Architecture:** Store the compiled custom GDM resource under project `assets/`, ship project-relative install/repair/rollback scripts under `scripts/`, and document the full workflow in `docs/` plus a README entry. Keep the existing system-level installation logic reversible through `update-alternatives`.

**Tech Stack:** Bash, GDM3, GNOME Shell gresource, update-alternatives, Markdown

---

## Chunk 1: Project Assets And Scripts

### Task 1: Add the custom GDM resource and shell scripts

**Files:**
- Create: `assets/gdm/codex-gdm-prussiangreen/gnome-shell-theme.gresource`
- Create: `scripts/install-custom-gdm-prussiangreen.sh`
- Create: `scripts/repair-gdm-theme-alternative.sh`
- Create: `scripts/rollback-custom-gdm-prussiangreen.sh`
- Modify: `check.sh`

- [ ] **Step 1: Add the project resource asset**

Copy the validated custom `gnome-shell-theme.gresource` into `assets/gdm/codex-gdm-prussiangreen/`.

- [ ] **Step 2: Write the install script**

Create a project-relative install script that installs the resource into `/usr/local/share/...`, rebuilds the `gdm-theme.gresource` alternatives chain using `/usr/share/gnome-shell/gdm-theme.gresource` as the master link, and selects the custom resource.

- [ ] **Step 3: Write the repair and rollback scripts**

Create a repair script that rebuilds a broken alternatives chain and a rollback script that points GDM back to Yaru safely.

- [ ] **Step 4: Extend project checks**

Add the new shell scripts to `check.sh` so syntax and shellcheck cover them.

## Chunk 2: Documentation

### Task 2: Add user-facing docs for the GDM workflow

**Files:**
- Create: `docs/gdm-login-beautify.md`
- Modify: `README.md`

- [ ] **Step 1: Write the standalone GDM beautify guide**

Document the symptom, why dconf-only theming was insufficient, how the custom gresource approach works, install/repair/rollback commands, and how to observe the result.

- [ ] **Step 2: Add README entry points**

Update `README.md` so users can discover the new GDM beautify guide and scripts from the main project page.

## Chunk 3: Verification

### Task 3: Verify the synced project state

**Files:**
- Modify: none

- [ ] **Step 1: Run shell syntax checks**

Run: `bash -n scripts/install-custom-gdm-prussiangreen.sh scripts/repair-gdm-theme-alternative.sh scripts/rollback-custom-gdm-prussiangreen.sh`
Expected: PASS

- [ ] **Step 2: Verify the resource marker**

Run: `strings assets/gdm/codex-gdm-prussiangreen/gnome-shell-theme.gresource | grep 'Codex GDM prussiangreen override'`
Expected: one matching line

- [ ] **Step 3: Run project checks**

Run: `bash ./check.sh`
Expected: PASS, or existing shellcheck baseline only if unrelated

- [ ] **Step 4: Review the diff**

Run: `git status --short`
Expected: only the new asset, scripts, docs, and README/check changes appear
