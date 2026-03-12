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
