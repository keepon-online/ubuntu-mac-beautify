#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${PROJECT_ROOT}/lib/common.sh"

DISABLE_BLUR="true"
ROLLBACK_GDM="true"
DESKTOP="auto"

for arg in "$@"; do
  case "${arg}" in
    --desktop=*)
      DESKTOP="$(normalize_desktop "${arg#*=}")" || die "Unsupported desktop: ${arg#*=}"
      ;;
    --keep-blur)
      DISABLE_BLUR="false"
      ;;
    --keep-gdm)
      ROLLBACK_GDM="false"
      ;;
    -h|--help)
      cat <<'EOF'
Usage: ./reset.sh [options]

Options:
  --desktop=DESKTOP    auto (default), gnome, or kde
  --keep-blur          Do not disable Blur my Shell (GNOME only)
  --keep-gdm           Do not roll back the project custom GDM theme (GNOME only)
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

  reset_appearance_settings
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

  reset_kde_appearance_settings
fi

info "Done"
echo
echo "Project           : ${PROJECT_ROOT}"
echo "Desktop target    : ${DESKTOP}"
if [[ "${DESKTOP}" == "gnome" ]]; then
  echo "Blur disabled     : ${DISABLE_BLUR}"
  echo "GDM rolled back   : ${ROLLBACK_GDM}"
  echo "If GNOME does not refresh immediately, log out and log back in once."
else
  echo "KDE reset         : attempted"
  echo "If Plasma does not refresh immediately, log out and log back in once."
fi
