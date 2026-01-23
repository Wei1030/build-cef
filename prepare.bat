@echo on
set CEF_BRANCH=%1
set "SCRIPT_PATH=%~dp0"
echo SCRIPT_PATH:%SCRIPT_PATH%
git config --global core.autocrlf false
git config --global core.filemode false
git config --global core.fscache true
git config --global core.preloadindex true

cd %SCRIPT_PATH%depot_tools
cmd /c update_depot_tools.bat
set PATH=%SCRIPT_PATH%LLVM\bin;%SCRIPT_PATH%depot_tools\;%PATH%
clang --version

mkdir %SCRIPT_PATH%chromium_git
cd %SCRIPT_PATH%chromium_git
python3 ..\automate\automate-git.py --download-dir=%SCRIPT_PATH%chromium_git --depot-tools-dir=%SCRIPT_PATH%depot_tools --branch=%CEF_BRANCH% --no-depot-tools-update --no-chromium-history --with-pgo-profiles --no-distrib --no-build

