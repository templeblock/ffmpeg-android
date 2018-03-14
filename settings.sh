#!/bin/bash
#
# Copyright 2016 Eng Chong Meng
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
set -x
if [ "$ANDROID_NDK" = "" ]; then
	echo "You need to set ANDROID_NDK environment variable, exiting"
	echo "Use: export ANDROID_NDK=/your/path/to/android-ndk"
	exit 1
fi
set -u

# Never mix two api level to build static library for use on the same apk.
# Set to API:15 for aTalk minimun support for platform API-15
# Does not build 64-bit arch if ANDROID_API is less than 21 - the minimum supported API level for 64-bit.
ANDROID_API=21
NDK_ABI_VERSION=4.9

# Built with command i.e. ./ffmpeg-android_build.sh or following with parameter [ABIS(x)]
# Create custom ABIS or uncomment to build all supported abi for ffmpeg.
# Do not change naming convention of the ABIS; see:
# https://developer.android.com/ndk/guides/abis.html#Native code in app packages
# Android recomended architecture support; others are deprecated
ABIS=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")
#ABIS=("armeabi" "armeabi-v7a" "arm64-v8a" "mips" "mips64" "x86" "x86_64")

BASEDIR=`pwd`
TOOLCHAIN_PREFIX=${BASEDIR}/toolchain-android

#===========================================
# Do not procced on first call without the required 2 parameters
[[ $# -lt 2 ]] && return

NDK=${ANDROID_NDK}
HOST_NUM_CORES=$(nproc)

CFLAGS='-fPIE -fPIC -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2 -fno-strict-overflow -fstack-protector-all'
LDFLAGS='-pie -Wl,-z,relro -Wl,-z,now -nostdlib -lc -lm -ldl -llog'

# https://en.wikipedia.org/wiki/List_of_ARM_microarchitectures
case $1 in
  # Deprecated in r16. Will be removed in r17
  armeabi)
    HOST='arm-linux'
    NDK_ARCH="arm"
    NDK_ABIARCH='arm-linux-androideabi'
    NDK_CROSS_PREFIX="${NDK_ABIARCH}"
    CFLAGS="$CFLAGS -march=armv5 -marm"
  ;;
  armeabi-v7a)
    HOST='arm-linux'
    NDK_ARCH='arm'
    NDK_ABIARCH='arm-linux-androideabi'
    NDK_CROSS_PREFIX="${NDK_ABIARCH}"
    CFLAGS="$CFLAGS -march=armv7-a -Wl,--fix-cortex-a8 -marm -mfloat-abi=softfp -mfpu=neon -mtune=cortex-a8 -mthumb -D__thumb__"

    # arm v7vfpv3
    # CFLAGS="$CFLAGS -march=$CPU -marm -mfloat-abi=softfp -mfpu=vfpv3-d16"

    # arm v7 + neon (neon also include vfpv3-32)
    # CFLAGS="$CFLAGS -march=$CPU -marm -mfloat-abi=softfp -mfpu=neon"-mtune=cortex-a8 -mthumb -D__thumb__" 
  ;;
  arm64-v8a)
    HOST='aarch64-linux'
    NDK_ARCH='arm64'
    NDK_ABIARCH='aarch64-linux-android'
    NDK_CROSS_PREFIX="${NDK_ABIARCH}"
    CFLAGS="$CFLAGS"
  ;;
  mips)
    HOST='mips-linux'
    NDK_ARCH='mips'
    NDK_ABIARCH="mipsel-linux-android"
    NDK_CROSS_PREFIX="${NDK_ABIARCH}"
    CFLAGS="$CFLAGS -EL -march=mips32 -mips32 -mhard-float"
  ;;
  mips64)
    HOST='mips64-linux'
    NDK_ARCH='mips64'
    NDK_ABIARCH='mips64el-linux-android'
    NDK_CROSS_PREFIX="${NDK_ABIARCH}"
    CFLAGS="$CFLAGS -EL -mfp64 -mhard-float"
  ;;
  # MIPS is deprecated in NDK r16 and will be removed in NDK r17.
  x86)
    HOST='i686-linux'
    NDK_ARCH='x86'
    NDK_ABIARCH='x86'
    NDK_CROSS_PREFIX="i686-linux-android"
    CFLAGS="$CFLAGS -O2 -march=i686 -mtune=intel -mssse3 -mfpmath=sse -m32"
  ;;
  x86_64)
    HOST='x86_64-linux'
    NDK_ARCH='x86_64'
    NDK_ABIARCH='x86_64'
    NDK_CROSS_PREFIX="x86_64-linux-android"
    CFLAGS="$CFLAGS -O2 -march=x86-64 -mtune=intel -msse4.2 -mpopcnt -m64"
  ;;
esac

# cmeng: must ensure AS JNI uses the same STL library or "system" if specified
# Create standalone toolchains for the specified architecture - use .py instead of the old .sh
  [ -d ${TOOLCHAIN_PREFIX} ] || python $NDK/build/tools/make_standalone_toolchain.py \
    --arch ${NDK_ARCH} \
    --api ${ANDROID_API} \
    --stl=libc++ \
    --install-dir=${TOOLCHAIN_PREFIX}

# old .sh replaced with .py
#[ -d ${TOOLCHAIN_PREFIX} ] || $NDK/build/tools/make-standalone-toolchain.sh \
#  --toolchain=${NDK_ABIARCH}-${NDK_ABI_VERSION} \
#  --platform=android-$ANDROID_API \
#  --install-dir=${TOOLCHAIN_PREFIX}

# Direct NDK path without copying - not advise to use this
# OS_ARCH=`basename $ANDROID_NDK/toolchains/arm-linux-androideabi-$NDK_ABI_VERSION/prebuilt/*`
# PREBUILT=$ANDROID_NDK/toolchains/$NDK_ABIARCH-$NDK_ABI_VERSION/prebuilt/$OS_ARCH
# export PLATFORM=$ANDROID_NDK/platforms/android-$ANDROID_API/arch-$NDK_ARCH
# export CROSS_PREFIX=$PREBUILT/bin/$NDK_CROSS_PREFIX-

NDK_SYSROOT=${TOOLCHAIN_PREFIX}/sysroot
PREFIX=$BASEDIR/build/ffmpeg/android/$1
FFMPEG_PKG_CONFIG=${BASEDIR}/ffmpeg-pkg-config

# Add the standalone toolchain to the search path.
export PATH=$TOOLCHAIN_PREFIX/bin:$PATH
export CROSS_PREFIX=$TOOLCHAIN_PREFIX/bin/$NDK_CROSS_PREFIX-
export CFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
export CXXFLAGS="$CFLAGS"

# lame work with gcc/g+ and have problem when export LDFLAGS!
if [[ $0 = *"lame"* ]]; then
  export LDFLAGS=""
else
  export LDFLAGS="-Wl,-rpath-link=$NDK_SYSROOT/usr/lib -L$NDK_SYSROOT/usr/lib $LDFLAGS"
fi

export CC="${CROSS_PREFIX}clang"
export CXX="${CROSS_PREFIX}clang++"
export AS="${CROSS_PREFIX}clang"
export AR="${CROSS_PREFIX}ar"
export LD="${CROSS_PREFIX}ld"
export RANLIB="${CROSS_PREFIX}ranlib"
export STRIP="${CROSS_PREFIX}strip"
export OBJDUMP="${CROSS_PREFIX}objdump"
export CPP="${CROSS_PREFIX}cpp"
export GCONV="${CROSS_PREFIX}gconv"
export NM="${CROSS_PREFIX}nm"
export SIZE="${CROSS_PREFIX}size"
export PKG_CONFIG="${CROSS_PREFIX}pkg-config"
export PKG_CONFIG_LIBDIR=$PREFIX/lib/pkgconfig
export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
