#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${PROJECT_ROOT}/lib/common.sh"

REMOVE_WALLPAPERS="true"
RESET_SETTINGS="true"
DISABLE_BLUR="true"

for arg in "$@"; do
  case "${arg}" in
    --keep-wallpapers)
      REMOVE_WALLPAPERS="false"
      ;;
    --skip-reset)
      RESET_SETTINGS="false"
      ;;
    --keep-blur)
      DISABLE_BLUR="false"
      ;;
    -h|--help)
      cat <<'EOF'
Usage: ./uninstall.sh [options]

Options:
  --keep-wallpapers   Keep wallpapers under ~/.local/share/backgrounds/codex-macos-style
  --skip-reset        Do not reset GNOME appearance settings before removal
  --keep-blur         Do not disable Blur my Shell before removal

This script removes user-level files installed by this project.
It does not fully revert GDM login screen tweaks.
EOF
      exit 0
      ;;
    *)
      die "Unknown argument: ${arg}"
      ;;
  esac
done

check_not_root
check_os

if [[ "${DISABLE_BLUR}" == "true" ]]; then
  disable_extensions
fi

if [[ "${RESET_SETTINGS}" == "true" ]]; then
  reset_appearance_settings
fi

info "Removing project-installed user files"
remove_path_if_exists "${HOME}/.local/share/gnome-shell/extensions/blur-my-shell@aunetx"
remove_path_if_exists "${HOME}/.local/share/icons/McMojave-cursors"
remove_path_if_exists "${HOME}/.local/share/icons/WhiteSur"
remove_path_if_exists "${HOME}/.local/share/icons/WhiteSur-dark"
remove_path_if_exists "${HOME}/.local/share/icons/WhiteSur-light"

for path in "${HOME}"/.themes/WhiteSur*; do
  if [[ -e "${path}" ]]; then
    remove_path_if_exists "${path}"
  fi
done

if [[ "${REMOVE_WALLPAPERS}" == "true" ]]; then
  remove_path_if_exists "${HOME}/.local/share/backgrounds/codex-macos-style"
fi

warn "GDM login screen changes are not automatically reverted by uninstall.sh."
warn "If you changed GDM with install.sh, rerun the WhiteSur GDM tweak manually to restore it."

info "Done"
echo
echo "Project           : ${PROJECT_ROOT}"
echo "Settings reset    : ${RESET_SETTINGS}"
echo "Wallpapers removed: ${REMOVE_WALLPAPERS}"
