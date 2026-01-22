@echo on
set CEF_BRANCH=%1
set "SCRIPT_PATH=%~dp0"
echo SCRIPT_PATH:%SCRIPT_PATH%
git config --global core.autocrlf false
git config --global core.filemode false
git config --global core.fscache true
git config --global core.preloadindex true

set PATH=%SCRIPT_PATH%depot_tools\;%PATH%

cd %SCRIPT_PATH%chromium_git
echo call automate-git.py, current path: %CD%
python3 ..\automate\automate-git.py --download-dir=%SCRIPT_PATH%chromium_git --depot-tools-dir=%SCRIPT_PATH%depot_tools --branch=%CEF_BRANCH% --force-clean --no-update --no-depot-tools-update --no-chromium-history --no-distrib --no-build
echo automate-git.py end.

cd %SCRIPT_PATH%chromium_git\chromium\src\cef
set GN_DEFINES=proprietary_codecs=true ffmpeg_branding=Chrome is_official_build=true is_debug=false symbol_level=0 enable_nacl=false
set GN_ARGUMENTS=--ide=vs2022 --sln=cef --filters=//cef/*
call cef_create_projects.bat
cd %SCRIPT_PATH%chromium_git\chromium\src
autoninja -C out\Release_GN_x86 cef
