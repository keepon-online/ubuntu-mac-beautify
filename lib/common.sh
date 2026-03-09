#!/usr/bin/env bash

info() {
  printf '[INFO] %s\n' "$*"
}

warn() {
  printf '[WARN] %s\n' "$*" >&2
}

die() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

check_not_root() {
  if [[ "${EUID}" -eq 0 ]]; then
    die "Run this script as your regular user, not with sudo."
  fi
}

check_os() {
  if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    if [[ "${ID:-}" != "ubuntu" || "${VERSION_ID:-}" != "24.04" ]]; then
      warn "This project targets Ubuntu 24.04. Detected: ${PRETTY_NAME:-unknown}. Continuing anyway."
    fi
  fi
}

has_command() {
  command -v "$1" >/dev/null 2>&1
}

has_schema() {
  local schema="$1"
  gsettings list-schemas | grep -qx "${schema}"
}

has_extension_uuid() {
  local uuid="$1"
  [[ -d "${HOME}/.local/share/gnome-shell/extensions/${uuid}" || -d "/usr/share/gnome-shell/extensions/${uuid}" ]]
}

require_command() {
  local command_name="$1"
  has_command "${command_name}" || die "${command_name} is required."
}

set_gsetting() {
  local schema="$1"
  local key="$2"
  shift 2

  if ! gsettings set "${schema}" "${key}" "$@" >/dev/null 2>&1; then
    warn "Could not set ${schema} ${key}. Log into a GNOME session and rerun if needed."
  fi
}

get_gnome_major() {
  if ! has_command gnome-shell; then
    return 1
  fi

  gnome-shell --version | awk '{print $3}' | cut -d. -f1
}

clone_blur_my_shell() {
  local repo_url="$1"
  local dest_dir="$2"
  local gnome_major="$3"
  local ref="master"

  case "${gnome_major}" in
    46)
      ref="master"
      ;;
    45)
      ref="v58"
      ;;
    43|44)
      ref="v47"
      ;;
    40|41|42)
      ref="v42"
      ;;
    *)
      warn "GNOME Shell ${gnome_major} is not mapped to a known Blur my Shell compatibility tag. Trying master."
      ;;
  esac

  git clone --depth=1 --branch "${ref}" "${repo_url}" "${dest_dir}"
}

pick_wallpaper() {
  local repo_dir="$1"
  local series="$2"
  local mode="$3"
  local mode_pattern="dark|night"
  local picked=""

  if [[ "${mode}" == "light" ]]; then
    mode_pattern="light|day"
  fi

  picked="$(find "${repo_dir}" -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) | \
    grep -Ei "/${series}[^/]*/|/${series}[._ -]" | \
    grep -Ei "${mode_pattern}" | head -n1 || true)"

  if [[ -z "${picked}" ]]; then
    picked="$(find "${repo_dir}" -type f \
      \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) | \
      grep -Ei "/${series}[^/]*/|/${series}[._ -]" | head -n1 || true)"
  fi

  if [[ -z "${picked}" ]]; then
    picked="$(find "${repo_dir}" -type f \
      \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) | head -n1 || true)"
  fi

  [[ -n "${picked}" ]] || return 1
  printf '%s\n' "${picked}"
}

find_existing_wallpaper() {
  local wallpaper_dir="$1"
  local series="$2"
  local mode="$3"
  local picked=""

  if [[ -d "${wallpaper_dir}" ]]; then
    picked="$(find "${wallpaper_dir}" -maxdepth 1 -type f | \
      grep -Ei "/macos-${series}-${mode}\." | head -n1 || true)"

    if [[ -z "${picked}" ]]; then
      picked="$(find "${wallpaper_dir}" -maxdepth 1 -type f | \
        grep -Ei "/macos-${series}-" | head -n1 || true)"
    fi

    if [[ -z "${picked}" ]]; then
      picked="$(find "${wallpaper_dir}" -maxdepth 1 -type f | \
        grep -Ei "/macos-.*-${mode}\." | head -n1 || true)"
    fi
  fi

  [[ -n "${picked}" ]] || return 1
  printf '%s\n' "${picked}"
}

theme_name_for_mode() {
  if [[ "$1" == "light" ]]; then
    printf 'WhiteSur-Light-blue\n'
  else
    printf 'WhiteSur-Dark-blue\n'
  fi
}

color_scheme_for_mode() {
  if [[ "$1" == "light" ]]; then
    printf 'prefer-light\n'
  else
    printf 'prefer-dark\n'
  fi
}

enable_extensions() {
  local enable_blur="$1"

  if ! has_command gnome-extensions; then
    return 0
  fi

  info "Enabling GNOME extensions"
  gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com >/dev/null 2>&1 || \
    warn "Could not enable User Themes automatically."

  if [[ "${enable_blur}" == "true" ]] && has_extension_uuid "blur-my-shell@aunetx"; then
    gnome-extensions enable blur-my-shell@aunetx >/dev/null 2>&1 || \
      warn "Could not enable Blur my Shell automatically."
  fi
}

disable_extensions() {
  if ! has_command gnome-extensions; then
    return 0
  fi

  if has_extension_uuid "blur-my-shell@aunetx"; then
    gnome-extensions disable blur-my-shell@aunetx >/dev/null 2>&1 || \
      warn "Could not disable Blur my Shell automatically."
  fi
}

reset_gsetting() {
  local schema="$1"
  local key="$2"

  if ! gsettings reset "${schema}" "${key}" >/dev/null 2>&1; then
    warn "Could not reset ${schema} ${key}."
  fi
}

reset_appearance_settings() {
  info "Resetting GNOME appearance settings"

  reset_gsetting org.gnome.desktop.interface color-scheme
  reset_gsetting org.gnome.desktop.interface gtk-theme
  reset_gsetting org.gnome.desktop.interface icon-theme
  reset_gsetting org.gnome.desktop.interface cursor-theme
  reset_gsetting org.gnome.desktop.interface font-name
  reset_gsetting org.gnome.desktop.interface document-font-name
  reset_gsetting org.gnome.desktop.interface monospace-font-name
  reset_gsetting org.gnome.desktop.interface enable-hot-corners
  reset_gsetting org.gnome.desktop.wm.preferences button-layout
  reset_gsetting org.gnome.desktop.background picture-uri
  reset_gsetting org.gnome.desktop.background picture-uri-dark
  reset_gsetting org.gnome.desktop.background picture-options
  reset_gsetting org.gnome.desktop.screensaver picture-uri
  reset_gsetting org.gnome.desktop.screensaver picture-options

  if has_schema org.gnome.shell.extensions.user-theme; then
    reset_gsetting org.gnome.shell.extensions.user-theme name
  fi

  if has_schema org.gnome.shell.extensions.dash-to-dock; then
    reset_gsetting org.gnome.shell.extensions.dash-to-dock dock-position
    reset_gsetting org.gnome.shell.extensions.dash-to-dock extend-height
    reset_gsetting org.gnome.shell.extensions.dash-to-dock dock-fixed
    reset_gsetting org.gnome.shell.extensions.dash-to-dock autohide
    reset_gsetting org.gnome.shell.extensions.dash-to-dock intellihide
    reset_gsetting org.gnome.shell.extensions.dash-to-dock intellihide-mode
    reset_gsetting org.gnome.shell.extensions.dash-to-dock always-center-icons
    reset_gsetting org.gnome.shell.extensions.dash-to-dock icon-size-fixed
    reset_gsetting org.gnome.shell.extensions.dash-to-dock dash-max-icon-size
    reset_gsetting org.gnome.shell.extensions.dash-to-dock transparency-mode
    reset_gsetting org.gnome.shell.extensions.dash-to-dock running-indicator-style
    reset_gsetting org.gnome.shell.extensions.dash-to-dock click-action
    reset_gsetting org.gnome.shell.extensions.dash-to-dock show-show-apps-button
    reset_gsetting org.gnome.shell.extensions.dash-to-dock show-mounts
    reset_gsetting org.gnome.shell.extensions.dash-to-dock show-trash
  fi
}

remove_path_if_exists() {
  local path="$1"

  if [[ -e "${path}" ]]; then
    rm -rf "${path}"
    info "Removed ${path}"
  fi
}

apply_appearance_settings() {
  local mode="$1"
  local wallpaper_path="${2:-}"
  local show_apps_button="${3:-false}"
  local gtk_theme
  local color_scheme

  gtk_theme="$(theme_name_for_mode "${mode}")"
  color_scheme="$(color_scheme_for_mode "${mode}")"

  info "Applying GNOME appearance settings"
  set_gsetting org.gnome.desktop.interface color-scheme "'${color_scheme}'"
  set_gsetting org.gnome.desktop.interface gtk-theme "'${gtk_theme}'"
  set_gsetting org.gnome.desktop.interface icon-theme "'WhiteSur'"
  set_gsetting org.gnome.desktop.interface cursor-theme "'McMojave-cursors'"
  set_gsetting org.gnome.desktop.interface font-name "'Inter 11'"
  set_gsetting org.gnome.desktop.interface document-font-name "'Inter 11'"
  set_gsetting org.gnome.desktop.interface monospace-font-name "'JetBrains Mono 11'"
  set_gsetting org.gnome.desktop.interface enable-hot-corners "false"
  set_gsetting org.gnome.desktop.wm.preferences button-layout "'close,minimize,maximize:'"

  if [[ -n "${wallpaper_path}" && -f "${wallpaper_path}" ]]; then
    set_gsetting org.gnome.desktop.background picture-uri "'file://${wallpaper_path}'"
    set_gsetting org.gnome.desktop.background picture-uri-dark "'file://${wallpaper_path}'"
    set_gsetting org.gnome.desktop.background picture-options "'zoom'"
    set_gsetting org.gnome.desktop.screensaver picture-uri "'file://${wallpaper_path}'"
    set_gsetting org.gnome.desktop.screensaver picture-options "'zoom'"
  else
    warn "Wallpaper not found. Skipping wallpaper update."
  fi

  if has_schema org.gnome.shell.extensions.user-theme; then
    set_gsetting org.gnome.shell.extensions.user-theme name "'${gtk_theme}'"
  fi

  if has_schema org.gnome.shell.extensions.dash-to-dock; then
    set_gsetting org.gnome.shell.extensions.dash-to-dock dock-position "'BOTTOM'"
    set_gsetting org.gnome.shell.extensions.dash-to-dock extend-height "false"
    set_gsetting org.gnome.shell.extensions.dash-to-dock dock-fixed "false"
    set_gsetting org.gnome.shell.extensions.dash-to-dock autohide "true"
    set_gsetting org.gnome.shell.extensions.dash-to-dock intellihide "true"
    set_gsetting org.gnome.shell.extensions.dash-to-dock intellihide-mode "'ALL_WINDOWS'"
    set_gsetting org.gnome.shell.extensions.dash-to-dock always-center-icons "true"
    set_gsetting org.gnome.shell.extensions.dash-to-dock icon-size-fixed "true"
    set_gsetting org.gnome.shell.extensions.dash-to-dock dash-max-icon-size "52"
    set_gsetting org.gnome.shell.extensions.dash-to-dock transparency-mode "'FIXED'"
    set_gsetting org.gnome.shell.extensions.dash-to-dock running-indicator-style "'DOTS'"
    set_gsetting org.gnome.shell.extensions.dash-to-dock click-action "'minimize-or-previews'"
    set_gsetting org.gnome.shell.extensions.dash-to-dock show-show-apps-button "${show_apps_button}"
    set_gsetting org.gnome.shell.extensions.dash-to-dock show-mounts "false"
    set_gsetting org.gnome.shell.extensions.dash-to-dock show-trash "false"
  fi
}
