#!/bin/bash

if [ ! -f "$1" ]; then
  echo 'Please enter qemu source tar.bz2 file as 1st arg'
  exit
fi

QDIR=$(mktemp -d)

tar -xf $1 -C $QDIR
QVERSION=$(ls -1 $QDIR | sed 's/qemu-//')
cd $QDIR/qemu-${QVERSION}
mkdir build
cd build
../configure --prefix=/usr --sysconfdir=/etc --docdir=/usr/share/doc/qemu-2.5.0 --target-list=x86_64-softmmu --enable-tcmalloc --disable-sdl --disable-gtk --disable-curses --disable-bluez --enable-kvm --enable-uuid --enable-linux-aio --disable-spice
make


echo 'QEMU full system emulation binaries (x86)' > description-pak
sudo checkinstall --pkgname qemu \
  --maintainer 'drdeimosnn@gmail.com' \
  --provides qemu \
  --requires 'libaio1,libc6,libgcc1,libglib2.0-0,libgoogle-perftools4,liblzma5,libnettle6,libpcre3,libpixman-1-0,libpng12-0,libstdc++6,libunwind8,libuuid1,zlib1g' \
  --pkgversion $QVERSION \
  --nodoc \
  --pkgsource $1 \
  --pakdir '/home/drdeimos/Build/pkgs'

rm -rf ${QDIR}
