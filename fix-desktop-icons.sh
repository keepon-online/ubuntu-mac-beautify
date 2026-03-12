#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${PROJECT_ROOT}/lib/common.sh"

USER_APPLICATIONS_DIR="${USER_APPLICATIONS_DIR:-${HOME}/.local/share/applications}"
SYSTEM_APPLICATIONS_DIRS="${SYSTEM_APPLICATIONS_DIRS:-${USER_APPLICATIONS_DIR}:/usr/local/share/applications:/usr/share/applications}"
UPDATE_DESKTOP_DATABASE_BIN="${UPDATE_DESKTOP_DATABASE_BIN:-update-desktop-database}"

usage() {
  cat <<'EOF'
Usage: ./fix-desktop-icons.sh

Repairs hidden user desktop entries under ~/.local/share/applications that are
missing Icon= or StartupWMClass= by copying those fields from a matching visible
application desktop entry when the match is unambiguous.
EOF
}

fixed_count=0
skipped_count=0
unchanged_count=0

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

check_not_root

if [[ ! -d "${USER_APPLICATIONS_DIR}" ]]; then
  info "User applications directory not found: ${USER_APPLICATIONS_DIR}"
  printf 'fixed=0\n'
  printf 'skipped=0\n'
  printf 'unchanged=0\n'
  exit 0
fi

while IFS= read -r -d '' desktop_file; do
  source_file=""
  source_icon=""
  source_wmclass=""
  patch_icon=""
  patch_wmclass=""
  match_status=0

  if ! desktop_entry_is_hidden "${desktop_file}"; then
    continue
  fi

  if ! desktop_entry_has_missing_repair_fields "${desktop_file}"; then
    unchanged_count=$((unchanged_count + 1))
    continue
  fi

  if source_file="$(find_desktop_entry_repair_source "${desktop_file}" "${USER_APPLICATIONS_DIR}" "${SYSTEM_APPLICATIONS_DIRS}")"; then
    :
  else
    match_status=$?
    case "${match_status}" in
      1)
        warn "Skipped ${desktop_file}: no visible source match."
        ;;
      2)
        warn "Skipped ${desktop_file}: multiple visible source matches."
        ;;
      *)
        warn "Skipped ${desktop_file}: unexpected matching error."
        ;;
    esac
    skipped_count=$((skipped_count + 1))
    continue
  fi

  if ! desktop_entry_has_key "${desktop_file}" "Icon"; then
    source_icon="$(desktop_entry_get_value "${source_file}" "Icon" || true)"
    patch_icon="${source_icon}"
  fi

  if ! desktop_entry_has_key "${desktop_file}" "StartupWMClass"; then
    source_wmclass="$(desktop_entry_get_value "${source_file}" "StartupWMClass" || true)"
    patch_wmclass="${source_wmclass}"
  fi

  if [[ -z "${patch_icon}" && -z "${patch_wmclass}" ]]; then
    warn "Skipped ${desktop_file}: source entry is missing required metadata."
    skipped_count=$((skipped_count + 1))
    continue
  fi

  backup_file_with_timestamp "${desktop_file}" >/dev/null
  patch_desktop_entry_missing_fields "${desktop_file}" "${patch_icon}" "${patch_wmclass}"
  info "Repaired ${desktop_file} using ${source_file}"
  fixed_count=$((fixed_count + 1))
done < <(desktop_entry_list_files "${USER_APPLICATIONS_DIR}")

if has_command "${UPDATE_DESKTOP_DATABASE_BIN}"; then
  "${UPDATE_DESKTOP_DATABASE_BIN}" "${USER_APPLICATIONS_DIR}" >/dev/null 2>&1 || \
    warn "Could not refresh desktop database for ${USER_APPLICATIONS_DIR}."
fi

printf 'fixed=%s\n' "${fixed_count}"
printf 'skipped=%s\n' "${skipped_count}"
printf 'unchanged=%s\n' "${unchanged_count}"
