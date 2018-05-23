#!/bin/bash

# Author: Mikhail Nosov (drdeimosnn@gmail.com)
# Build packages bspwm and sxhkd with hcheckinstall for ubuntu 16.04
# bspwm: https://github.com/baskerville/bspwm.git
# sxhkd: https://github.com/baskerville/sxhkd.git
#
# Requirements:
# * Packages: build-essential, checkinstall, fakeroot, gcc

set -e

if [ -z $1 ]; then
  echo "Please set package dir in first arg. Example: ./bspwm_update.sh /build"
  exit
fi

apt update
apt -y upgrade

PACDIR="$1"
MAINTAINER="drdeimosnn@gmail.com"
RELEASE="$(awk -F '=' '/CODENAME/ {print $2}' /etc/lsb-release)-$(date '+%Y%m%d%H%M%S')"
COMMON_BUILD_DEPS="git make gcc checkinstall"

### BUILD BSPWM ###
BSPWM_BUILD_DIR=$(mktemp -d)
BSPWM_REQUIRES="libc6, libxcb1, libxau6, libxcb-ewmh2, libxcb-icccm4, libxcb-keysyms1, libxcb-randr0, libxcb-util1, libxcb-xinerama0, libxdmcp6"
BSPWM_BUILD_DEPS="libxcb-xinerama0-dev libxcb-icccm4-dev libxcb-randr0-dev libxcb-util-dev libxcb-ewmh-dev libxcb-keysyms1-dev"
BSPWM_DESCRIPTION="A tiling window manager based on binary space partitioning"
BSPWM_REPO="https://github.com/baskerville/bspwm.git"

apt update
apt install -y ${COMMON_BUILD_DEPS} $BSPWM_BUILD_DEPS

git clone $BSPWM_REPO $BSPWM_BUILD_DIR
cd $BSPWM_BUILD_DIR
VERSION=$(git describe --long)
make
echo $BSPWM_DESCRIPTION > description-pak
checkinstall --pkgname bspwm \
  --maintainer $MAINTAINER \
  --provides bspwm \
  --requires "$BSPWM_REQUIRES" \
  --pkgversion $VERSION \
  --pkgrelease ${RELEASE} \
  --nodoc \
  --pkgsource $BSPWM_REPO \
  --pakdir $PACDIR
rm -rf $BSPWM_BUILD_DIR
cd ~/
### END ###

### BUILD SXHKD ###
SXHKD_BUILD_DIR=$(mktemp -d)
SXHKD_REQUIRES="libxcb1, libxcb-keysyms1, libc6, libxau6, libxdmcp6"
SXHKD_BUILD_DEPS="libxcb-keysyms1-dev"
SXHKD_DESCRIPTION="Simple X hotkey daemon"
SXHKD_REPO="https://github.com/baskerville/sxhkd.git"

apt update
apt install -y $SXHKD_BUILD_DEPS

git clone $SXHKD_REPO $SXHKD_BUILD_DIR
cd $SXHKD_BUILD_DIR
VERSION=$(git describe --long)
make

echo $SXHKD_DESCRIPTION > description-pak
checkinstall --pkgname sxhkd \
  --maintainer $MAINTAINER \
  --provides sxhkd \
  --requires "$SXHKD_REQUIRES" \
  --pkgversion $VERSION \
  --pkgrelease ${RELEASE} \
  --nodoc \
  --pkgsource $SXHKD_REPO \
  --pakdir $PACDIR
rm -rf $SXHKD_BUILD_DIR
### END ###
