#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${PROJECT_ROOT}/lib/common.sh"

MODE="dark"
KEEP_WORKDIR="false"
WITH_GDM="true"
WITH_BLUR="true"
WITH_FLATPAK_FIX="true"
WALLPAPER_SERIES="ventura"
SHOW_APPS_BUTTON="false"

for arg in "$@"; do
  case "${arg}" in
    --light)
      MODE="light"
      ;;
    --dark)
      MODE="dark"
      ;;
    --skip-gdm)
      WITH_GDM="false"
      ;;
    --skip-blur)
      WITH_BLUR="false"
      ;;
    --skip-flatpak-fix)
      WITH_FLATPAK_FIX="false"
      ;;
    --show-apps-button)
      SHOW_APPS_BUTTON="true"
      ;;
    --keep-workdir)
      KEEP_WORKDIR="true"
      ;;
    --wallpaper=*)
      WALLPAPER_SERIES="${arg#*=}"
      ;;
    -h|--help)
      cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --dark                Use the dark WhiteSur theme (default)
  --light               Use the light WhiteSur theme
  --skip-gdm            Do not style the login screen
  --skip-blur           Do not install Blur my Shell
  --skip-flatpak-fix    Skip Flatpak theme integration
  --show-apps-button    Show the app grid button in the dock
  --wallpaper=SERIES    Wallpaper series hint, e.g. ventura or sonoma
  --keep-workdir        Keep the temporary repo checkout for inspection
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
require_command sudo

PACKAGES=(
  curl
  fonts-inter
  fonts-jetbrains-mono
  fonts-noto-cjk
  gettext
  git
  gnome-shell-extension-manager
  gnome-shell-extensions
  gnome-tweaks
  gtk2-engines-murrine
  gtk2-engines-pixbuf
  imagemagick
  inkscape
  libglib2.0-dev-bin
  libxml2-utils
  make
  optipng
  sassc
  wget
)

WORKDIR="$(mktemp -d)"
cleanup() {
  if [[ "${KEEP_WORKDIR}" != "true" && -d "${WORKDIR}" ]]; then
    rm -rf "${WORKDIR}"
  fi
}
trap cleanup EXIT

WALLPAPER_DIR="${HOME}/.local/share/backgrounds/codex-macos-style"
WALLPAPER_BASENAME="${WALLPAPER_DIR}/macos-${WALLPAPER_SERIES}-${MODE}"
GNOME_MAJOR="$(get_gnome_major || true)"

info "Refreshing package index"
sudo apt update

info "Installing required packages"
sudo apt install -y "${PACKAGES[@]}"

info "Cloning official theme repositories"
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git "${WORKDIR}/WhiteSur-gtk-theme"
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git "${WORKDIR}/WhiteSur-icon-theme"
git clone --depth=1 https://github.com/vinceliuice/McMojave-cursors.git "${WORKDIR}/McMojave-cursors"
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-wallpapers.git "${WORKDIR}/WhiteSur-wallpapers"

if [[ "${WITH_BLUR}" == "true" ]]; then
  if [[ -n "${GNOME_MAJOR}" ]]; then
    info "Cloning Blur my Shell for GNOME Shell ${GNOME_MAJOR}"
    clone_blur_my_shell \
      https://github.com/aunetx/blur-my-shell.git \
      "${WORKDIR}/blur-my-shell" \
      "${GNOME_MAJOR}"
  else
    warn "GNOME Shell version could not be detected. Skipping Blur my Shell."
    WITH_BLUR="false"
  fi
fi

info "Installing WhiteSur GTK and Shell theme"
(
  cd "${WORKDIR}/WhiteSur-gtk-theme"
  ./install.sh -l --shell -c "${MODE}" -t blue
)

info "Installing WhiteSur icon theme"
(
  cd "${WORKDIR}/WhiteSur-icon-theme"
  ./install.sh -a
)

info "Installing McMojave cursor theme"
(
  cd "${WORKDIR}/McMojave-cursors"
  ./install.sh
)

if has_extension_uuid "dash-to-dock@micxgx.gmail.com"; then
  info "Applying WhiteSur dock tweaks"
  (
    cd "${WORKDIR}/WhiteSur-gtk-theme"
    ./tweaks.sh -d
  )
else
  warn "Standalone Dash to Dock is not installed. Skipping WhiteSur dock tweaks and keeping Ubuntu Dock settings."
fi

if [[ "${WITH_FLATPAK_FIX}" == "true" ]] && has_command flatpak; then
  info "Applying Flatpak theme integration"
  (
    cd "${WORKDIR}/WhiteSur-gtk-theme"
    ./tweaks.sh -F || warn "WhiteSur Flatpak tweak failed."
  )
fi

mkdir -p "${WALLPAPER_DIR}"
info "Selecting an official macOS-style wallpaper"
WALLPAPER_SRC="$(pick_wallpaper "${WORKDIR}/WhiteSur-wallpapers" "${WALLPAPER_SERIES}" "${MODE}" || true)"
[[ -n "${WALLPAPER_SRC}" ]] || die "Could not find a wallpaper in WhiteSur-wallpapers."
WALLPAPER_EXT="${WALLPAPER_SRC##*.}"
WALLPAPER_DST="${WALLPAPER_BASENAME}.${WALLPAPER_EXT}"
cp -f "${WALLPAPER_SRC}" "${WALLPAPER_DST}"

if [[ "${WITH_GDM}" == "true" ]]; then
  info "Styling the login screen"
  (
    cd "${WORKDIR}/WhiteSur-gtk-theme"
    sudo ./tweaks.sh -g -c "${MODE}" -t blue -b "${WALLPAPER_DST}" || \
      warn "GDM styling failed."
  )
fi

if [[ "${WITH_BLUR}" == "true" ]]; then
  info "Installing Blur my Shell"
  (
    cd "${WORKDIR}/blur-my-shell"
    make install
  )
fi

enable_extensions "${WITH_BLUR}"
apply_appearance_settings "${MODE}" "${WALLPAPER_DST}" "${SHOW_APPS_BUTTON}"

info "Done"
echo
echo "Project           : ${PROJECT_ROOT}"
echo "Applied theme     : $(theme_name_for_mode "${MODE}")"
echo "Applied icons     : WhiteSur"
echo "Applied cursor    : McMojave-cursors"
echo "Wallpaper series  : ${WALLPAPER_SERIES}"
echo "GDM styled        : ${WITH_GDM}"
echo "Blur my Shell     : ${WITH_BLUR}"
echo
echo "If the shell theme or blur effect does not fully apply, log out and log back in once."
