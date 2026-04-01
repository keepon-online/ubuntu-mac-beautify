#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CUSTOM="${PROJECT_ROOT}/assets/gdm/codex-gdm-prussiangreen/gnome-shell-theme.gresource"
ORIG=/usr/share/gnome-shell/theme/Yaru/gnome-shell-theme.gresource
LINK=/usr/share/gnome-shell/gdm-theme.gresource

if [[ "${GDM_THEME_TEST_MODE:-0}" == "1" ]]; then
  printf 'PROJECT_ROOT=%s\n' "${PROJECT_ROOT}"
  printf 'CUSTOM=%s\n' "${CUSTOM}"
  printf 'LINK=%s\n' "${LINK}"
  printf 'ORIG=%s\n' "${ORIG}"
  exit 0
fi

test -f "${CUSTOM}"
test -f "${ORIG}"

install -d /usr/local/share/gnome-shell/theme/codex-gdm-prussiangreen
install -m 0644 "${CUSTOM}" /usr/local/share/gnome-shell/theme/codex-gdm-prussiangreen/gnome-shell-theme.gresource

rm -f /etc/alternatives/gdm-theme.gresource "${LINK}"
update-alternatives --remove-all gdm-theme.gresource || true
update-alternatives --install "${LINK}" gdm-theme.gresource "${ORIG}" 100
update-alternatives --install "${LINK}" gdm-theme.gresource /usr/local/share/gnome-shell/theme/codex-gdm-prussiangreen/gnome-shell-theme.gresource 200
update-alternatives --set gdm-theme.gresource /usr/local/share/gnome-shell/theme/codex-gdm-prussiangreen/gnome-shell-theme.gresource

printf '== display ==\n'
update-alternatives --display gdm-theme.gresource | sed -n '1,120p'
printf '\n== symlink chain ==\n'
ls -l "${LINK}" /etc/alternatives/gdm-theme.gresource
printf '\n== marker ==\n'
strings /usr/local/share/gnome-shell/theme/codex-gdm-prussiangreen/gnome-shell-theme.gresource | grep -n 'Codex GDM prussiangreen override' | sed -n '1,20p'
