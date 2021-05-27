#!/bin/bash

RYZENADJ_LATEST=$(curl --silent "https://api.github.com/repos/FlyGoat/RyzenAdj/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")' | sed -E 's/v//')

if [[ $RYZENADJ_LATEST = $(git describe --tags | sed -E 's/v//') && -f ryzenadj-$RYZENADJ_LATEST.deb ]] ; then
    echo "RyzenAdj already up to date."
    exit
fi

git pull origin "v$RYZENADJ_LATEST"

rm -rf build/ ryzenadj-$(git describe --tags | sed -E 's/v//')*

mkdir -p build && cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make
cd ..

mkdir -p ryzenadj-$RYZENADJ_LATEST/DEBIAN/ ryzenadj-$RYZENADJ_LATEST/usr/local/bin/

cp build/libryzenadj.so build/ryzenadj ryzenadj-$RYZENADJ_LATEST/usr/local/bin/

cat <<EOF | tee ryzenadj-$RYZENADJ_LATEST/DEBIAN/control
Package: ryzenadj
Version: $(echo $RYZENADJ_LATEST | sed -E 's/v//')
Architecture: all
Maintainer: Nikhil Sairam Reddy S
Priority: optional
Description: Adjust power management settings for Ryzen Mobile Processors.
EOF

dpkg-deb --build ryzenadj-$RYZENADJ_LATEST/

sudo dpkg -i ryzenadj-$RYZENADJ_LATEST.deb
