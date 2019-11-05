#!/bin/sh
#
# install_tools.sh

[ "$XLINT" ] && exit 0

/bin/echo -e '\x1b[32mUpdating etc/conf...\x1b[0m'
echo XBPS_CHROOT_CMD=uchroot >> etc/conf
echo XBPS_MAKEJOBS=4 >> etc/conf
echo XBPS_ALLOW_RESTRICTED=yes >> etc/conf

/bin/echo -e '\x1b[32mEnabling ethereal chroot-style...\x1b[0m'
echo XBPS_CHROOT_CMD=ethereal >> etc/conf
echo XBPS_ALLOW_CHROOT_BREAKOUT=yes >> etc/conf

/bin/echo -e '\x1b[32mLinking / to /masterdir...\x1b[0m'
ln -s / masterdir
