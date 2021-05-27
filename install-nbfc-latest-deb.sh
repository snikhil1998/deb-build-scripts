#!/bin/bash

NBFC_LATEST=$(curl --silent "https://api.github.com/repos/hirschmann/nbfc/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')

if [[ $NBFC_LATEST = $(git describe --tags) && -f nbfc-$NBFC_LATEST.deb ]] ; then
    echo "NBFC already up to date."
    exit
fi

git pull origin $NBFC_LATEST

chmod +x build.sh
./build.sh

rm -rf nbfc-$(git describe --tags)*

mkdir -p nbfc-$NBFC_LATEST/DEBIAN/ nbfc-$NBFC_LATEST/opt/nbfc/ nbfc-$NBFC_LATEST/etc/systemd/system/

cp -r Linux/bin/Release/* nbfc-$NBFC_LATEST/opt/nbfc/
cp Linux/nbfc.service Linux/nbfc-sleep.service nbfc-$NBFC_LATEST/etc/systemd/system/

# Uncomment and edit the following line if custom configs are needed.
#cp ~/Downloads/HP_OMEN_Laptop_15-en0xxx.xml nbfc-$NBFC_LATEST/opt/nbfc/Configs/

cat <<EOF | tee nbfc-$NBFC_LATEST/DEBIAN/control
Package: nbfc
Version: $NBFC_LATEST
Architecture: all
Maintainer: Nikhil Sairam Reddy S
Depends: mono-complete
Priority: optional
Description: Cross-platform fan control service for notebooks.
EOF

cat <<EOF | tee nbfc-$NBFC_LATEST/DEBIAN/postinst
#!/bin/bash

mono /opt/nbfc/nbfc.exe config -a "HP_OMEN_Laptop_15-en0xxx"
mono /opt/nbfc/nbfc.exe set -a
systemctl enable --now nbfc
EOF

cat <<EOF | tee nbfc-$NBFC_LATEST/DEBIAN/prerm
#!/bin/bash

systemctl disable nbfc
systemctl stop nbfc
EOF

chmod 755 nbfc-$NBFC_LATEST/DEBIAN/postinst nbfc-$NBFC_LATEST/DEBIAN/prerm #nbfc-$NBFC_LATEST/DEBIAN/postrm

dpkg-deb --build nbfc-$NBFC_LATEST/

sudo dpkg -i nbfc-$NBFC_LATEST.deb
