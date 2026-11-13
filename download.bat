@echo on
set "SCRIPT_PATH=%~dp0"
cd /d %SCRIPT_PATH%

powershell -Command "Invoke-WebRequest -Uri 'https://storage.googleapis.com/chrome-infra/depot_tools.zip' -OutFile '.\depot_tools.zip'"
powershell -Command "Expand-Archive -Path '.\depot_tools.zip' -DestinationPath '.\depot_tools' -Force"
del /F /Q .\depot_tools.zip

:: automate-git.py is pinned to a known CEF commit so fix-automate-git.patch
:: keeps applying. Update both together when moving to a newer version.
set AUTOMATE_COMMIT=b4ce724e45013510fdf6880c0b9357025e0959c5
mkdir .\automate
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/chromiumembedded/cef/%AUTOMATE_COMMIT%/tools/automate/automate-git.py' -OutFile '.\automate\automate-git.py'"
git apply fix-automate-git.patch
