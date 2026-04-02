#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  printf '[FAIL] %s\n' "$*" >&2
  exit 1
}

workspace="$(mktemp -d)"
copy_root="${workspace}/portable-repo"

cleanup() {
  rm -rf "${workspace}"
}
trap cleanup EXIT

mkdir -p "${copy_root}/scripts" "${copy_root}/tests" "${copy_root}/lib"
cp "${PROJECT_ROOT}/scripts/install-custom-gdm-prussiangreen.sh" "${copy_root}/scripts/"
cp "${PROJECT_ROOT}/scripts/repair-gdm-theme-alternative.sh" "${copy_root}/scripts/"
cp "${PROJECT_ROOT}/scripts/rollback-custom-gdm-prussiangreen.sh" "${copy_root}/scripts/"
cp "${PROJECT_ROOT}/tests/gdm_theme_scripts_test.sh" "${copy_root}/tests/"
cp "${PROJECT_ROOT}/lib/common.sh" "${copy_root}/lib/"
cp "${PROJECT_ROOT}/install.sh" "${copy_root}/"
cp "${PROJECT_ROOT}/reapply.sh" "${copy_root}/"
cp "${PROJECT_ROOT}/reset.sh" "${copy_root}/"
cp "${PROJECT_ROOT}/uninstall.sh" "${copy_root}/"

output="$(cd "${copy_root}" && bash tests/gdm_theme_scripts_test.sh 2>&1)" || {
  printf '%s\n' "${output}" >&2
  fail "gdm theme scripts test should be portable across checkout paths"
}

printf '%s\n' "${output}" | rg -q '\[PASS\] gdm theme scripts test' || fail "expected portable test pass output"

echo "[PASS] gdm theme scripts portable test"
