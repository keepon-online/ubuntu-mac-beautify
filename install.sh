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
DESKTOP="auto"
WITH_KDE_PANEL="true"
WITH_KDE_LAUNCHERS="true"
KDE_ROUND="auto"
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
    --skip-kde-panel)
      WITH_KDE_PANEL="false"
      ;;
    --skip-kde-launchers)
      WITH_KDE_LAUNCHERS="false"
      ;;
    --kde-round)
      KDE_ROUND="true"
      ;;
    --kde-no-round)
      KDE_ROUND="false"
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
  --desktop=DESKTOP      auto (default), gnome, or kde
  --dark                 Use the dark WhiteSur theme (default)
  --light                Use the light WhiteSur theme
  --skip-gdm             Do not style the login screen (GNOME only)
  --skip-blur            Do not install Blur my Shell (GNOME only)
  --skip-flatpak-fix     Skip Flatpak theme integration
  --show-apps-button     Show the app grid button in the dock (GNOME only)
  --skip-kde-panel       Do not restyle the Plasma panel (KDE only)
  --skip-kde-launchers   Do not configure default pinned apps on the Plasma panel (KDE only)
  --kde-round            Prefer rounded KDE window decorations (default for Ventura / Sonoma / Sequoia)
  --kde-no-round         Prefer the default KDE window decoration variant
  --wallpaper=SERIES     Wallpaper series hint, e.g. ventura or sonoma
  --keep-workdir         Keep the temporary repo checkout for inspection
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
require_command sudo
warn_if_session_mismatch "${DESKTOP}"

if [[ "${DESKTOP}" == "kde" ]] && ! has_kde_session_installed; then
  die "KDE Plasma session is not installed. Install it first, for example: sudo apt install kde-standard sddm"
fi

COMMON_PACKAGES=(
  curl
  fonts-inter
  fonts-jetbrains-mono
  fonts-noto-cjk
  gettext
  git
  imagemagick
  inkscape
  libglib2.0-dev-bin
  libxml2-utils
  make
  optipng
  sassc
  wget
)

GNOME_PACKAGES=(
  gnome-shell-extension-manager
  gnome-shell-extensions
  gnome-tweaks
  gtk2-engines-murrine
  gtk2-engines-pixbuf
)

KDE_PACKAGES=(
  breeze-gtk-theme
  gtk2-engines-murrine
  gtk2-engines-pixbuf
  kde-config-gtk-style
  qt5-style-kvantum
  qt5-style-kvantum-themes
)

PACKAGES=("${COMMON_PACKAGES[@]}")
if [[ "${DESKTOP}" == "gnome" ]]; then
  PACKAGES+=("${GNOME_PACKAGES[@]}")
else
  PACKAGES+=("${KDE_PACKAGES[@]}")
fi

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
KDE_THEME_REPO_URL="$(get_kde_theme_repo_url "${WALLPAPER_SERIES}")"

if [[ "${DESKTOP}" == "kde" ]]; then
  if [[ "${WITH_GDM}" == "false" ]]; then
    warn "--skip-gdm is a GNOME-only option and will be ignored for KDE."
  fi
  if [[ "${WITH_BLUR}" == "false" ]]; then
    warn "--skip-blur is a GNOME-only option and will be ignored for KDE."
  fi
  if [[ "${SHOW_APPS_BUTTON}" == "true" ]]; then
    warn "--show-apps-button is a GNOME-only option and will be ignored for KDE."
  fi
  if ! has_command plasmashell; then
    warn "Plasma shell was not detected. KDE theme files will still be installed, but automatic application only works reliably inside a KDE Plasma session."
  fi
else
  if [[ "${WITH_KDE_PANEL}" == "false" ]]; then
    warn "--skip-kde-panel is a KDE-only option and will be ignored for GNOME."
  fi
  if [[ "${WITH_KDE_LAUNCHERS}" == "false" ]]; then
    warn "--skip-kde-launchers is a KDE-only option and will be ignored for GNOME."
  fi
fi

info "Refreshing package index"
sudo apt update

info "Installing required packages"
sudo apt install -y "${PACKAGES[@]}"

info "Cloning official theme repositories"
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git "${WORKDIR}/WhiteSur-gtk-theme"
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git "${WORKDIR}/WhiteSur-icon-theme"
git clone --depth=1 https://github.com/vinceliuice/McMojave-cursors.git "${WORKDIR}/McMojave-cursors"
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-wallpapers.git "${WORKDIR}/WhiteSur-wallpapers"

if [[ "${DESKTOP}" == "kde" ]]; then
  git clone --depth=1 "${KDE_THEME_REPO_URL}" "${WORKDIR}/$(kde_theme_label "${WALLPAPER_SERIES}")"
fi

if [[ "${DESKTOP}" == "gnome" && "${WITH_BLUR}" == "true" ]]; then
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

if [[ "${DESKTOP}" == "gnome" ]]; then
  info "Installing WhiteSur GTK and Shell theme"
  (
    cd "${WORKDIR}/WhiteSur-gtk-theme"
    ./install.sh -l --shell -c "${MODE}" -t blue
  )
else
  info "Installing WhiteSur GTK theme for GTK apps"
  (
    cd "${WORKDIR}/WhiteSur-gtk-theme"
    ./install.sh -l -c "${MODE}" -t blue
  )

  info "Installing KDE global theme"
  (
    cd "${WORKDIR}/$(kde_theme_label "${WALLPAPER_SERIES}")"
    KDE_THEME_ARGS="$(kde_theme_install_args "${WALLPAPER_SERIES}" "${KDE_ROUND}")"
    if [[ -n "${KDE_THEME_ARGS}" ]]; then
      ./install.sh "${KDE_THEME_ARGS}"
    else
      ./install.sh
    fi
  )
fi

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

if [[ "${DESKTOP}" == "gnome" ]]; then
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
fi

mkdir -p "${WALLPAPER_DIR}"
info "Selecting an official macOS-style wallpaper"
WALLPAPER_SRC="$(pick_wallpaper "${WORKDIR}/WhiteSur-wallpapers" "${WALLPAPER_SERIES}" "${MODE}" || true)"
[[ -n "${WALLPAPER_SRC}" ]] || die "Could not find a wallpaper in WhiteSur-wallpapers."
WALLPAPER_EXT="${WALLPAPER_SRC##*.}"
WALLPAPER_DST="${WALLPAPER_BASENAME}.${WALLPAPER_EXT}"
cp -f "${WALLPAPER_SRC}" "${WALLPAPER_DST}"

if [[ "${DESKTOP}" == "gnome" && "${WITH_GDM}" == "true" ]]; then
  info "Styling the login screen"
  (
    cd "${WORKDIR}/WhiteSur-gtk-theme"
    sudo ./tweaks.sh -g -c "${MODE}" -t blue -b "${WALLPAPER_DST}" || \
      warn "GDM styling failed."
  )

  if run_project_gdm_beautify; then
    PROJECT_GDM_OVERRIDE="attempted"
  else
    PROJECT_GDM_OVERRIDE="failed"
  fi
fi

if [[ "${DESKTOP}" == "gnome" && "${WITH_BLUR}" == "true" ]]; then
  info "Installing Blur my Shell"
  (
    cd "${WORKDIR}/blur-my-shell"
    make install
  )
fi

if [[ "${DESKTOP}" == "gnome" ]]; then
  enable_extensions "${WITH_BLUR}"
  apply_appearance_settings "${MODE}" "${WALLPAPER_DST}" "${SHOW_APPS_BUTTON}"
else
  apply_kde_appearance_settings "${MODE}" "${WALLPAPER_DST}" "${WALLPAPER_SERIES}" "${WITH_KDE_PANEL}" "${WITH_KDE_LAUNCHERS}" "${KDE_ROUND}"
fi

info "Done"
echo
echo "Project           : ${PROJECT_ROOT}"
echo "Desktop target    : ${DESKTOP}"
if [[ "${DESKTOP}" == "gnome" ]]; then
  echo "Applied theme     : $(theme_name_for_mode "${MODE}")"
  echo "Blur my Shell     : ${WITH_BLUR}"
  echo "GDM requested     : ${WITH_GDM}"
  echo "GDM custom theme  : ${PROJECT_GDM_OVERRIDE}"
else
  echo "Applied theme     : $(kde_theme_label "${WALLPAPER_SERIES}")"
  echo "GTK theme         : $(theme_name_for_mode "${MODE}")"
  echo "GTK 3/4 sync      : enabled"
  echo "Window buttons    : left (close/minimize/maximize)"
  echo "Rounded windows   : ${KDE_ROUND}"
  echo "Plasma panel      : ${WITH_KDE_PANEL}"
  echo "Pinned apps       : ${WITH_KDE_LAUNCHERS}"
  echo "Kvantum           : attempted"
fi
echo "Applied icons     : WhiteSur"
echo "Applied cursor    : McMojave-cursors"
echo "Wallpaper series  : ${WALLPAPER_SERIES}"
echo
if [[ "${DESKTOP}" == "gnome" ]]; then
  echo "If the shell theme or blur effect does not fully apply, log out and log back in once."
  if [[ "${WITH_GDM}" == "true" ]]; then
    echo "If you want to roll back the custom GDM theme, run: sudo bash ./scripts/rollback-custom-gdm-prussiangreen.sh"
  fi
else
  echo "If the KDE global theme does not fully apply, log into a Plasma session and verify Global Theme, Icons, and Kvantum once in System Settings."
fi
