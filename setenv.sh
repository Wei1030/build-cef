# Shared build environment for the Linux / macOS scripts. Source it, don't run
# it.
#
# Optional inputs:
#   CEF_ARCH          x64 or arm64 (default: host architecture)
#   EXTRA_GN_DEFINES  appended to GN_DEFINES, e.g. cc_wrapper=sccache
#   BUILD_TARGETS     ninja targets for build.sh
#   MAC_SDK_PATH      macOS only: SDK to build against (e.g. MacOSX13.0.sdk)

SETENV_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$SETENV_PATH/depot_tools:$PATH"

case "$(uname -s)" in
  Linux)  CEF_PLATFORM=linux ;;
  Darwin) CEF_PLATFORM=mac ;;
  *) echo "Unsupported OS: $(uname -s)" >&2; return 1 ;;
esac

if [ -z "${CEF_ARCH:-}" ]; then
  case "$(uname -m)" in
    arm64|aarch64) CEF_ARCH=arm64 ;;
    *) CEF_ARCH=x64 ;;
  esac
fi

# Passed to automate-git.py and make_distrib.py.
CEF_ARCH_FLAG="--${CEF_ARCH}-build"
BUILD_DIR="Release_GN_${CEF_ARCH}"

GN_DEFINES="proprietary_codecs=true ffmpeg_branding=Chrome media_use_ffmpeg=true is_component_build=false is_official_build=true is_debug=false symbol_level=0 enable_nacl=false blink_symbol_level=0 v8_symbol_level=0"

if [ "$CEF_PLATFORM" = linux ]; then
  # CEF defaults to use_sysroot=false on Linux; build against Chromium's
  # Debian sysroot so the result does not depend on the host distribution.
  GN_DEFINES="$GN_DEFINES use_sysroot=true is_cfi=false"
  export CEF_INSTALL_SYSROOT="$CEF_ARCH"
  # make_distrib.py packages libcef.so and chrome-sandbox.
  : "${BUILD_TARGETS:=cefsimple chrome_sandbox}"
else
  # gn_args.py generates configurations for the host CPU; also allow
  # cross-compiling for the other one.
  if [ "$CEF_ARCH" = arm64 ]; then
    export CEF_ENABLE_ARM64=1
  else
    export CEF_ENABLE_AMD64=1
  fi
  # make_distrib.py takes the framework from cefclient.app.
  : "${BUILD_TARGETS:=cefclient}"
  # Chromium 109's clang cannot parse the SDKs of current Xcode releases
  # (15.x); point it at the 13.0 SDK it was released with.
  if [ -n "${MAC_SDK_PATH:-}" ]; then
    GN_DEFINES="$GN_DEFINES mac_sdk_path=$MAC_SDK_PATH"
  fi
fi

# make_distrib.py defaults to zip, which loses symlinks (macOS frameworks) and
# file permissions.
export CEF_ARCHIVE_FORMAT="${CEF_ARCHIVE_FORMAT:-tar.bz2}"

export GN_DEFINES="$GN_DEFINES ${EXTRA_GN_DEFINES:-}"
export CEF_PLATFORM CEF_ARCH CEF_ARCH_FLAG BUILD_DIR BUILD_TARGETS
