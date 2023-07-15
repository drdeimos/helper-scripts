#!/bin/bash

# Author: Mikhail Nosov (drdeimosnn@gmail.com)
# Build libvirt package from source

if [ ! -f "$1" ]; then
  echo 'Please enter qemu source tar.xz file as 1st arg'
  exit
fi

LDIR=$(mktemp -d)

tar -xf $1 -C $LDIR
LVERSION=$(ls -1 $LDIR | sed 's/libvirt-//')
cd $LDIR/libvirt-${LVERSION}
./autogen.sh --prefix=/usr --with-apparmor --with-blkid --with-numactl --with-apparmor-profiles --with-qemu-user=libvirt-qemu --with-qemu-group=libvirtd

make

echo 'Programs for the libvirt library' > description-pak
sudo checkinstall --pkgname libvirt-bin \
  --maintainer 'drdeimosnn@gmail.com' \
  --provides 'libvirt-bin, libvirt0' \
  --requires 'libapparmor1,libasn1-8-heimdal,libaudit1,libavahi-client3,libavahi-common3,libblkid1,libc6,libcap-ng0,libcomerr2,libcomerr2,libcurl3-gnutls,libdbus-1-3,libdevmapper1.02.1,libffi6,libgcc1,libgcrypt20,libgmp10,libgnutls30,libgpg-error0,libgssapi3-heimdal,libgssapi-krb5-2,libhcrypto4-heimdal,libheimbase1-heimdal,libheimntlm0-heimdal,libhogweed4,libhx509-5-heimdal,libicu55,libidn11,libk5crypto3,libkeyutils1,libkrb5-26-heimdal,libkrb5-3,libkrb5-3,libkrb5support0,libldap-2.4-2,liblzma5,libnettle6,libnl-3-200,libnuma1,libp11-kit0,libpciaccess0,libpcre3,libreadline6,libroken18-heimdal,librtmp1,libsasl2-2,libselinux1,libsqlite3-0,libstdc++6,libsystemd0,libtasn1-6,libtinfo5,libudev1,libuuid1,libwind0-heimdal,libxen-4.6,libxenstore3.0,libxml2,libyajl2,zlib1g' \
  --pkgversion $LVERSION \
  --nodoc \
  --pkgsource $1 \
  --pakdir '/home/drdeimos/Build/pkgs'

rm -rf ${LDIR}
