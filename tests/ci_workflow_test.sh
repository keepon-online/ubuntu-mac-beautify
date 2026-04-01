#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW_FILE="${PROJECT_ROOT}/.github/workflows/ci.yml"

fail() {
  printf '[FAIL] %s\n' "$*" >&2
  exit 1
}

assert_file_contains() {
  local file="$1"
  local needle="$2"

  if ! rg -F -q "${needle}" "${file}"; then
    fail "expected ${file} to contain: ${needle}"
  fi
}

[[ -f "${WORKFLOW_FILE}" ]] || fail "missing workflow: ${WORKFLOW_FILE}"

assert_file_contains "${WORKFLOW_FILE}" "pull_request:"
assert_file_contains "${WORKFLOW_FILE}" "push:"
assert_file_contains "${WORKFLOW_FILE}" "ubuntu-22.04"
assert_file_contains "${WORKFLOW_FILE}" "ubuntu-24.04"
assert_file_contains "${WORKFLOW_FILE}" "sudo apt-get update"
assert_file_contains "${WORKFLOW_FILE}" "sudo apt-get install -y shellcheck ripgrep"
assert_file_contains "${WORKFLOW_FILE}" "bash ./check.sh"
assert_file_contains "${WORKFLOW_FILE}" "bash tests/fix_desktop_icons_test.sh"
assert_file_contains "${WORKFLOW_FILE}" "bash tests/gdm_theme_scripts_test.sh"

echo "[PASS] ci workflow test"
