:: Shared build environment for the Windows scripts. Call it, don't run it.
::
:: Optional inputs:
::   EXTRA_GN_DEFINES  appended to GN_DEFINES, e.g. cc_wrapper=sccache
::   BUILD_TARGETS     ninja targets for build.bat (default: cefsimple)
set "SETENV_PATH=%~dp0"
set "PATH=%SETENV_PATH%depot_tools\;%PATH%"
set DEPOT_TOOLS_WIN_TOOLCHAIN=0
set GN_DEFINES=proprietary_codecs=true ffmpeg_branding=Chrome media_use_ffmpeg=true is_component_build=false is_official_build=true is_debug=false symbol_level=0 enable_nacl=false blink_symbol_level=0 v8_symbol_level=0 %EXTRA_GN_DEFINES%
set GN_ARGUMENTS=--ide=vs2022 --sln=cef --filters=//cef/*
set BUILD_DIR=Release_GN_x86
if "%BUILD_TARGETS%"=="" set BUILD_TARGETS=cefsimple
