@echo on
set "SCRIPT_PATH=%~dp0"
echo SCRIPT_PATH:%SCRIPT_PATH%

set PATH=%SCRIPT_PATH%depot_tools\;%PATH%
set GN_DEFINES=proprietary_codecs=true ffmpeg_branding=Chrome is_official_build=true is_debug=false symbol_level=0 enable_nacl=false
set GN_ARGUMENTS=--ide=vs2022 --sln=cef --filters=//cef/*

cd %SCRIPT_PATH%chromium_git\chromium\src\cef
python3.bat tools\gclient_hook.py
