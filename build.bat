@echo on
set "SCRIPT_PATH=%~dp0"
echo SCRIPT_PATH:%SCRIPT_PATH%
call "%SCRIPT_PATH%setenv.bat"

cd /d %SCRIPT_PATH%chromium_git\chromium\src
call autoninja -C out\%BUILD_DIR% %BUILD_TARGETS% || exit /b 1
