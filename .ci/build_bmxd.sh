#!/usr/bin/env bash

test ! -d build && mkdir build ; cd build

git clone https://github.com/ddmesh/ffdd-bmxd.git bmxd
cd bmxd || exit 1
#git checkout latest_server
git checkout master

chmod 755 DEBIAN
chmod 555 DEBIAN/*

make

ARCH='amd64'
VERSION="$(awk '/SOURCE_VERSION/ {print $3}' batman.h | head -1 | sed -e 's/^"//' -e 's/"$//' -e 's/-freifunk-dresden//')"
SOURCE_MD5="$(md5sum *.[ch] linux/*.[cp] posix/*.[cp] Makefile | md5sum | cut -d' ' -f1)"
REVISION="${SOURCE_MD5}"

mkdir -p OUT/usr/sbin/
cp bmxd OUT/usr/sbin/
cp -RPfv DEBIAN OUT/

cd OUT
sed -i "s/ARCH/$ARCH/g" DEBIAN/control
sed -i "s/VERSION/$VERSION/g" DEBIAN/control
sed -i "s/REVISION/$REVISION/g" DEBIAN/control
md5sum "$(find . -type f | grep -v '^[.]/DEBIAN/')" > DEBIAN/md5sums

dpkg-deb --build ./ ../../bmxd-"$VERSION"-"$REVISION"_"$ARCH".deb

exit 0
