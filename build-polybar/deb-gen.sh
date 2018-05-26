#!/bin/bash

set -e

SRCDIR='src'
WORKDIR=$(pwd)

rm -vf *.build *.changes *.dsc *.tar.gz *.tar.xz *.upload

if [ -d ${SRCDIR} ]; then
  cd ${SRCDIR}
  git clean -fd
  git checkout master
  git checkout .
  git pull --recurse-submodules
  git checkout c2ac93db5533d2424e16a399d6777bb4caf2aace
else
  git clone https://github.com/jaagr/polybar.git ${SRCDIR}
  cd ${SRCDIR}
  git submodule update --init --recursive
  git checkout c2ac93db5533d2424e16a399d6777bb4caf2aace
fi

cd ${WORKDIR}
cp -rv debian ${SRCDIR}/.

export VERSION=$(cd src && git describe --tags)
export CODENAME=$(awk -F '=' '/CODENAME/ {print $2}' /etc/lsb-release)
export DATE_RFC=$(date --rfc-2822)

cat debian/changelog.tpl | envsubst | tee -a ${SRCDIR}/debian/changelog

cd ${SRCDIR}
tar -zcpf ../polybar_${VERSION}.orig.tar.gz .

debuild -S

cd ${WORKDIR}
CHANGEFILE=$(find . -name '*changes')
dput ppa:drdeimosnn/survive-on-wm ${CHANGEFILE}
