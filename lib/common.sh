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
    # shellcheck disable=SC1091
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

normalize_desktop() {
  local value="${1:-auto}"

  case "${value,,}" in
    auto|gnome|kde)
      printf '%s\n' "${value,,}"
      ;;
    *)
      return 1
      ;;
  esac
}

detect_current_desktop() {
  local raw="${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-}}"

  if [[ "${raw^^}" == *GNOME* ]]; then
    printf 'gnome\n'
    return 0
  fi

  if [[ "${raw^^}" == *KDE* || "${raw^^}" == *PLASMA* ]]; then
    printf 'kde\n'
    return 0
  fi

  if [[ "${KDE_FULL_SESSION:-}" == "true" || -n "${KDE_SESSION_VERSION:-}" ]]; then
    printf 'kde\n'
    return 0
  fi

  return 1
}

has_kde_session_installed() {
  local session_file=""

  for session_file in \
    /usr/share/xsessions/plasma.desktop \
    /usr/share/xsessions/plasmax11.desktop \
    /usr/share/wayland-sessions/plasma.desktop \
    /usr/share/wayland-sessions/plasmawayland.desktop; do
    if [[ -f "${session_file}" ]]; then
      return 0
    fi
  done

  has_command startplasma-x11 || has_command startplasma-wayland
}

resolve_desktop() {
  local requested="${1:-auto}"
  local detected=""

  if [[ "${requested}" != "auto" ]]; then
    printf '%s\n' "${requested}"
    return 0
  fi

  detected="$(detect_current_desktop || true)"
  if [[ -n "${detected}" ]]; then
    printf '%s\n' "${detected}"
    return 0
  fi

  if has_command gnome-shell; then
    printf 'gnome\n'
    return 0
  fi

  if has_command plasmashell || has_command plasma-apply-lookandfeel || has_command lookandfeeltool; then
    printf 'kde\n'
    return 0
  fi

  printf 'gnome\n'
}

warn_if_session_mismatch() {
  local target_desktop="$1"
  local current_desktop=""

  current_desktop="$(detect_current_desktop || true)"
  if [[ -n "${current_desktop}" && "${current_desktop}" != "${target_desktop}" ]]; then
    warn "Requested ${target_desktop} styling while current session looks like ${current_desktop}. Settings may not fully apply until you log into a ${target_desktop^^} session."
  fi
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

get_kde_theme_repo_url() {
  local series="$1"

  case "${series,,}" in
    sonoma)
      printf 'https://github.com/vinceliuice/MacSonoma-kde.git\n'
      ;;
    ventura)
      printf 'https://github.com/vinceliuice/MacVentura-kde.git\n'
      ;;
    sequoia)
      printf 'https://github.com/vinceliuice/MacSequoia-kde.git\n'
      ;;
    *)
      printf 'https://github.com/vinceliuice/WhiteSur-kde.git\n'
      ;;
  esac
}

kde_theme_match_regex() {
  local series="$1"

  case "${series,,}" in
    sonoma)
      printf 'macsonoma|sonoma\n'
      ;;
    ventura)
      printf 'macventura|ventura\n'
      ;;
    sequoia)
      printf 'macsequoia|sequoia\n'
      ;;
    *)
      printf 'whitesur\n'
      ;;
  esac
}

kde_theme_label() {
  local series="$1"

  case "${series,,}" in
    sonoma)
      printf 'MacSonoma-kde\n'
      ;;
    ventura)
      printf 'MacVentura-kde\n'
      ;;
    sequoia)
      printf 'MacSequoia-kde\n'
      ;;
    *)
      printf 'WhiteSur-kde\n'
      ;;
  esac
}

default_kde_round_style() {
  local series="$1"

  case "${series,,}" in
    sonoma|ventura|sequoia)
      printf 'true\n'
      ;;
    *)
      printf 'false\n'
      ;;
  esac
}

kde_theme_install_args() {
  local series="$1"
  local round_style="${2:-$(default_kde_round_style "${series}")}"

  case "${series,,}" in
    sonoma|ventura|sequoia)
      if [[ "${round_style}" == "true" ]]; then
        printf '%s\n' "--round"
      fi
      ;;
    *)
      :
      ;;
  esac
}

find_kde_lookandfeel_id() {
  local series="$1"
  local regex

  regex="$(kde_theme_match_regex "${series}")"
  find_matching_kde_dir "${regex}" \
    "${HOME}/.local/share/plasma/look-and-feel" \
    "/usr/share/plasma/look-and-feel"
}

find_kde_kvantum_theme_name() {
  local series="$1"
  local regex

  regex="$(kde_theme_match_regex "${series}")"
  find_matching_kde_dir "${regex}" \
    "${HOME}/.config/Kvantum" \
    "${HOME}/.local/share/Kvantum" \
    "/usr/share/Kvantum"
}

find_kde_color_scheme_name() {
  local series="$1"
  local regex

  regex="$(kde_theme_match_regex "${series}")"
  find_matching_kde_file_basename "${regex}" '.colors' \
    "${HOME}/.local/share/color-schemes" \
    "/usr/share/color-schemes"
}

find_kde_plasma_theme_name() {
  local series="$1"
  local regex

  regex="$(kde_theme_match_regex "${series}")"
  find_matching_kde_dir "${regex}" \
    "${HOME}/.local/share/plasma/desktoptheme" \
    "/usr/share/plasma/desktoptheme"
}

find_kde_aurorae_theme_name() {
  local series="$1"
  local round_style="${2:-$(default_kde_round_style "${series}")}"
  local regex
  local dir=""
  local candidate=""
  local fallback=""

  regex="$(kde_theme_match_regex "${series}")"

  for dir in "${HOME}/.local/share/aurorae/themes" "/usr/share/aurorae/themes"; do
    [[ -d "${dir}" ]] || continue
    while IFS= read -r candidate; do
      [[ -n "${candidate}" ]] || continue
      if [[ "${round_style}" == "true" && "${candidate,,}" == *round* ]]; then
        printf '%s\n' "${candidate}"
        return 0
      fi
      if [[ -z "${fallback}" ]]; then
        fallback="${candidate}"
      fi
    done < <(find "${dir}" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | grep -Ei "${regex}" || true)
  done

  [[ -n "${fallback}" ]] || return 1
  printf '%s\n' "${fallback}"
}

kwriteconfig_command() {
  if has_command kwriteconfig6; then
    printf 'kwriteconfig6\n'
    return 0
  fi

  if has_command kwriteconfig5; then
    printf 'kwriteconfig5\n'
    return 0
  fi

  return 1
}

find_matching_kde_dir() {
  local regex="$1"
  shift
  local dir=""

  for dir in "$@"; do
    [[ -d "${dir}" ]] || continue
    find "${dir}" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | \
      grep -Ei "${regex}" | head -n1 && return 0
  done

  return 1
}

find_matching_kde_file_basename() {
  local regex="$1"
  local suffix="$2"
  shift 2
  local dir=""

  for dir in "$@"; do
    [[ -d "${dir}" ]] || continue
    find "${dir}" -mindepth 1 -maxdepth 1 -type f -name "*${suffix}" -printf '%f\n' | \
      sed "s/${suffix//./\\.}$//" | \
      grep -Ei "${regex}" | head -n1 && return 0
  done

  return 1
}

set_ini_value() {
  local file_path="$1"
  local section_name="$2"
  local key_name="$3"
  local key_value="$4"
  local tmp_file=""

  mkdir -p "$(dirname "${file_path}")"
  [[ -f "${file_path}" ]] || : > "${file_path}"
  tmp_file="$(mktemp)"

  awk \
    -v section="[${section_name}]" \
    -v key="${key_name}" \
    -v value="${key_name}=${key_value}" '
      BEGIN {
        in_section = 0
        section_found = 0
        key_written = 0
      }
      /^\[.*\]$/ {
        if (in_section && !key_written) {
          print value
          key_written = 1
        }
        in_section = ($0 == section)
        if (in_section) {
          section_found = 1
        }
        print
        next
      }
      {
        if (in_section && $0 ~ "^[[:space:]]*" key "[[:space:]]*=") {
          if (!key_written) {
            print value
            key_written = 1
          }
          next
        }
        print
      }
      END {
        if (!section_found) {
          print section
          print value
        } else if (in_section && !key_written) {
          print value
        }
      }
    ' "${file_path}" > "${tmp_file}"

  mv "${tmp_file}" "${file_path}"
}

set_plain_key_value() {
  local file_path="$1"
  local key_name="$2"
  local key_value="$3"
  local tmp_file=""

  mkdir -p "$(dirname "${file_path}")"
  [[ -f "${file_path}" ]] || : > "${file_path}"
  tmp_file="$(mktemp)"

  awk \
    -v key="${key_name}" \
    -v value="${key_name}=${key_value}" '
      BEGIN {
        key_written = 0
      }
      {
        if ($0 ~ "^[[:space:]]*" key "[[:space:]]*=") {
          if (!key_written) {
            print value
            key_written = 1
          }
          next
        }
        print
      }
      END {
        if (!key_written) {
          print value
        }
      }
    ' "${file_path}" > "${tmp_file}"

  mv "${tmp_file}" "${file_path}"
}

set_kde_config_value() {
  local file_name="$1"
  local group_name="$2"
  local key_name="$3"
  local key_value="$4"
  local kwriteconfig_bin=""

  kwriteconfig_bin="$(kwriteconfig_command || true)"
  [[ -n "${kwriteconfig_bin}" ]] || return 1

  "${kwriteconfig_bin}" --file "${file_name}" --group "${group_name}" --key "${key_name}" "${key_value}" >/dev/null 2>&1
}

qdbus_command() {
  if has_command qdbus6; then
    printf 'qdbus6\n'
    return 0
  fi

  if has_command qdbus; then
    printf 'qdbus\n'
    return 0
  fi

  return 1
}

run_plasma_script() {
  local script_body="$1"
  local qdbus_bin=""

  qdbus_bin="$(qdbus_command || true)"
  [[ -n "${qdbus_bin}" ]] || return 1

  "${qdbus_bin}" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "${script_body}" >/dev/null 2>&1
}

escape_js_string() {
  local value="$1"

  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  printf '%s\n' "${value}"
}

desktop_entry_search_paths() {
  printf '%s\n' \
    "${HOME}/.local/share/applications" \
    "${HOME}/.local/share/flatpak/exports/share/applications" \
    "/var/lib/flatpak/exports/share/applications" \
    "/usr/local/share/applications" \
    "/usr/share/applications"
}

desktop_entry_exists() {
  local desktop_id="$1"
  local dir=""

  while IFS= read -r dir; do
    [[ -n "${dir}" ]] || continue
    if [[ -f "${dir}/${desktop_id}" ]]; then
      return 0
    fi
  done < <(desktop_entry_search_paths)

  return 1
}

find_first_desktop_entry() {
  local candidate=""

  for candidate in "$@"; do
    if desktop_entry_exists "${candidate}"; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done

  return 1
}

join_by_comma() {
  local joined=""
  local item=""

  for item in "$@"; do
    [[ -n "${item}" ]] || continue
    if [[ -n "${joined}" ]]; then
      joined+=","
    fi
    joined+="${item}"
  done

  printf '%s\n' "${joined}"
}

resolve_kde_default_launchers() {
  local browser=""
  local settings=""
  local spectacle=""
  local discover=""
  local -a launchers=()

  if desktop_entry_exists "org.kde.dolphin.desktop"; then
    launchers+=("applications:org.kde.dolphin.desktop")
  fi

  browser="$(find_first_desktop_entry \
    "firefox_firefox.desktop" \
    "firefox.desktop" \
    "org.mozilla.firefox.desktop" \
    "google-chrome.desktop" \
    "chromium_chromium.desktop" \
    "chromium.desktop" || true)"
  if [[ -n "${browser}" ]]; then
    launchers+=("applications:${browser}")
  fi

  if desktop_entry_exists "org.kde.konsole.desktop"; then
    launchers+=("applications:org.kde.konsole.desktop")
  fi

  spectacle="$(find_first_desktop_entry \
    "org.kde.spectacle.desktop" \
    "spectacle.desktop" || true)"
  if [[ -n "${spectacle}" ]]; then
    launchers+=("applications:${spectacle}")
  fi

  settings="$(find_first_desktop_entry \
    "systemsettings.desktop" \
    "org.kde.systemsettings.desktop" || true)"
  if [[ -n "${settings}" ]]; then
    launchers+=("applications:${settings}")
  fi

  discover="$(find_first_desktop_entry \
    "org.kde.discover.desktop" \
    "plasma-discover.desktop" || true)"
  if [[ -n "${discover}" ]]; then
    launchers+=("applications:${discover}")
  fi

  [[ "${#launchers[@]}" -gt 0 ]] || return 1
  join_by_comma "${launchers[@]}"
}

apply_kde_panel_layout() {
  local script_body=""

  read -r -d '' script_body <<'EOF' || true
var panel = null;
for (var i = 0; i < panelIds.length; ++i) {
  var candidate = panelById(panelIds[i]);
  if (panel === null) {
    panel = candidate;
  }
  if (candidate.location === "bottom") {
    panel = candidate;
    break;
  }
}

if (panel !== null) {
  try { panel.location = "bottom"; } catch (e) {}
  try { panel.alignment = "center"; } catch (e) {}
  try { panel.lengthMode = "fit"; } catch (e) {}
  try { panel.height = 44; } catch (e) {}
  try { panel.floating = true; } catch (e) {}
  try { panel.hiding = "none"; } catch (e) {}
  try { panel.offset = 0; } catch (e) {}
  try { panel.minimumLength = 720; } catch (e) {}
  try { panel.maximumLength = 1440; } catch (e) {}
}
EOF

  run_plasma_script "${script_body}"
}

apply_kde_panel_launchers() {
  local launchers_csv="$1"
  local escaped_launchers=""
  local script_body=""

  escaped_launchers="$(escape_js_string "${launchers_csv}")"

  read -r -d '' script_body <<EOF || true
var panel = null;
var launchers = "${escaped_launchers}";
for (var i = 0; i < panelIds.length; ++i) {
  var candidate = panelById(panelIds[i]);
  if (panel === null) {
    panel = candidate;
  }
  if (candidate.location === "bottom") {
    panel = candidate;
    break;
  }
}

if (panel !== null) {
  var widgets = [];
  try { widgets = panel.widgets(); } catch (e) {}
  for (var j = 0; j < widgets.length; ++j) {
    var widget = widgets[j];
    try {
      if (widget.type === "org.kde.plasma.icontasks" || widget.type === "org.kde.plasma.taskmanager") {
        widget.currentConfigGroup = ["General"];
        widget.writeConfig("launchers", launchers);
      }
    } catch (e) {}
  }
}
EOF

  run_plasma_script "${script_body}"
}

reset_kde_panel_layout() {
  local script_body=""

  read -r -d '' script_body <<'EOF' || true
var panel = null;
for (var i = 0; i < panelIds.length; ++i) {
  var candidate = panelById(panelIds[i]);
  if (panel === null) {
    panel = candidate;
  }
  if (candidate.location === "bottom") {
    panel = candidate;
    break;
  }
}

if (panel !== null) {
  try { panel.location = "bottom"; } catch (e) {}
  try { panel.alignment = "left"; } catch (e) {}
  try { panel.lengthMode = "fill"; } catch (e) {}
  try { panel.height = 40; } catch (e) {}
  try { panel.floating = false; } catch (e) {}
  try { panel.hiding = "none"; } catch (e) {}
  try { panel.offset = 0; } catch (e) {}
}
EOF

  run_plasma_script "${script_body}"
}

activate_kde_kvantum_theme() {
  local series="$1"
  local theme_name=""

  theme_name="$(find_kde_kvantum_theme_name "${series}" || true)"
  if [[ -z "${theme_name}" ]]; then
    return 1
  fi

  mkdir -p "${HOME}/.config/Kvantum"
  {
    printf '[General]\n'
    printf 'theme=%s\n' "${theme_name}"
  } > "${HOME}/.config/Kvantum/kvantum.kvconfig"
}

apply_kde_gtk_theme_settings() {
  local mode="$1"
  local gtk_theme=""
  local prefer_dark="0"

  gtk_theme="$(theme_name_for_mode "${mode}")"
  if [[ "${mode}" == "dark" ]]; then
    prefer_dark="1"
  fi

  set_ini_value "${HOME}/.config/gtk-3.0/settings.ini" Settings gtk-theme-name "${gtk_theme}"
  set_ini_value "${HOME}/.config/gtk-3.0/settings.ini" Settings gtk-icon-theme-name "WhiteSur"
  set_ini_value "${HOME}/.config/gtk-3.0/settings.ini" Settings gtk-cursor-theme-name "McMojave-cursors"
  set_ini_value "${HOME}/.config/gtk-3.0/settings.ini" Settings gtk-font-name "Inter 11"
  set_ini_value "${HOME}/.config/gtk-3.0/settings.ini" Settings gtk-cursor-theme-size "24"
  set_ini_value "${HOME}/.config/gtk-3.0/settings.ini" Settings gtk-application-prefer-dark-theme "${prefer_dark}"

  set_ini_value "${HOME}/.config/gtk-4.0/settings.ini" Settings gtk-theme-name "${gtk_theme}"
  set_ini_value "${HOME}/.config/gtk-4.0/settings.ini" Settings gtk-icon-theme-name "WhiteSur"
  set_ini_value "${HOME}/.config/gtk-4.0/settings.ini" Settings gtk-cursor-theme-name "McMojave-cursors"
  set_ini_value "${HOME}/.config/gtk-4.0/settings.ini" Settings gtk-font-name "Inter 11"
  set_ini_value "${HOME}/.config/gtk-4.0/settings.ini" Settings gtk-cursor-theme-size "24"
  set_ini_value "${HOME}/.config/gtk-4.0/settings.ini" Settings gtk-application-prefer-dark-theme "${prefer_dark}"

  set_plain_key_value "${HOME}/.gtkrc-2.0" gtk-theme-name "\"${gtk_theme}\""
  set_plain_key_value "${HOME}/.gtkrc-2.0" gtk-icon-theme-name "\"WhiteSur\""
  set_plain_key_value "${HOME}/.gtkrc-2.0" gtk-cursor-theme-name "\"McMojave-cursors\""
  set_plain_key_value "${HOME}/.gtkrc-2.0" gtk-font-name "\"Inter 11\""
}

reset_kde_gtk_theme_settings() {
  set_ini_value "${HOME}/.config/gtk-3.0/settings.ini" Settings gtk-theme-name "Breeze"
  set_ini_value "${HOME}/.config/gtk-3.0/settings.ini" Settings gtk-icon-theme-name "breeze"
  set_ini_value "${HOME}/.config/gtk-3.0/settings.ini" Settings gtk-cursor-theme-name "breeze_cursors"
  set_ini_value "${HOME}/.config/gtk-3.0/settings.ini" Settings gtk-font-name "Sans 10"
  set_ini_value "${HOME}/.config/gtk-3.0/settings.ini" Settings gtk-cursor-theme-size "24"
  set_ini_value "${HOME}/.config/gtk-3.0/settings.ini" Settings gtk-application-prefer-dark-theme "0"

  set_ini_value "${HOME}/.config/gtk-4.0/settings.ini" Settings gtk-theme-name "Breeze"
  set_ini_value "${HOME}/.config/gtk-4.0/settings.ini" Settings gtk-icon-theme-name "breeze"
  set_ini_value "${HOME}/.config/gtk-4.0/settings.ini" Settings gtk-cursor-theme-name "breeze_cursors"
  set_ini_value "${HOME}/.config/gtk-4.0/settings.ini" Settings gtk-font-name "Sans 10"
  set_ini_value "${HOME}/.config/gtk-4.0/settings.ini" Settings gtk-cursor-theme-size "24"
  set_ini_value "${HOME}/.config/gtk-4.0/settings.ini" Settings gtk-application-prefer-dark-theme "0"

  set_plain_key_value "${HOME}/.gtkrc-2.0" gtk-theme-name "\"Breeze\""
  set_plain_key_value "${HOME}/.gtkrc-2.0" gtk-icon-theme-name "\"breeze\""
  set_plain_key_value "${HOME}/.gtkrc-2.0" gtk-cursor-theme-name "\"breeze_cursors\""
  set_plain_key_value "${HOME}/.gtkrc-2.0" gtk-font-name "\"Sans 10\""
}

apply_kde_macos_config() {
  local mode="$1"
  local wallpaper_series="$2"
  local round_style="${3:-$(default_kde_round_style "${wallpaper_series}")}"
  local color_scheme_name=""
  local plasma_theme_name=""
  local aurorae_theme_name=""

  color_scheme_name="$(find_kde_color_scheme_name "${wallpaper_series}" || true)"
  plasma_theme_name="$(find_kde_plasma_theme_name "${wallpaper_series}" || true)"
  aurorae_theme_name="$(find_kde_aurorae_theme_name "${wallpaper_series}" "${round_style}" || true)"

  if [[ -n "${color_scheme_name}" ]]; then
    if has_command plasma-apply-colorscheme; then
      plasma-apply-colorscheme "${color_scheme_name}" >/dev/null 2>&1 || \
        warn "Could not apply the KDE color scheme ${color_scheme_name} automatically."
    fi
    set_kde_config_value kdeglobals General ColorScheme "${color_scheme_name}" || \
      warn "Could not persist the KDE color scheme automatically."
  fi

  if [[ -n "${plasma_theme_name}" ]]; then
    set_kde_config_value plasmarc Theme name "${plasma_theme_name}" || \
      warn "Could not persist the Plasma desktop theme automatically."
  fi

  if [[ -n "${aurorae_theme_name}" ]]; then
    set_kde_config_value kwinrc org.kde.kdecoration2 theme "${aurorae_theme_name}" || \
      warn "Could not persist the KDE window decoration theme automatically."
  fi

  set_kde_config_value kdeglobals Icons Theme WhiteSur || \
    warn "Could not set the KDE icon theme automatically."
  set_kde_config_value kdeglobals General font "Inter,11,-1,5,50,0,0,0,0,0" || \
    warn "Could not set the KDE UI font automatically."
  set_kde_config_value kdeglobals General fixed "JetBrains Mono,11,-1,5,50,0,0,0,0,0" || \
    warn "Could not set the KDE monospace font automatically."
  set_kde_config_value kdeglobals KDE widgetStyle kvantum || true
  set_kde_config_value kcminputrc Mouse cursorTheme McMojave-cursors || true
  set_kde_config_value kcminputrc Mouse cursorSize 24 || true
  set_kde_config_value kwinrc org.kde.kdecoration2 ButtonsOnLeft XIA || \
    warn "Could not move KDE window buttons to the left automatically."
  set_kde_config_value kwinrc org.kde.kdecoration2 ButtonsOnRight "" || \
    warn "Could not clear KDE right-side window buttons automatically."

  apply_kde_gtk_theme_settings "${mode}"
}

apply_kde_appearance_settings() {
  local mode="$1"
  local wallpaper_path="${2:-}"
  local wallpaper_series="${3:-ventura}"
  local apply_panel_layout="${4:-true}"
  local apply_panel_launchers="${5:-true}"
  local round_style="${6:-$(default_kde_round_style "${wallpaper_series}")}"
  local launchers_csv=""
  local look_and_feel_id=""

  info "Applying KDE appearance settings"

  look_and_feel_id="$(find_kde_lookandfeel_id "${wallpaper_series}" || true)"
  if [[ -n "${look_and_feel_id}" ]]; then
    if has_command plasma-apply-lookandfeel; then
      plasma-apply-lookandfeel -a "${look_and_feel_id}" >/dev/null 2>&1 || \
        warn "Could not apply KDE look-and-feel package ${look_and_feel_id} automatically."
    elif has_command lookandfeeltool; then
      lookandfeeltool -a "${look_and_feel_id}" >/dev/null 2>&1 || \
        warn "Could not apply KDE look-and-feel package ${look_and_feel_id} automatically."
    else
      warn "KDE look-and-feel command not found. Apply ${look_and_feel_id} manually in System Settings."
    fi
  else
    warn "Could not find an installed KDE global theme for ${wallpaper_series}. Apply it manually in System Settings."
  fi

  if [[ -n "${wallpaper_path}" && -f "${wallpaper_path}" ]]; then
    if has_command plasma-apply-wallpaperimage; then
      plasma-apply-wallpaperimage "${wallpaper_path}" >/dev/null 2>&1 || \
        warn "Could not apply the KDE wallpaper automatically."
    else
      warn "plasma-apply-wallpaperimage is not available. Set the wallpaper manually if needed."
    fi
  else
    warn "Wallpaper not found. Skipping wallpaper update."
  fi

  if has_command plasma-apply-cursortheme; then
    plasma-apply-cursortheme "McMojave-cursors" >/dev/null 2>&1 || \
      warn "Could not apply the cursor theme automatically."
  fi

  activate_kde_kvantum_theme "${wallpaper_series}" || \
    warn "Could not detect a matching Kvantum theme automatically."
  apply_kde_macos_config "${mode}" "${wallpaper_series}" "${round_style}"
  if [[ "${apply_panel_layout}" == "true" ]]; then
    apply_kde_panel_layout || \
      warn "Could not restyle the Plasma panel automatically. Adjust the panel manually in edit mode if needed."
  fi
  if [[ "${apply_panel_launchers}" == "true" ]]; then
    launchers_csv="$(resolve_kde_default_launchers || true)"
    if [[ -n "${launchers_csv}" ]]; then
      apply_kde_panel_launchers "${launchers_csv}" || \
        warn "Could not configure default Plasma launchers automatically."
    else
      warn "Could not find suitable desktop launchers to pin on the Plasma panel automatically."
    fi
  fi

  if [[ "${mode}" == "light" ]]; then
    warn "KDE light/dark mode depends on the upstream global theme variant. Verify the result in System Settings if you switch modes."
  fi
}

reset_kde_appearance_settings() {
  info "Resetting KDE appearance settings"

  if has_command plasma-apply-lookandfeel; then
    plasma-apply-lookandfeel -a org.kde.breeze.desktop >/dev/null 2>&1 || \
      warn "Could not reapply the Breeze global theme automatically."
  elif has_command lookandfeeltool; then
    lookandfeeltool -a org.kde.breeze.desktop >/dev/null 2>&1 || \
      warn "Could not reapply the Breeze global theme automatically."
  else
    warn "KDE look-and-feel command not found. Reset the theme manually to Breeze if needed."
  fi

  if has_command plasma-apply-cursortheme; then
    plasma-apply-cursortheme breeze_cursors >/dev/null 2>&1 || \
      warn "Could not reset the cursor theme automatically."
  fi

  set_kde_config_value kdeglobals Icons Theme breeze >/dev/null 2>&1 || true
  set_kde_config_value kdeglobals KDE widgetStyle Breeze >/dev/null 2>&1 || true
  set_kde_config_value kdeglobals General font "Noto Sans,10,-1,5,50,0,0,0,0,0" >/dev/null 2>&1 || true
  set_kde_config_value kdeglobals General fixed "Monospace,10,-1,5,50,0,0,0,0,0" >/dev/null 2>&1 || true
  set_kde_config_value kcminputrc Mouse cursorTheme breeze_cursors >/dev/null 2>&1 || true
  set_kde_config_value kcminputrc Mouse cursorSize 24 >/dev/null 2>&1 || true
  set_kde_config_value kwinrc org.kde.kdecoration2 ButtonsOnLeft M >/dev/null 2>&1 || true
  set_kde_config_value kwinrc org.kde.kdecoration2 ButtonsOnRight IAX >/dev/null 2>&1 || true
  reset_kde_gtk_theme_settings
  reset_kde_panel_layout >/dev/null 2>&1 || true

  if [[ -f "${HOME}/.config/Kvantum/kvantum.kvconfig" ]]; then
    rm -f "${HOME}/.config/Kvantum/kvantum.kvconfig"
    info "Removed ${HOME}/.config/Kvantum/kvantum.kvconfig"
  fi

  warn "KDE wallpaper is not reset automatically."
}

remove_matching_paths() {
  local base_dir="$1"
  local pattern="$2"
  local path=""

  [[ -d "${base_dir}" ]] || return 0

  shopt -s nullglob
  for path in "${base_dir}"/${pattern}; do
    remove_path_if_exists "${path}"
  done
  shopt -u nullglob
}

remove_kde_installed_files() {
  remove_matching_paths "${HOME}/.local/share/plasma/look-and-feel" '*WhiteSur*'
  remove_matching_paths "${HOME}/.local/share/plasma/look-and-feel" '*MacSonoma*'
  remove_matching_paths "${HOME}/.local/share/plasma/look-and-feel" '*MacVentura*'
  remove_matching_paths "${HOME}/.local/share/plasma/look-and-feel" '*MacSequoia*'
  remove_matching_paths "${HOME}/.local/share/plasma/desktoptheme" 'WhiteSur*'
  remove_matching_paths "${HOME}/.local/share/plasma/desktoptheme" 'MacSonoma*'
  remove_matching_paths "${HOME}/.local/share/plasma/desktoptheme" 'MacVentura*'
  remove_matching_paths "${HOME}/.local/share/plasma/desktoptheme" 'MacSequoia*'
  remove_matching_paths "${HOME}/.local/share/color-schemes" 'WhiteSur*'
  remove_matching_paths "${HOME}/.local/share/color-schemes" 'MacSonoma*'
  remove_matching_paths "${HOME}/.local/share/color-schemes" 'MacVentura*'
  remove_matching_paths "${HOME}/.local/share/color-schemes" 'MacSequoia*'
  remove_matching_paths "${HOME}/.local/share/aurorae/themes" 'WhiteSur*'
  remove_matching_paths "${HOME}/.local/share/aurorae/themes" 'MacSonoma*'
  remove_matching_paths "${HOME}/.local/share/aurorae/themes" 'MacVentura*'
  remove_matching_paths "${HOME}/.local/share/aurorae/themes" 'MacSequoia*'
  remove_matching_paths "${HOME}/.config/Kvantum" 'WhiteSur*'
  remove_matching_paths "${HOME}/.config/Kvantum" 'MacSonoma*'
  remove_matching_paths "${HOME}/.config/Kvantum" 'MacVentura*'
  remove_matching_paths "${HOME}/.config/Kvantum" 'MacSequoia*'
  remove_matching_paths "${HOME}/.local/share/Kvantum" 'WhiteSur*'
  remove_matching_paths "${HOME}/.local/share/Kvantum" 'MacSonoma*'
  remove_matching_paths "${HOME}/.local/share/Kvantum" 'MacVentura*'
  remove_matching_paths "${HOME}/.local/share/Kvantum" 'MacSequoia*'
  remove_path_if_exists "${HOME}/.config/Kvantum/kvantum.kvconfig"
}
desktop_entry_get_value() {
  local file_path="$1"
  local key="$2"

  awk -F= -v key="${key}" '
    index($0, key "=") == 1 {
      print substr($0, length(key) + 2)
      exit
    }
  ' "${file_path}"
}

desktop_entry_has_key() {
  local file_path="$1"
  local key="$2"

  grep -Eq "^${key}=" "${file_path}"
}

desktop_entry_is_hidden() {
  local value
  value="$(desktop_entry_get_value "$1" "NoDisplay" || true)"
  [[ "${value,,}" == "true" ]]
}

normalize_desktop_name() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]_-'
}

sanitize_desktop_token() {
  local token="$1"

  token="${token%\"}"
  token="${token#\"}"
  token="${token%\'}"
  token="${token#\'}"
  printf '%s\n' "${token}"
}

desktop_entry_exec_basename_from_value() {
  local exec_value="$1"
  local -a tokens=()
  local token=""

  [[ -n "${exec_value}" ]] || return 1
  read -r -a tokens <<<"${exec_value}"

  for token in "${tokens[@]}"; do
    token="$(sanitize_desktop_token "${token}")"
    case "${token}" in
      ""|env|*/env)
        continue
        ;;
      -*)
        continue
        ;;
      [A-Za-z_][A-Za-z0-9_]*=*)
        continue
        ;;
    esac

    basename "${token}"
    return 0
  done

  return 1
}

desktop_entry_exec_basename() {
  local exec_value
  exec_value="$(desktop_entry_get_value "$1" "Exec" || true)"
  desktop_entry_exec_basename_from_value "${exec_value}"
}

desktop_entry_has_missing_repair_fields() {
  local file_path="$1"

  if ! desktop_entry_has_key "${file_path}" "Icon"; then
    return 0
  fi

  if ! desktop_entry_has_key "${file_path}" "StartupWMClass"; then
    return 0
  fi

  return 1
}

desktop_entry_list_files() {
  local dir_path="$1"

  [[ -d "${dir_path}" ]] || return 0
  find "${dir_path}" -maxdepth 1 -type f -name '*.desktop' -print0
}

desktop_entry_collect_visible_sources() {
  local user_dir="$1"
  local system_dirs_csv="$2"
  local -a directories=()
  local directory=""
  local file_path=""

  directories=("${user_dir}")
  IFS=':' read -r -a extra_dirs <<<"${system_dirs_csv}"
  directories+=("${extra_dirs[@]}")

  for directory in "${directories[@]}"; do
    while IFS= read -r -d '' file_path; do
      if desktop_entry_is_hidden "${file_path}"; then
        continue
      fi
      printf '%s\0' "${file_path}"
    done < <(desktop_entry_list_files "${directory}")
  done
}

desktop_entry_shares_mime_type() {
  local left_file="$1"
  local right_file="$2"
  local left_mimes=""
  local right_mimes=""
  local mime=""

  left_mimes="$(desktop_entry_get_value "${left_file}" "MimeType" || true)"
  right_mimes="$(desktop_entry_get_value "${right_file}" "MimeType" || true)"

  [[ -n "${left_mimes}" && -n "${right_mimes}" ]] || return 1

  IFS=';' read -r -a left_parts <<<"${left_mimes}"
  for mime in "${left_parts[@]}"; do
    [[ -n "${mime}" ]] || continue
    case ";${right_mimes};" in
      *";${mime};"*)
        return 0
        ;;
    esac
  done

  return 1
}

find_desktop_entry_repair_source() {
  local candidate_file="$1"
  local user_dir="$2"
  local system_dirs_csv="$3"
  local candidate_exec=""
  local candidate_name=""
  local source_exec=""
  local source_name=""
  local visible_file=""
  local -a visible_sources=()
  local -a mime_matches=()
  local -a exec_matches=()
  local -a name_matches=()

  mapfile -d '' -t visible_sources < <(
    desktop_entry_collect_visible_sources "${user_dir}" "${system_dirs_csv}"
  )

  for visible_file in "${visible_sources[@]}"; do
    [[ "${visible_file}" == "${candidate_file}" ]] && continue
    if desktop_entry_shares_mime_type "${candidate_file}" "${visible_file}"; then
      mime_matches+=("${visible_file}")
    fi
  done

  if [[ "${#mime_matches[@]}" -eq 1 ]]; then
    printf '%s\n' "${mime_matches[0]}"
    return 0
  fi

  if [[ "${#mime_matches[@]}" -gt 1 ]]; then
    return 2
  fi

  candidate_exec="$(desktop_entry_exec_basename "${candidate_file}" || true)"
  if [[ -n "${candidate_exec}" ]]; then
    for visible_file in "${visible_sources[@]}"; do
      [[ "${visible_file}" == "${candidate_file}" ]] && continue
      source_exec="$(desktop_entry_exec_basename "${visible_file}" || true)"
      if [[ -n "${source_exec}" && "${source_exec}" == "${candidate_exec}" ]]; then
        exec_matches+=("${visible_file}")
      fi
    done
  fi

  if [[ "${#exec_matches[@]}" -eq 1 ]]; then
    printf '%s\n' "${exec_matches[0]}"
    return 0
  fi

  if [[ "${#exec_matches[@]}" -gt 1 ]]; then
    return 2
  fi

  candidate_name="$(normalize_desktop_name "$(desktop_entry_get_value "${candidate_file}" "Name" || true)")"
  if [[ -n "${candidate_name}" ]]; then
    for visible_file in "${visible_sources[@]}"; do
      [[ "${visible_file}" == "${candidate_file}" ]] && continue
      source_name="$(normalize_desktop_name "$(desktop_entry_get_value "${visible_file}" "Name" || true)")"
      if [[ -n "${source_name}" && "${source_name}" == "${candidate_name}" ]]; then
        name_matches+=("${visible_file}")
      fi
    done
  fi

  if [[ "${#name_matches[@]}" -eq 1 ]]; then
    printf '%s\n' "${name_matches[0]}"
    return 0
  fi

  if [[ "${#name_matches[@]}" -gt 1 ]]; then
    return 2
  fi

  return 1
}

backup_file_with_timestamp() {
  local file_path="$1"
  local backup_path=""

  backup_path="${file_path}.bak.$(date +%Y%m%d%H%M%S)"
  cp -p "${file_path}" "${backup_path}"
  printf '%s\n' "${backup_path}"
}

patch_desktop_entry_missing_fields() {
  local file_path="$1"
  local icon_value="${2:-}"
  local wmclass_value="${3:-}"
  local temp_file=""

  temp_file="$(mktemp)"

  awk -v icon_value="${icon_value}" -v wmclass_value="${wmclass_value}" '
    function print_missing() {
      if (inserted) {
        return
      }
      if (icon_value != "") {
        print "Icon=" icon_value
      }
      if (wmclass_value != "") {
        print "StartupWMClass=" wmclass_value
      }
      inserted = 1
    }

    $0 == "[Desktop Entry]" {
      if (in_desktop_entry && !inserted) {
        print_missing()
      }
      in_desktop_entry = 1
      print
      next
    }

    in_desktop_entry && /^\[/ {
      if (!inserted) {
        print_missing()
      }
      in_desktop_entry = 0
      print
      next
    }

    {
      print
    }

    END {
      if (in_desktop_entry && !inserted) {
        print_missing()
      }
    }
  ' "${file_path}" >"${temp_file}"

  mv "${temp_file}" "${file_path}"
}
