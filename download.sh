#!/bin/bash
# Downloads depot_tools and automate-git.py (Linux / macOS version of
# download.bat).
set -euo pipefail
SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_PATH"

if [ ! -d depot_tools/.git ]; then
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git depot_tools
fi

# automate-git.py is pinned to a known CEF commit so fix-automate-git.patch
# keeps applying. Keep in sync with download.bat.
AUTOMATE_COMMIT=b4ce724e45013510fdf6880c0b9357025e0959c5
mkdir -p automate
curl -fsSL -o automate/automate-git.py \
  "https://raw.githubusercontent.com/chromiumembedded/cef/${AUTOMATE_COMMIT}/tools/automate/automate-git.py"
git apply fix-automate-git.patch
