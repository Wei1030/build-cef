@echo on
powershell -Command "Invoke-WebRequest -Uri 'https://storage.googleapis.com/chrome-infra/depot_tools.zip' -OutFile '.\depot_tools.zip'"
powershell -Command "Expand-Archive -Path '.\depot_tools.zip' -DestinationPath '.\depot_tools' -Force"
del /F /Q .\depot_tools.zip
mkdir .\automate
powershell -Command "Invoke-WebRequest -Uri 'https://bitbucket.org/chromiumembedded/cef/raw/master/tools/automate/automate-git.py' -OutFile '.\automate\automate-git.py'"

set CEF_BRANCH=%1
set "SCRIPT_PATH=%~dp0"
echo SCRIPT_PATH:%SCRIPT_PATH%

cd %SCRIPT_PATH%depot_tools
git config --global core.autocrlf false
git config --global core.filemode false
git config --global core.fscache true
git config --global core.preloadindex true
cmd /c update_depot_tools.bat
set PATH=%CD%;%PATH%


mkdir %SCRIPT_PATH%chromium_git
cd %SCRIPT_PATH%chromium_git
python3 ..\automate\automate-git.py --download-dir=%SCRIPT_PATH%chromium_git --depot-tools-dir=%SCRIPT_PATH%depot_tools --branch=%CEF_BRANCH% --no-depot-tools-update --no-chromium-history --no-distrib --no-build
