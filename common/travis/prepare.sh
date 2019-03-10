#!/bin/sh
#
# install_tools.sh

mkdir -p $HOME/bin

/bin/echo -e '\x1b[32mInstalling xbps...\x1b[0m'
wget -q -O - http://alpha.de.repo.voidlinux.org/static/xbps-static-latest.x86_64-musl.tar.xz | \
	unxz | tar x -C $HOME/bin --wildcards "./usr/bin/xbps-*" \
	--strip-components=3 || exit 1

sudo chown root $HOME/bin/xbps-uchroot
sudo chmod u+s $HOME/bin/xbps-uchroot

/bin/echo -e '\x1b[32mInstalling xtools...\x1b[0m'
wget -q -O - https://github.com/chneukirchen/xtools/archive/master.tar.gz | \
	gunzip | tar x -C $HOME/bin --wildcards "xtools-master/x*" \
	--strip-components=1 || exit 1

/bin/echo -e '\x1b[32mUpdating etc/conf...\x1b[0m'
echo XBPS_CHROOT_CMD=uchroot >> etc/conf
echo XBPS_MAKEJOBS=4 >> etc/conf
echo XBPS_ALLOW_RESTRICTED=yes >> etc/conf
