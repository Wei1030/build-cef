#!/bin/bash
# Builds CEF (Linux / macOS version of build.bat).
set -euo pipefail
SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_PATH/setenv.sh"

cd "$SCRIPT_PATH/chromium_git/chromium/src"
autoninja -C "out/$BUILD_DIR" $BUILD_TARGETS
