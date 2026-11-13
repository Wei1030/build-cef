@echo on
set "SCRIPT_PATH=%~dp0"
echo SCRIPT_PATH:%SCRIPT_PATH%

cd %SCRIPT_PATH%chromium_git\chromium\src\third_party\ffmpeg
git apply %SCRIPT_PATH%add-hevc-ffmpeg-decoder-parser.patch

cd %SCRIPT_PATH%chromium_git\chromium\src
git apply %SCRIPT_PATH%fix-webui_module_path.patch
git apply %SCRIPT_PATH%remove-main-main10-profile-limit.patch
git apply %SCRIPT_PATH%vs2026-toolchain.patch
git apply %SCRIPT_PATH%add-external-video-source.patch

set PATH=%SCRIPT_PATH%depot_tools\;%PATH%
set DEPOT_TOOLS_WIN_TOOLCHAIN=0
set GN_DEFINES=proprietary_codecs=true ffmpeg_branding=Chrome media_use_ffmpeg=true is_component_build=false is_official_build=true is_debug=false symbol_level=0 enable_nacl=false blink_symbol_level=0 v8_symbol_level=0
set GN_ARGUMENTS=--ide=vs2022 --sln=cef --filters=//cef/*

cd %SCRIPT_PATH%chromium_git\chromium\src\cef
python3.bat tools\gclient_hook.py
