@echo on
set "SCRIPT_PATH=%~dp0"
echo SCRIPT_PATH:%SCRIPT_PATH%

set PATH=%SCRIPT_PATH%depot_tools\;%PATH%
set DEPOT_TOOLS_WIN_TOOLCHAIN=0
set GN_DEFINES=proprietary_codecs=true ffmpeg_branding=Chrome media_use_ffmpeg=true is_component_build=false is_official_build=true is_debug=false symbol_level=0 enable_nacl=false blink_symbol_level=0 v8_symbol_level=0
set GN_ARGUMENTS=--ide=vs2022 --sln=cef --filters=//cef/*

cd %SCRIPT_PATH%chromium_git\chromium\src
autoninja -C out\Release_GN_x86 cef
