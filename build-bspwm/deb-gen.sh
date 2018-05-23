#!/bin/bash

SRCDIR='src'
WORKDIR=$(pwd)

rm -vf *.build *.changes *.dsc *.tar.gz *.tar.xz *.upload

if [ -d ${SRCDIR} ]; then
  cd ${SRCDIR}
  git clean -fd
  git checkout .
  git checkout master
  git pull
else
  git clone https://github.com/baskerville/bspwm.git ${SRCDIR}
fi

cd ${WORKDIR}
cp -rv debian ${SRCDIR}/.

export VERSION=$(cd src && git describe --long)
export CODENAME=$(awk -F '=' '/CODENAME/ {print $2}' /etc/lsb-release)
export RELEASE=$(date '+%Y%m%d%H%M%S')
export DATE_RFC=$(date --rfc-2822)

cat debian/changelog.tpl | envsubst | tee -a ${SRCDIR}/debian/changelog

cd ${SRCDIR}
tar -zcpf ../bspwm_${VERSION}.orig.tar.gz .

export PREFIX=/usr
debuild -S
