#!/bin/bash

CEF_BRANCH=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

export PATH=$SCRIPT_DIR/depot_tools:$PATH

mkdir $SCRIPT_DIR/chromium_git
cd $SCRIPT_DIR/chromium_git
python3 ../automate/automate-git.py --download-dir=$SCRIPT_DIR/chromium_git --depot-tools-dir=$SCRIPT_DIR/depot_tools --branch=$CEF_BRANCH --no-chromium-history --no-distrib --no-build


export GN_DEFINES="use_sysroot=false use_allocator=none symbol_level=0 is_cfi=false use_thin_lto=false use_vaapi=false"
cd $SCRIPT_DIR/chromium_git/chromium/src/cef
./cef_create_projects.sh

cd $SCRIPT_DIR/chromium_git/chromium/src
autoninja -C out/Release_GN_x64 cef