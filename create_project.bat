@echo on
set "SCRIPT_PATH=%~dp0"
echo SCRIPT_PATH:%SCRIPT_PATH%
call "%SCRIPT_PATH%setenv.bat"

cd /d %SCRIPT_PATH%chromium_git\chromium\src\third_party\ffmpeg
git apply %SCRIPT_PATH%add-hevc-ffmpeg-decoder-parser.patch || exit /b 1

cd /d %SCRIPT_PATH%chromium_git\chromium\src
git apply %SCRIPT_PATH%fix-webui_module_path.patch || exit /b 1
git apply %SCRIPT_PATH%remove-main-main10-profile-limit.patch || exit /b 1
git apply %SCRIPT_PATH%vs2026-toolchain.patch || exit /b 1
git apply %SCRIPT_PATH%add-external-video-source.patch || exit /b 1

cd /d %SCRIPT_PATH%chromium_git\chromium\src\cef
call python3.bat tools\gclient_hook.py || exit /b 1
