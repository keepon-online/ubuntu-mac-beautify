#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ORIG=/usr/share/gnome-shell/theme/Yaru/gnome-shell-theme.gresource
LINK=/usr/share/gnome-shell/gdm-theme.gresource

if [[ "${GDM_THEME_TEST_MODE:-0}" == "1" ]]; then
  printf 'PROJECT_ROOT=%s\n' "${PROJECT_ROOT}"
  printf 'LINK=%s\n' "${LINK}"
  printf 'ORIG=%s\n' "${ORIG}"
  exit 0
fi

test -f "${ORIG}"

if ! update-alternatives --query gdm-theme.gresource >/dev/null 2>&1; then
  rm -f /etc/alternatives/gdm-theme.gresource "${LINK}"
  update-alternatives --install "${LINK}" gdm-theme.gresource "${ORIG}" 100
fi

update-alternatives --set gdm-theme.gresource "${ORIG}"

printf '== alternatives display ==\n'
update-alternatives --display gdm-theme.gresource | sed -n '1,80p'
printf '\n== symlink chain ==\n'
ls -l "${LINK}" /etc/alternatives/gdm-theme.gresource
