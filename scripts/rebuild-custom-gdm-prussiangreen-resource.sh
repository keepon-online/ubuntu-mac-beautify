#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
RESOURCE_FILE="${PROJECT_ROOT}/assets/gdm/codex-gdm-prussiangreen/gnome-shell-theme.gresource"
OVERRIDE_FILE="${PROJECT_ROOT}/assets/gdm/codex-gdm-prussiangreen-src/gdm-login-override.css"
GDM_CSS_PATH="org/gnome/shell/theme/gdm.css"
OLD_MARKER='/* Codex GDM prussiangreen override */'

fail() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

command -v gresource >/dev/null 2>&1 || fail "gresource is required"
command -v glib-compile-resources >/dev/null 2>&1 || fail "glib-compile-resources is required"
[[ -f "${RESOURCE_FILE}" ]] || fail "missing resource: ${RESOURCE_FILE}"
[[ -f "${OVERRIDE_FILE}" ]] || fail "missing override: ${OVERRIDE_FILE}"

workspace="$(mktemp -d)"
cleanup() {
  rm -rf "${workspace}"
}
trap cleanup EXIT

source_root="${workspace}/source"
manifest_file="${workspace}/custom-gdm.gresource.xml"
mkdir -p "${source_root}"

mapfile -t resource_entries < <(gresource list "${RESOURCE_FILE}")
[[ "${#resource_entries[@]}" -gt 0 ]] || fail "resource list is empty"

for entry in "${resource_entries[@]}"; do
  rel_path="${entry#/}"
  target_path="${source_root}/${rel_path}"
  mkdir -p "$(dirname "${target_path}")"
  gresource extract "${RESOURCE_FILE}" "${entry}" >"${target_path}"
done

gdm_css_file="${source_root}/${GDM_CSS_PATH}"
[[ -f "${gdm_css_file}" ]] || fail "missing extracted gdm.css"
grep -F -q "${OLD_MARKER}" "${gdm_css_file}" || fail "old GDM override marker not found"

python3 - "${gdm_css_file}" "${OVERRIDE_FILE}" <<'PY'
from pathlib import Path
import sys

css_path = Path(sys.argv[1])
override_path = Path(sys.argv[2])
marker = "/* Codex GDM prussiangreen override */"
css = css_path.read_text()
idx = css.find(marker)
if idx < 0:
    raise SystemExit("missing old marker")
css_path.write_text(css[:idx].rstrip() + "\n\n" + override_path.read_text().rstrip() + "\n")
PY

{
  printf '<gresources>\n'
  printf '  <gresource prefix="/">\n'
  for entry in "${resource_entries[@]}"; do
    printf '    <file>%s</file>\n' "${entry#/}"
  done
  printf '  </gresource>\n'
  printf '</gresources>\n'
} >"${manifest_file}"

glib-compile-resources \
  --sourcedir="${source_root}" \
  --target="${RESOURCE_FILE}" \
  "${manifest_file}"

printf '[INFO] Rebuilt %s\n' "${RESOURCE_FILE}"
