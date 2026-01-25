set PATH=%~dp0depot_tools\;%PATH%
set GN_DEFINES=proprietary_codecs=true ffmpeg_branding=Chrome media_use_ffmpeg=true is_component_build=false is_official_build=true is_debug=false symbol_level=0 enable_nacl=false blink_symbol_level=0 v8_symbol_level=0
set GN_ARGUMENTS=--ide=vs2019 --sln=cef --filters=//cef/*
