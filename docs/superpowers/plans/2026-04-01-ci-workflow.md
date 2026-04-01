# CI Workflow Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a GitHub Actions CI workflow that runs the existing repository checks on Ubuntu 22.04 and Ubuntu 24.04.

**Architecture:** Define the expected CI contract in a Bash regression test first, then implement a single GitHub Actions workflow with separate `check` and `test` jobs sharing the same Ubuntu version matrix. Keep the workflow thin by calling the existing repository scripts instead of duplicating shell logic in YAML.

**Tech Stack:** Bash, GitHub Actions YAML, existing repository scripts

---

## Chunk 1: Define the CI contract

### Task 1: Add the failing CI workflow regression test

**Files:**
- Create: `tests/ci_workflow_test.sh`
- Test: `tests/ci_workflow_test.sh`

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail

workflow_file="${PROJECT_ROOT}/.github/workflows/ci.yml"
[[ -f "${workflow_file}" ]] || fail "missing workflow"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/ci_workflow_test.sh`
Expected: FAIL because `.github/workflows/ci.yml` does not exist yet.

### Task 2: Implement the workflow

**Files:**
- Create: `.github/workflows/ci.yml`
- Modify: `README.md`
- Test: `tests/ci_workflow_test.sh`

- [ ] **Step 1: Write minimal implementation**

Create a workflow that:

- triggers on `push` and `pull_request`
- uses a matrix of `ubuntu-22.04` and `ubuntu-24.04`
- installs `shellcheck` and `ripgrep`
- runs `bash ./check.sh`
- runs `bash tests/fix_desktop_icons_test.sh`
- runs `bash tests/gdm_theme_scripts_test.sh`

- [ ] **Step 2: Run targeted test to verify it passes**

Run: `bash tests/ci_workflow_test.sh`
Expected: PASS

### Task 3: Document the CI entrypoint

**Files:**
- Modify: `README.md`
- Test: `bash ./check.sh`

- [ ] **Step 1: Update documentation**

Add a short note that GitHub Actions now runs the repository checks on Ubuntu 22.04 and 24.04.

- [ ] **Step 2: Run repository verification**

Run:

- `bash ./check.sh`
- `bash tests/ci_workflow_test.sh`
- `bash tests/fix_desktop_icons_test.sh`
- `bash tests/gdm_theme_scripts_test.sh`

Expected: all commands pass.
