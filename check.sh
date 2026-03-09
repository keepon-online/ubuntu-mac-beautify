#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SCRIPTS=(
  "${PROJECT_ROOT}/install.sh"
  "${PROJECT_ROOT}/reapply.sh"
  "${PROJECT_ROOT}/reset.sh"
  "${PROJECT_ROOT}/uninstall.sh"
  "${PROJECT_ROOT}/lib/common.sh"
)

echo "[INFO] Running bash -n"
for script in "${SCRIPTS[@]}"; do
  bash -n "${script}"
done

if command -v shellcheck >/dev/null 2>&1; then
  echo "[INFO] Running shellcheck"
  shellcheck "${SCRIPTS[@]}"
else
  echo "[WARN] shellcheck not found, skipped"
fi

echo "[INFO] Check complete"
