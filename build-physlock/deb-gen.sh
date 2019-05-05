#!/bin/bash

set -e

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
    git clean -fd
    git checkout .
    git checkout master
    git pull
  else
    git clone https://github.com/muennich/physlock.git ${SRCDIR}
  fi

  cd ${WORKDIR}
  cp -rv debian ${SRCDIR}/.

  export VERSION=$(cd src && git describe --long | sed 's/^v//')
  export DATE_RFC=$(date --rfc-2822)

  cat debian/changelog.tpl | envsubst | tee -a ${SRCDIR}/debian/changelog
  echo ${VERSION} > ${SRCDIR}/VERSION

  cd ${SRCDIR}
  make clean
  tar -Jcp \
    --exclude='.git' \
    --exclude='./debian' \
    -f ../physlock_${VERSION}.orig.tar.xz .

  export PREFIX=/usr
  debuild -S

  cd ${WORKDIR}
  CHANGEFILE=$(find . -name '*changes')
  dput ppa:drdeimosnn/survive-on-wm ${CHANGEFILE}
}

# main
BUILD_FOR="xenial bionic"
for CODENAME in $BUILD_FOR; do
  build ${CODENAME}
  clean
done
