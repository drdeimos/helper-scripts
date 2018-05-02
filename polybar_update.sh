#!/bin/bash

set -e

if [ -z $1 ]; then
  echo "Please set package dir in first arg. Example: ./polybar_update.sh /build"
  exit
fi

apt update
apt -y upgrade

PACDIR="$1"
MAINTAINER="drdeimosnn@gmail.com"
RELEASE=$(date '+%Y%m%d%H%M%S')

### BUILD BSPWM ###
BUILD_DIR=$(mktemp -d)
REQUIRES="libxcb-xkb1 libxcb-randr0 xcb-proto libxcb-ewmh2 libxcb-icccm4 python-xcbgen libiw30 libxcb-image0 libxcb-util1 libxcb-cursor0"
BUILD_DEPS="cmake libxcb-xkb-dev libxcb-randr0-dev libxcb-render-util0-dev libxcb-icccm4-dev libxcb-ewmh-dev python-xcbgen libiw-dev libasound2-dev libcurl4-openssl-dev pkg-config libcairo2-dev libxcb-image0-dev fontconfig git libxcb-util-dev libpulse-dev libxcb-cursor-dev"
DESCRIPTION="Polybar aims to help users build beautiful and highly customizable status bars for their desktop environment, without the need of having a black belt in shell scripting."
REPO="https://github.com/jaagr/polybar.git"

apt update
apt install -y $BUILD_DEPS $REQUIRES

git clone --recursive $REPO $BUILD_DIR
cd $BUILD_DIR
VERSION=$(git describe --long --tags)
mkdir build
cd build
cmake --prefix=/usr ..
make install
echo $DESCRIPTION > description-pak
checkinstall --pkgname polybar \
  --maintainer $MAINTAINER \
  --provides polybar \
  --requires $(echo $REQUIRES |tr ' ' ',' ) \
  --pkgversion $VERSION \
  --pkgrelease ${RELEASE} \
  --nodoc \
  --pkgsource $REPO \
  --pakdir $PACDIR
rm -rf $BUILD_DIR
cd ~/
### END ###
