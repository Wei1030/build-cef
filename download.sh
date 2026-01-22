#!/bin/bash

CEF_BRANCH=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"


mkdir ./automate
mkdir ./chromium_git

sudo apt-get install curl file lsb-release procps python3 python3-pip
curl 'https://chromium.googlesource.com/chromium/src/+/main/build/install-build-deps.py?format=TEXT' | base64 -d > install-build-deps.py
sudo python3 ./install-build-deps.py --no-arm --no-chromeos-fonts --no-nacl
python3 -m pip install dataclasses importlib_metadata


git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git


export PATH=$SCRIPT_DIR/depot_tools:$PATH

cd $SCRIPT_DIR/automate
wget https://bitbucket.org/chromiumembedded/cef/raw/master/tools/automate/automate-git.py

cd $SCRIPT_DIR/chromium_git
python3 ../automate/automate-git.py --download-dir=$SCRIPT_DIR/chromium_git --depot-tools-dir=$SCRIPT_DIR/depot_tools --branch=$CEF_BRANCH --no-depot-tools-update --no-chromium-history --no-distrib --no-build



