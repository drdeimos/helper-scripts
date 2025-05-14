#!/bin/bash

set -xe

SRCDIR='src'
WORKDIR=$(pwd)
export RELEASE_NUM=${1:-1}

function clean {
  cd ${WORKDIR}
  rm -vf *.build *.changes *.dsc *.tar.gz *.tar.xz *.upload *.buildinfo
}

function build {
  export CODENAME=${1}

  cd ${WORKDIR}
  if [ -d ${SRCDIR} ]; then
    cd ${SRCDIR}
    git clean -fdx
    git checkout .
    git submodule foreach --recursive git clean -fdx
    git submodule foreach --recursive git checkout .
    git checkout wayland
    git pull
  else
    git clone https://github.com/lbonn/rofi ${SRCDIR}
    cd ${SRCDIR}
    git submodule update --init
    git checkout wayland
    git pull
  fi

  cd ${WORKDIR}
  if [ -d "debian-${CODENAME}" ]; then
    rsync -rLptgoDAXv "debian-${CODENAME}/" "${SRCDIR}/debian"
  else
    rsync -rLptgoDAXv debian-default/ "${SRCDIR}/debian"
  fi

  export VERSION="$(cd src && git describe --long --tags | sed 's/^v//')-${RELEASE_NUM}"
  export DATE_RFC=$(date --rfc-2822)

  cat ${SRCDIR}/debian/changelog.tpl | envsubst | tee -a ${SRCDIR}/debian/changelog

  cd ${SRCDIR}
  git submodule update --init --recursive

  if [ ! -f "../rofi-wayland_${VERSION}.orig.tar.xz" ]; then
    tar -Jcp \
      --exclude='.git' \
      --exclude='./debian' \
      -f ../rofi-wayland_${VERSION}.orig.tar.xz .
  fi

  debuild -S --no-check-builddeps
  #debuild -b --no-check-builddeps
}

function release {
  cd ${WORKDIR}
  CHANGEFILES=$(find . -maxdepth 1 -name '*changes')
  for FILE in ${CHANGEFILES};do
    dput ppa:drdeimosnn/survive-on-wm ${FILE}
  done
}

# main
BUILD_FOR="jammy noble"
for CODENAME in $BUILD_FOR; do
  build ${CODENAME}
done

release
clean
