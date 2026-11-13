:: Shared build environment for the Windows scripts. Call it, don't run it.
::
:: Optional inputs:
::   CEF_ARCH          x86 (default) or x64
::   EXTRA_GN_DEFINES  appended to GN_DEFINES, e.g. cc_wrapper=sccache
::   BUILD_TARGETS     ninja targets for build.bat (default: cefsimple)
set "SETENV_PATH=%~dp0"
set "PATH=%SETENV_PATH%depot_tools\;%PATH%"
set DEPOT_TOOLS_WIN_TOOLCHAIN=0
set GN_DEFINES=proprietary_codecs=true ffmpeg_branding=Chrome media_use_ffmpeg=true is_component_build=false is_official_build=true is_debug=false symbol_level=0 enable_nacl=false blink_symbol_level=0 v8_symbol_level=0 %EXTRA_GN_DEFINES%
set GN_ARGUMENTS=--ide=vs2022 --sln=cef --filters=//cef/*
if "%CEF_ARCH%"=="" set CEF_ARCH=x86
set BUILD_DIR=Release_GN_%CEF_ARCH%
:: Passed to make_distrib.py (x86 is its default on Windows).
set CEF_ARCH_FLAG=
if "%CEF_ARCH%"=="x64" set CEF_ARCH_FLAG=--x64-build
:: cefsimple pulls in everything the minimal distribution packages (libcef.dll,
:: chrome_elf.dll, ANGLE, SwiftShader, V8 snapshot, paks).
if "%BUILD_TARGETS%"=="" set BUILD_TARGETS=cefsimple
