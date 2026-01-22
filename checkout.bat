@echo on
set "SCRIPT_PATH=%~dp0"
echo SCRIPT_PATH:%SCRIPT_PATH%
set CEF_BRANCH=5414
cd /d %~d0\
mkdir .\code\chromium_git
xcopy %SCRIPT_PATH%automate .\code\automate /E /I /H /Y /Q
xcopy %SCRIPT_PATH%depot_tools .\code\depot_tools /E /I /H /Y /Q

cd %~d0\code\depot_tools
git config --global core.autocrlf false
git config --global core.filemode false
git config --global core.fscache true
git config --global core.preloadindex true
echo start update_depot_tools, current path: %CD%
update_depot_tools.bat
set PATH=%CD%;%PATH%
echo update_depot_tools end.


cd %~d0\code\chromium_git
echo call automate-git.py, current path: %CD%
python3 ..\automate\automate-git.py --download-dir=%~d0\code\chromium_git --depot-tools-dir=%~d0\code\depot_tools --branch=%CEF_BRANCH% --url="--depth 1 --branch %CEF_BRANCH% https://bitbucket.org/chromiumembedded/cef.git" --no-chromium-history --no-distrib --no-build
echo automate-git.py end.

cd %~d0\code\chromium_git\chromium\src\cef
set GN_DEFINES=proprietary_codecs=true ffmpeg_branding=Chrome is_official_build=true is_debug=false symbol_level=0 enable_nacl=false
set GN_ARGUMENTS=--ide=vs2022 --sln=cef --filters=//cef/*
call cef_create_projects.bat
cd %~d0\code\chromium_git\chromium\src
autoninja -C out\Release_GN_x86 cef
