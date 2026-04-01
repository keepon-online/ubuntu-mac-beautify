#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ASSET="${PROJECT_ROOT}/assets/gdm/codex-gdm-prussiangreen/gnome-shell-theme.gresource"
LINK=/usr/share/gnome-shell/gdm-theme.gresource
ORIG=/usr/share/gnome-shell/theme/Yaru/gnome-shell-theme.gresource
DST_DIR=/usr/local/share/gnome-shell/theme/codex-gdm-prussiangreen
DST=${DST_DIR}/gnome-shell-theme.gresource

if [[ "${GDM_THEME_TEST_MODE:-0}" == "1" ]]; then
  printf 'PROJECT_ROOT=%s\n' "${PROJECT_ROOT}"
  printf 'ASSET=%s\n' "${ASSET}"
  printf 'LINK=%s\n' "${LINK}"
  printf 'ORIG=%s\n' "${ORIG}"
  printf 'DST=%s\n' "${DST}"
  exit 0
fi

test -f "${ASSET}"
test -f "${ORIG}"

install -d "${DST_DIR}"
install -m 0644 "${ASSET}" "${DST}"

rm -f /etc/alternatives/gdm-theme.gresource "${LINK}"
update-alternatives --remove-all gdm-theme.gresource || true
update-alternatives --install "${LINK}" gdm-theme.gresource "${ORIG}" 100
update-alternatives --install "${LINK}" gdm-theme.gresource "${DST}" 200
update-alternatives --set gdm-theme.gresource "${DST}"

printf '== alternatives display ==\n'
update-alternatives --display gdm-theme.gresource | sed -n '1,80p'
printf '\n== symlink chain ==\n'
ls -l "${LINK}" /etc/alternatives/gdm-theme.gresource
printf '\n== resource marker ==\n'
strings "${DST}" | grep -n 'Codex GDM prussiangreen override' | sed -n '1,20p'
