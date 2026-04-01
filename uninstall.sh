#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${PROJECT_ROOT}/lib/common.sh"

REMOVE_WALLPAPERS="true"
RESET_SETTINGS="true"
DISABLE_BLUR="true"
ROLLBACK_GDM="true"
DESKTOP="auto"

for arg in "$@"; do
  case "${arg}" in
    --desktop=*)
      DESKTOP="$(normalize_desktop "${arg#*=}")" || die "Unsupported desktop: ${arg#*=}"
      ;;
    --keep-wallpapers)
      REMOVE_WALLPAPERS="false"
      ;;
    --skip-reset)
      RESET_SETTINGS="false"
      ;;
    --keep-blur)
      DISABLE_BLUR="false"
      ;;
    --keep-gdm)
      ROLLBACK_GDM="false"
      ;;
    -h|--help)
      cat <<'EOF'
Usage: ./uninstall.sh [options]

Options:
  --desktop=DESKTOP    auto (default), gnome, or kde
  --keep-wallpapers    Keep wallpapers under ~/.local/share/backgrounds/codex-macos-style
  --skip-reset         Do not reset appearance settings before removal
  --keep-blur          Do not disable Blur my Shell before removal (GNOME only)
  --keep-gdm           Do not roll back the project custom GDM theme (GNOME only)

This script removes user-level files installed by this project.
It does not fully revert upstream WhiteSur GDM login screen tweaks.
EOF
      exit 0
      ;;
    *)
      die "Unknown argument: ${arg}"
      ;;
  esac
done

DESKTOP="$(resolve_desktop "${DESKTOP}")"

check_not_root
check_os
warn_if_session_mismatch "${DESKTOP}"

if [[ "${DESKTOP}" == "gnome" ]]; then
  if [[ "${DISABLE_BLUR}" == "true" ]]; then
    disable_extensions
  fi

  if [[ "${RESET_SETTINGS}" == "true" ]]; then
    reset_appearance_settings
  fi

  if [[ "${ROLLBACK_GDM}" == "true" ]]; then
    if run_project_gdm_rollback; then
      ROLLBACK_GDM="attempted"
    else
      ROLLBACK_GDM="failed"
    fi
  else
    ROLLBACK_GDM="skipped"
  fi
else
  if [[ "${DISABLE_BLUR}" == "false" ]]; then
    warn "--keep-blur is a GNOME-only option and will be ignored for KDE."
  fi
  if [[ "${ROLLBACK_GDM}" == "false" ]]; then
    warn "--keep-gdm is a GNOME-only option and will be ignored for KDE."
  fi

  if [[ "${RESET_SETTINGS}" == "true" ]]; then
    reset_kde_appearance_settings
  fi
fi

info "Removing project-installed user files"
if [[ "${DESKTOP}" == "gnome" ]]; then
  remove_path_if_exists "${HOME}/.local/share/gnome-shell/extensions/blur-my-shell@aunetx"
fi

remove_path_if_exists "${HOME}/.local/share/icons/McMojave-cursors"
remove_path_if_exists "${HOME}/.local/share/icons/WhiteSur"
remove_path_if_exists "${HOME}/.local/share/icons/WhiteSur-dark"
remove_path_if_exists "${HOME}/.local/share/icons/WhiteSur-light"

for path in "${HOME}"/.themes/WhiteSur*; do
  if [[ -e "${path}" ]]; then
    remove_path_if_exists "${path}"
  fi
done

if [[ "${DESKTOP}" == "kde" ]]; then
  remove_kde_installed_files
fi

if [[ "${REMOVE_WALLPAPERS}" == "true" ]]; then
  remove_path_if_exists "${HOME}/.local/share/backgrounds/codex-macos-style"
fi

if [[ "${DESKTOP}" == "gnome" ]]; then
  warn "uninstall.sh only rolls back the project custom GDM theme."
  warn "It does not fully revert any upstream WhiteSur GDM tweaks."
fi

info "Done"
echo
echo "Project           : ${PROJECT_ROOT}"
echo "Desktop target    : ${DESKTOP}"
echo "Settings reset    : ${RESET_SETTINGS}"
echo "Wallpapers removed: ${REMOVE_WALLPAPERS}"
if [[ "${DESKTOP}" == "gnome" ]]; then
  echo "GDM rolled back   : ${ROLLBACK_GDM}"
fi
