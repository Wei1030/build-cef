#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

sudo apt-get install curl file lsb-release procps python3 python3-pip
curl 'https://chromium.googlesource.com/chromium/src/+/main/build/install-build-deps.py?format=TEXT' | base64 -d > install-build-deps.py
sudo python3 ./install-build-deps.py --no-arm --no-chromeos-fonts --no-nacl
python3 -m pip install dataclasses importlib_metadata


git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
mkdir $SCRIPT_DIR/automate
cd $SCRIPT_DIR/automate
curl -fSL -o automate-git.py "https://bitbucket.org/chromiumembedded/cef/raw/master/tools/automate/automate-git.py"

