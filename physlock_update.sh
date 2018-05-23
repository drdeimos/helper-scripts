#!/bin/bash

# Author: Mikhail Nosov (drdeimosnn@gmail.com)
# Build package physlock with checkinstall for ubuntu 16.04
# physlock: https://github.com/muennich/physlock.git
#
# Requirements:
# * Packages: build-essential, checkinstall, fakeroot, gcc

set -e

if [ -z $1 ]; then
  echo "Please set package dir in first arg. Example: ./physlock_update.sh /build"
  exit
fi

apt update
apt -y upgrade

PACDIR="$1"
MAINTAINER="drdeimosnn@gmail.com"
RELEASE="$(awk -F '=' '/CODENAME/ {print $2}' /etc/lsb-release)-$(date '+%Y%m%d%H%M%S')"
COMMON_BUILD_DEPS="git make gcc checkinstall"

### BUILD ###
BUILD_DIR=$(mktemp -d)
REQUIRES="libaudit1,libc6,libpam0g"
BUILD_DEPS="libpam0g-dev"
DESCRIPTION="Control physical access to a linux computer by locking all of its virtual terminals."
REPO="https://github.com/muennich/physlock.git"

apt update
apt install -y ${COMMON_BUILD_DEPS} $BUILD_DEPS

git clone $REPO $BUILD_DIR
cd $BUILD_DIR
VERSION=$(git describe --long | sed 's/^v//')
make
echo $DESCRIPTION > description-pak
checkinstall --pkgname physlock \
  --maintainer $MAINTAINER \
  --provides physlock \
  --requires "$REQUIRES" \
  --pkgversion $VERSION \
  --pkgrelease ${RELEASE} \
  --nodoc \
  --pkgsource $REPO \
  --pakdir $PACDIR \
  make install PREFIX="/usr"
rm -rf $BUILD_DIR
cd ~/
### END ###
