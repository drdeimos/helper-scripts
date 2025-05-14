#!/bin/bash

set -e

SRCDIR='src'
WORKDIR=$(pwd)
export RELEASE_NUM=${1:-1}

function clean {
  cd ${WORKDIR}
  rm -vf *.build *.changes *.dsc *.tar.gz *.tar.xz *.upload
}

function build {
  export CODENAME=${1}

  cd ${WORKDIR}
  if [ -d ${SRCDIR} ]; then
    cd ${SRCDIR}
    git clean -fd
    git checkout .
    git checkout master
    git pull
  else
    git clone https://git.suckless.org/dmenu ${SRCDIR}
  fi

  cd ${WORKDIR}
  cp -rv debian ${SRCDIR}/.

  export VERSION="$(cd src && git describe --long --tags | sed 's/^v//')-${RELEASE_NUM}"
  export DATE_RFC=$(date --rfc-2822)

  cat debian/changelog.tpl | envsubst | tee -a ${SRCDIR}/debian/changelog
  sed -i "s/VERSION_CHANGEME/${VERSION}/g" ${SRCDIR}/debian/patches/0001-Fix-PATH-and-VERSION.patch

  cd ${SRCDIR}
  make clean
  if [ ! -f "../dmenu_${VERSION}.orig.tar.xz" ]; then
    tar -Jcp \
      --exclude='.git' \
      --exclude='./debian' \
      -f ../dmenu_${VERSION}.orig.tar.xz .
  fi

  debuild -S
}

function release {
  cd ${WORKDIR}
  CHANGEFILES=$(find . -maxdepth 1 -name '*changes')
  for FILE in ${CHANGEFILES};do
    dput ppa:drdeimosnn/survive-on-wm ${FILE}
  done
}

# main
BUILD_FOR="focal jammy noble"
for CODENAME in $BUILD_FOR; do
  build ${CODENAME}
done

release
clean
