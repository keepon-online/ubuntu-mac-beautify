#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESOURCE_FILE="${PROJECT_ROOT}/assets/gdm/codex-gdm-prussiangreen/gnome-shell-theme.gresource"
RESOURCE_PATH="/org/gnome/shell/theme/gdm.css"

fail() {
  printf '[FAIL] %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"

  if [[ "${haystack}" != *"${needle}"* ]]; then
    fail "expected extracted gdm.css to contain: ${needle}"
  fi
}

command -v gresource >/dev/null 2>&1 || fail "gresource is required"
[[ -f "${RESOURCE_FILE}" ]] || fail "missing resource: ${RESOURCE_FILE}"

css="$(gresource extract "${RESOURCE_FILE}" "${RESOURCE_PATH}")"

assert_contains "${css}" "Codex GDM minimal dark redesign"
assert_contains "${css}" "background-color: rgba(10, 12, 16, 0.78);"
assert_contains "${css}" "box-shadow: inset 0 0 0 2px #8da2ff !important;"
assert_contains "${css}" "background-color: #8da2ff;"

echo "[PASS] gdm theme resource style test"
