# CI Workflow Design

## Goal

Add a GitHub Actions workflow that validates this repository on Ubuntu 22.04 and Ubuntu 24.04 for pushes and pull requests.

## Scope

The workflow should only automate checks that already exist locally:

- `bash ./check.sh`
- `bash tests/fix_desktop_icons_test.sh`
- `bash tests/gdm_theme_scripts_test.sh`

It should not introduce new build logic, packaging, or desktop-environment integration tests.

## Approach

Use one workflow file at `.github/workflows/ci.yml` with two jobs:

- `check`: runs `bash ./check.sh`
- `test`: runs the two existing Bash regression tests

Both jobs use a matrix with `ubuntu-22.04` and `ubuntu-24.04`. Each job installs the small set of packages required by the current scripts in CI, specifically `shellcheck` and `ripgrep`.

## Rationale

Splitting static checks and tests into separate jobs improves failure visibility without adding much complexity. Reusing the repository's existing shell entrypoints keeps CI aligned with local developer workflows.

## Error Handling

The workflow should fail fast on any non-zero exit from the existing scripts. Dependency installation stays explicit in the workflow so runner differences are visible in logs.

## Verification

Add a repository test that asserts the workflow file exists and encodes the agreed contract:

- triggers on `push` and `pull_request`
- matrix includes Ubuntu 22.04 and 24.04
- uses `shellcheck` and `ripgrep`
- runs `check.sh` and both test scripts
