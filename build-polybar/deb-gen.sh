#!/bin/bash

set -ex

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
    git checkout master
    git checkout .
    git pull --recurse-submodules
    git submodule update --init --recursive
  else
    git clone https://github.com/jaagr/polybar.git ${SRCDIR}
    cd ${SRCDIR}
    git submodule update --init --recursive
    #git checkout c2ac93db5533d2424e16a399d6777bb4caf2aace
  fi

  cd ${WORKDIR}
  if [ -d "debian-${CODENAME}" ]; then
    cp -rv "debian-${CODENAME}" "${SRCDIR}/debian"
  else
    cp -rv "debian-default" "${SRCDIR}/debian"
  fi

  export VERSION="$(cd src && git describe --tags)-${RELEASE_NUM}"
  export DATE_RFC=$(date --rfc-2822)

  cat "${SRCDIR}/debian/changelog.tpl" | envsubst | tee -a "${SRCDIR}/debian/changelog"

  cd ${SRCDIR}
  tar -Jcp \
    --exclude='.git' \
    --exclude='./debian' \
    -f ../polybar_${VERSION}.orig.tar.xz .

  debuild -S

  cd ${WORKDIR}
  CHANGEFILE=$(find . -name '*changes')
  dput ppa:drdeimosnn/survive-on-wm ${CHANGEFILE}
}

# main
BUILD_FOR="focal jammy"
for CODENAME in $BUILD_FOR; do
  build ${CODENAME}
  clean
done
