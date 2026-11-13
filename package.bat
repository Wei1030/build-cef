@echo on
set "SCRIPT_PATH=%~dp0"
echo SCRIPT_PATH:%SCRIPT_PATH%
call "%SCRIPT_PATH%setenv.bat"

cd /d %SCRIPT_PATH%chromium_git\chromium\src\cef\tools
call python3.bat .\make_distrib.py --ninja-build --output-dir="%SCRIPT_PATH%output" --no-docs --minimal || exit /b 1
