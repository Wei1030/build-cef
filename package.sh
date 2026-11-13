#!/bin/bash
# Creates the minimal binary distribution (Linux / macOS version of
# package.bat).
set -euo pipefail
SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_PATH/setenv.sh"

cd "$SCRIPT_PATH/chromium_git/chromium/src/cef/tools"
python3 make_distrib.py --ninja-build --output-dir="$SCRIPT_PATH/output" \
  --no-docs --minimal $CEF_ARCH_FLAG
