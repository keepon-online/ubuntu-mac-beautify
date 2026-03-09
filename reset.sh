#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${PROJECT_ROOT}/lib/common.sh"

DISABLE_BLUR="true"

for arg in "$@"; do
  case "${arg}" in
    --keep-blur)
      DISABLE_BLUR="false"
      ;;
    -h|--help)
      cat <<'EOF'
Usage: ./reset.sh [options]

Options:
  --keep-blur     Do not disable Blur my Shell
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

reset_appearance_settings

info "Done"
echo
echo "Project           : ${PROJECT_ROOT}"
echo "Blur disabled     : ${DISABLE_BLUR}"
echo "If GNOME does not refresh immediately, log out and log back in once."
