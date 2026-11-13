#!/bin/bash
# Downloads CEF and Chromium sources (Linux / macOS version of prepare.bat).
# Usage: prepare.sh <cef_branch>
set -euo pipefail
CEF_BRANCH="${1:?usage: prepare.sh <cef_branch>}"
SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_PATH/setenv.sh"

git config --global core.autocrlf false

"$SCRIPT_PATH/depot_tools/update_depot_tools"

mkdir -p "$SCRIPT_PATH/chromium_git"
cd "$SCRIPT_PATH/chromium_git"
python3 ../automate/automate-git.py \
  --download-dir="$SCRIPT_PATH/chromium_git" \
  --depot-tools-dir="$SCRIPT_PATH/depot_tools" \
  --branch="$CEF_BRANCH" \
  --no-depot-tools-update --no-chromium-history --with-pgo-profiles \
  --no-distrib --no-build $CEF_ARCH_FLAG
