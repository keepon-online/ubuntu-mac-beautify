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
WALLPAPER_DIR="${HOME}/.local/share/backgrounds/codex-macos-style"

for arg in "$@"; do
  case "${arg}" in
    --light)
      MODE="light"
      ;;
    --dark)
      MODE="dark"
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
    --skip-blur)
      ENABLE_BLUR="false"
      ;;
    -h|--help)
      cat <<'EOF'
Usage: ./reapply.sh [options]

Options:
  --dark                     Reapply the dark theme (default)
  --light                    Reapply the light theme
  --wallpaper=SERIES         Pick an existing wallpaper series in ~/.local/share/backgrounds/codex-macos-style
  --wallpaper-path=/path     Use a specific wallpaper file
  --show-apps-button         Show the app grid button in the dock
  --skip-blur                Do not enable Blur my Shell
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

if [[ -z "${WALLPAPER_PATH}" ]]; then
  WALLPAPER_PATH="$(find_existing_wallpaper "${WALLPAPER_DIR}" "${WALLPAPER_SERIES}" "${MODE}" || true)"
fi

enable_extensions "${ENABLE_BLUR}"
apply_appearance_settings "${MODE}" "${WALLPAPER_PATH}" "${SHOW_APPS_BUTTON}"

info "Done"
echo
echo "Project           : ${PROJECT_ROOT}"
echo "Applied theme     : $(theme_name_for_mode "${MODE}")"
echo "Wallpaper         : ${WALLPAPER_PATH:-not-updated}"
