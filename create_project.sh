#!/bin/bash
# Applies the patches and generates the GN projects (Linux / macOS version of
# create_project.bat).
set -euo pipefail
SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_PATH/setenv.sh"
SRC="$SCRIPT_PATH/chromium_git/chromium/src"

git -C "$SRC/third_party/ffmpeg" apply "$SCRIPT_PATH/add-hevc-ffmpeg-decoder-parser.patch"

for patch in fix-webui_module_path.patch \
             remove-main-main10-profile-limit.patch \
             vs2026-toolchain.patch \
             add-external-video-source.patch; do
  git -C "$SRC" apply "$SCRIPT_PATH/$patch"
done

echo "GN_DEFINES=$GN_DEFINES"
cd "$SRC/cef"
python3 tools/gclient_hook.py
