#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_SCRIPT="${PROJECT_ROOT}/scripts/install-custom-gdm-prussiangreen.sh"
REPAIR_SCRIPT="${PROJECT_ROOT}/scripts/repair-gdm-theme-alternative.sh"
ROLLBACK_SCRIPT="${PROJECT_ROOT}/scripts/rollback-custom-gdm-prussiangreen.sh"
COMMON_SH="${PROJECT_ROOT}/lib/common.sh"
MAIN_INSTALL="${PROJECT_ROOT}/install.sh"
REAPPLY_SCRIPT="${PROJECT_ROOT}/reapply.sh"
RESET_SCRIPT="${PROJECT_ROOT}/reset.sh"
UNINSTALL_SCRIPT="${PROJECT_ROOT}/uninstall.sh"

fail() {
  echo "[FAIL] $*" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "${haystack}" != *"${needle}"* ]]; then
    fail "expected output to contain: ${needle}"
  fi
}

run_probe() {
  local script="$1"
  GDM_THEME_TEST_MODE=1 bash "${script}"
}

run_helper_probe() {
  GDM_THEME_HELPER_TEST_MODE=1 PROJECT_ROOT="${PROJECT_ROOT}" bash -lc '
    source "'"${COMMON_SH}"'"
    run_project_gdm_beautify
  '
}

run_rollback_helper_probe() {
  GDM_THEME_HELPER_TEST_MODE=1 PROJECT_ROOT="${PROJECT_ROOT}" bash -lc '
    source "'"${COMMON_SH}"'"
    run_project_gdm_rollback
  '
}

[[ -f "${INSTALL_SCRIPT}" ]] || fail "missing install script"
[[ -f "${REPAIR_SCRIPT}" ]] || fail "missing repair script"
[[ -f "${ROLLBACK_SCRIPT}" ]] || fail "missing rollback script"
[[ -f "${COMMON_SH}" ]] || fail "missing common.sh"
[[ -f "${MAIN_INSTALL}" ]] || fail "missing install.sh"
[[ -f "${REAPPLY_SCRIPT}" ]] || fail "missing reapply.sh"
[[ -f "${RESET_SCRIPT}" ]] || fail "missing reset.sh"
[[ -f "${UNINSTALL_SCRIPT}" ]] || fail "missing uninstall.sh"

install_out="$(run_probe "${INSTALL_SCRIPT}")"
repair_out="$(run_probe "${REPAIR_SCRIPT}")"
rollback_out="$(run_probe "${ROLLBACK_SCRIPT}")"
helper_out="$(run_helper_probe)"
rollback_helper_out="$(run_rollback_helper_probe)"

assert_contains "${install_out}" "PROJECT_ROOT=${PROJECT_ROOT}"
assert_contains "${install_out}" "ASSET=${PROJECT_ROOT}/assets/gdm/codex-gdm-prussiangreen/gnome-shell-theme.gresource"
assert_contains "${repair_out}" "LINK=/usr/share/gnome-shell/gdm-theme.gresource"
assert_contains "${rollback_out}" "ORIG=/usr/share/gnome-shell/theme/Yaru/gnome-shell-theme.gresource"
assert_contains "${helper_out}" "RUN_PROJECT_GDM_BEAUTIFY=${PROJECT_ROOT}/scripts/install-custom-gdm-prussiangreen.sh"
assert_contains "${rollback_helper_out}" "RUN_PROJECT_GDM_ROLLBACK=${PROJECT_ROOT}/scripts/rollback-custom-gdm-prussiangreen.sh"

if ! rg -q 'run_project_gdm_beautify' "${MAIN_INSTALL}"; then
  fail "install.sh does not call run_project_gdm_beautify"
fi

if ! rg -q -- '--skip-gdm' "${REAPPLY_SCRIPT}"; then
  fail "reapply.sh does not expose --skip-gdm"
fi

if ! rg -q 'run_project_gdm_beautify' "${REAPPLY_SCRIPT}"; then
  fail "reapply.sh does not call run_project_gdm_beautify"
fi

if ! rg -q -- '--keep-gdm' "${RESET_SCRIPT}"; then
  fail "reset.sh does not expose --keep-gdm"
fi

if ! rg -q 'run_project_gdm_rollback' "${RESET_SCRIPT}"; then
  fail "reset.sh does not call run_project_gdm_rollback"
fi

if ! rg -q -- '--keep-gdm' "${UNINSTALL_SCRIPT}"; then
  fail "uninstall.sh does not expose --keep-gdm"
fi

if ! rg -q 'run_project_gdm_rollback' "${UNINSTALL_SCRIPT}"; then
  fail "uninstall.sh does not call run_project_gdm_rollback"
fi

echo "[PASS] gdm theme scripts test"
