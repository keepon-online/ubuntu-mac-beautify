#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_PATH="${PROJECT_ROOT}/fix-desktop-icons.sh"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local file="$1"
  local expected="$2"

  if ! grep -Fqx "${expected}" "${file}"; then
    printf 'Expected line not found in %s: %s\n' "${file}" "${expected}" >&2
    sed -n '1,120p' "${file}" >&2 || true
    fail "assert_contains"
  fi
}

assert_not_contains() {
  local file="$1"
  local unexpected="$2"

  if grep -Fqx "${unexpected}" "${file}"; then
    printf 'Unexpected line found in %s: %s\n' "${file}" "${unexpected}" >&2
    sed -n '1,120p' "${file}" >&2 || true
    fail "assert_not_contains"
  fi
}

write_desktop_file() {
  local path="$1"
  shift

  mkdir -p "$(dirname "${path}")"
  {
    printf '[Desktop Entry]\n'
    printf '%s\n' "$@"
  } >"${path}"
}

run_repair() {
  local workspace="$1"
  local output_file="$2"

  USER_APPLICATIONS_DIR="${workspace}/user-applications" \
  SYSTEM_APPLICATIONS_DIRS="${workspace}/system-applications" \
  UPDATE_DESKTOP_DATABASE_BIN=true \
  bash "${SCRIPT_PATH}" >"${output_file}" 2>&1
}

test_match_by_mimetype() {
  local workspace output_file handler_file
  workspace="$(mktemp -d)"
  output_file="${workspace}/output.txt"
  handler_file="${workspace}/user-applications/cc-switch-handler.desktop"

  write_desktop_file \
    "${handler_file}" \
    "Type=Application" \
    "Name=CC Switch" \
    "Exec=/usr/bin/cc-switch %u" \
    "Terminal=false" \
    "MimeType=x-scheme-handler/ccswitch" \
    "NoDisplay=true"

  write_desktop_file \
    "${workspace}/system-applications/CC Switch.desktop" \
    "Type=Application" \
    "Name=CC Switch" \
    "Exec=cc-switch" \
    "Icon=cc-switch" \
    "StartupWMClass=cc-switch" \
    "MimeType=x-scheme-handler/ccswitch"

  run_repair "${workspace}" "${output_file}"

  assert_contains "${handler_file}" "Icon=cc-switch"
  assert_contains "${handler_file}" "StartupWMClass=cc-switch"
  assert_contains "${output_file}" "fixed=1"
  assert_contains "${output_file}" "skipped=0"
  assert_contains "${output_file}" "unchanged=0"
}

test_match_by_exec() {
  local workspace output_file handler_file
  workspace="$(mktemp -d)"
  output_file="${workspace}/output.txt"
  handler_file="${workspace}/user-applications/sample-handler.desktop"

  write_desktop_file \
    "${handler_file}" \
    "Type=Application" \
    "Name=Sample App" \
    "Exec=/opt/sample-app --open" \
    "NoDisplay=true"

  write_desktop_file \
    "${workspace}/system-applications/sample.desktop" \
    "Type=Application" \
    "Name=Sample Application" \
    "Exec=/usr/bin/sample-app %u" \
    "Icon=sample-app" \
    "StartupWMClass=sample-app"

  run_repair "${workspace}" "${output_file}"

  assert_contains "${handler_file}" "Icon=sample-app"
  assert_contains "${handler_file}" "StartupWMClass=sample-app"
  assert_contains "${output_file}" "fixed=1"
}

test_ambiguous_match_is_skipped() {
  local workspace output_file handler_file
  workspace="$(mktemp -d)"
  output_file="${workspace}/output.txt"
  handler_file="${workspace}/user-applications/ambiguous.desktop"

  write_desktop_file \
    "${handler_file}" \
    "Type=Application" \
    "Name=Shared App" \
    "Exec=/usr/bin/shared-app" \
    "MimeType=x-scheme-handler/shared" \
    "NoDisplay=true"

  write_desktop_file \
    "${workspace}/system-applications/shared-one.desktop" \
    "Type=Application" \
    "Name=Shared App" \
    "Exec=/usr/bin/shared-app" \
    "Icon=shared-one" \
    "StartupWMClass=shared-one" \
    "MimeType=x-scheme-handler/shared"

  write_desktop_file \
    "${workspace}/system-applications/shared-two.desktop" \
    "Type=Application" \
    "Name=Shared App" \
    "Exec=/opt/shared-app" \
    "Icon=shared-two" \
    "StartupWMClass=shared-two" \
    "MimeType=x-scheme-handler/shared"

  run_repair "${workspace}" "${output_file}"

  assert_not_contains "${handler_file}" "Icon=shared-one"
  assert_not_contains "${handler_file}" "StartupWMClass=shared-one"
  assert_contains "${output_file}" "fixed=0"
  assert_contains "${output_file}" "skipped=1"
}

test_complete_entry_is_unchanged() {
  local workspace output_file handler_file
  workspace="$(mktemp -d)"
  output_file="${workspace}/output.txt"
  handler_file="${workspace}/user-applications/complete.desktop"

  write_desktop_file \
    "${handler_file}" \
    "Type=Application" \
    "Name=Complete App" \
    "Exec=/usr/bin/complete" \
    "Icon=already-set" \
    "StartupWMClass=already-set" \
    "NoDisplay=true"

  run_repair "${workspace}" "${output_file}"

  assert_contains "${handler_file}" "Icon=already-set"
  assert_contains "${handler_file}" "StartupWMClass=already-set"
  assert_contains "${output_file}" "fixed=0"
  assert_contains "${output_file}" "skipped=0"
  assert_contains "${output_file}" "unchanged=1"
}

main() {
  test_match_by_mimetype
  test_match_by_exec
  test_ambiguous_match_is_skipped
  test_complete_entry_is_unchanged
  printf 'PASS\n'
}

main "$@"
