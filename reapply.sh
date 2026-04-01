#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${PROJECT_ROOT}/lib/common.sh"

MODE="dark"
WALLPAPER_SERIES="ventura"
WALLPAPER_PATH=""
SHOW_APPS_BUTTON="false"
ENABLE_BLUR="true"
WITH_GDM="true"
DESKTOP="auto"
APPLY_KDE_PANEL="true"
APPLY_KDE_LAUNCHERS="true"
KDE_ROUND="auto"
WALLPAPER_DIR="${HOME}/.local/share/backgrounds/codex-macos-style"
PROJECT_GDM_OVERRIDE="not-run"

for arg in "$@"; do
  case "${arg}" in
    --light)
      MODE="light"
      ;;
    --dark)
      MODE="dark"
      ;;
    --desktop=*)
      DESKTOP="$(normalize_desktop "${arg#*=}")" || die "Unsupported desktop: ${arg#*=}"
      ;;
    --wallpaper=*)
      WALLPAPER_SERIES="${arg#*=}"
      ;;
    --wallpaper-path=*)
      WALLPAPER_PATH="${arg#*=}"
      ;;
    --show-apps-button)
      SHOW_APPS_BUTTON="true"
      ;;
    --skip-gdm)
      WITH_GDM="false"
      ;;
    --skip-kde-panel)
      APPLY_KDE_PANEL="false"
      ;;
    --skip-kde-launchers)
      APPLY_KDE_LAUNCHERS="false"
      ;;
    --kde-round)
      KDE_ROUND="true"
      ;;
    --kde-no-round)
      KDE_ROUND="false"
      ;;
    --skip-blur)
      ENABLE_BLUR="false"
      ;;
    -h|--help)
      cat <<'EOF'
Usage: ./reapply.sh [options]

Options:
  --desktop=DESKTOP          auto (default), gnome, or kde
  --dark                     Reapply the dark theme (default)
  --light                    Reapply the light theme
  --wallpaper=SERIES         Pick an existing wallpaper series in ~/.local/share/backgrounds/codex-macos-style
  --wallpaper-path=/path     Use a specific wallpaper file
  --show-apps-button         Show the app grid button in the dock (GNOME only)
  --skip-gdm                 Do not restyle the login screen (GNOME only)
  --skip-kde-panel           Do not restyle the Plasma panel (KDE only)
  --skip-kde-launchers       Do not configure default pinned apps on the Plasma panel (KDE only)
  --kde-round                Prefer rounded KDE window decorations
  --kde-no-round             Prefer the default KDE window decoration variant
  --skip-blur                Do not enable Blur my Shell (GNOME only)
EOF
      exit 0
      ;;
    *)
      die "Unknown argument: ${arg}"
      ;;
  esac
done

DESKTOP="$(resolve_desktop "${DESKTOP}")"
if [[ "${KDE_ROUND}" == "auto" ]]; then
  KDE_ROUND="$(default_kde_round_style "${WALLPAPER_SERIES}")"
fi

check_not_root
check_os
warn_if_session_mismatch "${DESKTOP}"

if [[ -z "${WALLPAPER_PATH}" ]]; then
  WALLPAPER_PATH="$(find_existing_wallpaper "${WALLPAPER_DIR}" "${WALLPAPER_SERIES}" "${MODE}" || true)"
fi

if [[ "${DESKTOP}" == "gnome" ]]; then
  if [[ "${APPLY_KDE_PANEL}" == "false" ]]; then
    warn "--skip-kde-panel is a KDE-only option and will be ignored for GNOME."
  fi
  if [[ "${APPLY_KDE_LAUNCHERS}" == "false" ]]; then
    warn "--skip-kde-launchers is a KDE-only option and will be ignored for GNOME."
  fi
  enable_extensions "${ENABLE_BLUR}"
  apply_appearance_settings "${MODE}" "${WALLPAPER_PATH}" "${SHOW_APPS_BUTTON}"
  if [[ "${WITH_GDM}" == "true" ]]; then
    if run_project_gdm_beautify; then
      PROJECT_GDM_OVERRIDE="attempted"
    else
      PROJECT_GDM_OVERRIDE="failed"
    fi
  fi
else
  if [[ "${SHOW_APPS_BUTTON}" == "true" ]]; then
    warn "--show-apps-button is a GNOME-only option and will be ignored for KDE."
  fi
  if [[ "${WITH_GDM}" == "false" ]]; then
    warn "--skip-gdm is a GNOME-only option and will be ignored for KDE."
  fi
  if [[ "${ENABLE_BLUR}" == "false" ]]; then
    warn "--skip-blur is a GNOME-only option and will be ignored for KDE."
  fi
  apply_kde_appearance_settings "${MODE}" "${WALLPAPER_PATH}" "${WALLPAPER_SERIES}" "${APPLY_KDE_PANEL}" "${APPLY_KDE_LAUNCHERS}" "${KDE_ROUND}"
fi

info "Done"
echo
echo "Project           : ${PROJECT_ROOT}"
echo "Desktop target    : ${DESKTOP}"
if [[ "${DESKTOP}" == "gnome" ]]; then
  echo "Applied theme     : $(theme_name_for_mode "${MODE}")"
  echo "GDM requested     : ${WITH_GDM}"
  echo "GDM custom theme  : ${PROJECT_GDM_OVERRIDE}"
else
  echo "Applied theme     : $(kde_theme_label "${WALLPAPER_SERIES}")"
  echo "Rounded windows   : ${KDE_ROUND}"
  echo "Plasma panel      : ${APPLY_KDE_PANEL}"
  echo "Pinned apps       : ${APPLY_KDE_LAUNCHERS}"
fi
echo "Wallpaper         : ${WALLPAPER_PATH:-not-updated}"
if [[ "${DESKTOP}" == "gnome" && "${WITH_GDM}" == "true" ]]; then
  echo "Rollback GDM      : sudo bash ./scripts/rollback-custom-gdm-prussiangreen.sh"
fi
