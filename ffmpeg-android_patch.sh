#!/bin/bash
# set -x
# Applying required patches for all the codec modules

# ===============================
# ffmpeg patches
# ===============================
if [[ -f "ffmpeg/ffbuild/version.sh" ]]; then
  VERSION=$(ffmpeg/ffbuild/version.sh ./ffmpeg)
else
  VERSION=$(ffmpeg/version.sh ./ffmpeg)
fi

echo -e "### Applying patches for ffmpeg-v${VERSION} modules"

if [[ ${VERSION} == 1.0.10 ]]; then
    patch  -p0 -N --dry-run --silent -f ./ffmpeg/configure < ./patches/ffmpeg-1.0.10/10.ffmpeg-configure.patch 1>/dev/null
    if [[ $? -eq 0 ]]; then
      patch -p0 -f ./ffmpeg/configure < ./patches/ffmpeg-1.0.10/10.ffmpeg-configure.patch
    fi

    patch  -p0 -N --dry-run --silent -f ./ffmpeg/libavcodec/libx264.c < ./patches/ffmpeg-1.0.10/11.ffmpeg-libx264.c.patch 1>/dev/null
    if [[ $? -eq 0 ]]; then
      patch -p0 -f ./ffmpeg/libavcodec/libx264.c < ./patches/ffmpeg-1.0.10/11.ffmpeg-libx264.c.patch
    fi

    patch  -p0 -N --dry-run --silent -f ./ffmpeg/libavutil/pixdesc.c < ./patches/ffmpeg-1.0.10/12.ffmpeg-pixdesc.c.patch 1>/dev/null
    if [[ $? -eq 0 ]]; then
      patch -p0 -f ./ffmpeg/libavutil/pixdesc.c < ./patches/ffmpeg-1.0.10/12.ffmpeg-pixdesc.c.patch
    fi

    patch  -p0 -N --dry-run --silent -f ./ffmpeg/libavutil/pixdesc.h < ./patches/ffmpeg-1.0.10/13.ffmpeg-pixdesc.h.patch 1>/dev/null
    if [[ $? -eq 0 ]]; then
      patch -p0 -f ./ffmpeg/libavutil/pixdesc.h < ./patches/ffmpeg-1.0.10/13.ffmpeg-pixdesc.h.patch
    fi

    patch  -p0 -N --dry-run --silent -f ./ffmpeg/libavcodec/svq3.c < ./patches/ffmpeg-1.0.10/14.ffmpeg-svq3.c.patch 1>/dev/null
    if [[ $? -eq 0 ]]; then
      patch -p0 -f ./ffmpeg/libavcodec/svq3.c < ./patches/ffmpeg-1.0.10/14.ffmpeg-svq3.c.patch
    fi
else
    patch  -p0 -N --dry-run --silent -f ./ffmpeg/libavcodec/aaccoder.c < ./patches/01.ffmpeg_aacoder.patch 1>/dev/null
    if [[ $? -eq 0 ]]; then
      patch -p0 -f ./ffmpeg/libavcodec/aaccoder.c < ./patches/01.ffmpeg_aacoder.patch
    fi

    patch  -p0 -N --dry-run --silent -f ./ffmpeg/libavcodec/hevc_mvs.c < ./patches/02.ffmpeg_hevc_mvs.patch 1>/dev/null
    if [[ $? -eq 0 ]]; then
      patch -p0 -f ./ffmpeg/libavcodec/hevc_mvs.c < ./patches/02.ffmpeg_hevc_mvs.patch
    fi

    patch  -p0 -N --dry-run --silent -f ./ffmpeg/libavcodec/opus_pvq.c < ./patches/03.ffmpeg_opus_pvq.patch 1>/dev/null
    if [[ $? -eq 0 ]]; then
      patch -p0 -f ./ffmpeg/libavcodec/opus_pvq.c < ./patches/03.ffmpeg_opus_pvq.patch
    fi

    patch  -p0 -N --dry-run --silent -f ./ffmpeg/libaudevice/v4l2.c < ./patches/04.ffmpeg_v4l2.patch 1>/dev/null
    if [[ $? -eq 0 ]]; then
      patch -p0 -f ./ffmpeg/libaudevice/v4l2.c < ./patches/03.ffmpeg_v4l2.patch
    fi
fi

# ===============================
# libvpx patches for version 1.8.0, 1.7.0 and 1.6.1+
# ===============================
LIB_VPX="libvpx"
if [[ -f "${LIB_VPX}/build/make/version.sh" ]]; then
  version=`"${LIB_VPX}/build/make/version.sh" --bare "${LIB_VPX}"`
else
  version='v1.7.0'
fi
echo -e "### Applying patches for libvpx-${version} modules"

patch  -p0 -N --dry-run --silent -f ./${LIB_VPX}/build/make/configure.sh < ./patches/10.libvpx_configure.sh.patch 1>/dev/null
if [[ $? -eq 0 ]]; then
  patch -p0 -f ./${LIB_VPX}/build/make/configure.sh < ./patches/10.libvpx_configure.sh.patch
fi

# v1.8.0 does not have filter_x86.c
if [[ "${version}" == v1.7.0 ]] || [[ "${version}" == v1.6.1 ]]; then
  patch  -p0 -N --dry-run --silent -f ./${LIB_VPX}/vp8/common/x86/filter_x86.c < ./patches/11.libvpx_filter_x86.c.patch 1>/dev/null
  if [[ $? -eq 0 ]]; then
    patch -p0 -f ./${LIB_VPX}/vp8/common/x86/filter_x86.c < ./patches/11.libvpx_filter_x86.c.patch
  fi

  patch  -p0 -N --dry-run --silent -f ./${LIB_VPX}/vpx_dsp/deblock.c < ./patches/12.libvpx_deblock.c.patch 1>/dev/null
  if [[ $? -eq 0 ]]; then
    patch -p0 -f ./${LIB_VPX}/vpx_dsp/deblock.c < ./patches/12.libvpx_deblock.c.patch
  fi

  patch  -p0 -N --dry-run --silent -f ./${LIB_VPX}/vpx_ports/mem.h < ./patches/13.libvpx_mem.h.patch 1>/dev/null
  if [[ $? -eq 0 ]]; then
    patch -p0 -f ./${LIB_VPX}/vpx_ports/mem.h < ./patches/13.libvpx_mem.h.patch
  fi
fi

# ===============================
# x264 patches
# ===============================
X264_API="$(grep '#define X264_BUILD' < x264/x264.h | sed 's/^.* \([1-9][0-9]*\).*$/\1/')"
echo -e "### Applying patches for x264-v${X264_API} modules"

patch  -p0 -N --dry-run --silent -f ./x264/configure < ./patches/21.x264_configure.patch 1>/dev/null
if [[ $? -eq 0 ]]; then
  patch -p0 -f ./x264/configure < ./patches/21.x264_configure.patch
fi

# ===============================
# lame patches
# ===============================
LAME_VER="$(grep 'PACKAGE_VERSION =' < lame/Makefile | sed 's/^.* \([1-9]\.[0-9]*\).*$/\1/')"
echo -e "### Applying patches for lame-v${LAME_VER} modules"

patch  -p0 -N --dry-run --silent -f ./lame/configure < ./patches/31.lame_configure.patch 1>/dev/null
if [[ $? -eq 0 ]]; then
  patch -p0 -f ./lame/configure < ./patches/31.lame_configure.patch
fi

# ===============================
# fontconfig patches
# ===============================
patch  -p0 -N --dry-run --silent -f ./fontconfig/src/fcxml.c < ./patches/41.fontconfig_fcxml.patch 1>/dev/null
if [[ $? -eq 0 ]]; then
  patch -p0 -f ./fontconfig/src/fcxml.c < ./patches/41.fontconfig_fcxml.patch
fi
