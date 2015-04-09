#!/bin/sh
#
# install_tools.sh

mkdir -p $HOME/bin

/bin/echo -e '\x1b[32mInstalling proot...\x1b[0m'
wget -q http://static.proot.me/proot-x86_64
install -m 755 proot-x86_64 $HOME/bin/proot || exit 1

/bin/echo -e '\x1b[32mInstalling xbps...\x1b[0m'
wget -q -O - http://repo.voidlinux.eu/static/xbps-static-latest.x86_64-musl.tar.xz | \
	unxz | tar x -C $HOME/bin --wildcards "./usr/sbin/xbps-*" \
	--strip-components=3 || exit 1

/bin/echo -e '\x1b[32mInstalling xtools...\x1b[0m'
wget -q -O - https://github.com/chneukirchen/xtools/archive/master.tar.gz | \
	gunzip | tar x -C $HOME/bin --wildcards "xtools-master/x*" \
	--strip-components=1 || exit 1

/bin/echo -e '\x1b[32mUpdating etc/conf...\x1b[0m'
echo XBPS_CHROOT_CMD=proot >> etc/conf
