#
# Helper to install packages into a sandbox in masterdir.
# Actually this needs the xbps-base-chroot package installed.
#

# Umount stuff if SIGINT or SIGQUIT was caught
trap umount_chroot_fs INT QUIT

check_installed_pkg xbps-base-chroot 0.1
if [ $? -ne 0 ]; then
	echo "*** ERROR: xbps-base-chroot pkg not installed ***"
	exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
	echo "*** ERROR: you must be root to use this target ***"
	exit 1
fi

echo -n "=> Preparing sandbox on $XBPS_MASTERDIR... "

if [ ! -x $XBPS_MASTERDIR/bin/sh ]; then
	cd $XBPS_MASTERDIR/bin && ln -s bash sh
fi

if [ ! -f $XBPS_MASTERDIR/.xbps_perms_done ]; then
	chown -R root:root $XBPS_MASTERDIR/*
	chmod +s $XBPS_MASTERDIR/usr/libexec/pt_chown
	cp -af /etc/passwd /etc/shadow /etc/group /etc/hosts $XBPS_MASTERDIR/etc
	touch $XBPS_MASTERDIR/.xbps_perms_done
fi

if [ ! -h $XBPS_MASTERDIR/usr/bin/cc ]; then
	cd $XBPS_MASTERDIR/usr/bin && ln -s gcc cc
fi

for f in bin sbin tmp var sys proc dev xbps; do
	[ ! -d $XBPS_MASTERDIR/$f ] && mkdir -p $XBPS_MASTERDIR/$f
done

for f in sys proc dev; do
	if [ ! -f $XBPS_MASTERDIR/.${f}_mount_bind_done ]; then
		mount -o bind /$f $XBPS_MASTERDIR/$f
		[ $? -eq 0 ] && touch $XBPS_MASTERDIR/.${f}_mount_bind_done
	fi
done

if [ ! -f $XBPS_MASTERDIR/.xbps_mount_bind_done ]; then
	mount -o bind $XBPS_DISTRIBUTIONDIR $XBPS_MASTERDIR/xbps
	[ $? -eq 0 ] && touch $XBPS_MASTERDIR/.xbps_mount_bind_done
fi

if [ ! -f $XBPS_MASTERDIR/.xbps_builddir_mount_bind_done ]; then
	[ ! -d $XBPS_MASTERDIR/xbps-builddir ] && mkdir -p \
		$XBPS_MASTERDIR/xbps-builddir
	mount -o bind $XBPS_BUILDDIR $XBPS_MASTERDIR/xbps-builddir
	[ $? -eq 0 ] && touch $XBPS_MASTERDIR/.xbps_builddir_mount_bind_done
fi

echo "XBPS_DISTRIBUTIONDIR=/xbps" > $XBPS_MASTERDIR/etc/xbps.conf
echo "XBPS_MASTERDIR=/" >> $XBPS_MASTERDIR/etc/xbps.conf
echo "XBPS_DESTDIR=/xbps/packages" >> $XBPS_MASTERDIR/etc/xbps.conf
echo "XBPS_BUILDDIR=/xbps-builddir" >> $XBPS_MASTERDIR/etc/xbps.conf
echo "XBPS_SRCDISTDIR=/xbps/srcdistdir" >> $XBPS_MASTERDIR/etc/xbps.conf
echo "XBPS_CFLAGS=\"$XBPS_CFLAGS\"" >> $XBPS_MASTERDIR/etc/xbps.conf
echo "XBPS_CXXFLAGS=\"\$XBPS_CFLAGS\"" >> $XBPS_MASTERDIR/etc/xbps.conf

echo "done."

install_chroot_pkg()
{
	local pkg="$1"

	[ -z "$pkg" ] && return 1

	echo -n "=> Rebuilding dynamic linker's cache..."
	chroot $XBPS_MASTERDIR /sbin/ldconfig -c /etc/ld.so.conf
	chroot $XBPS_MASTERDIR /sbin/ldconfig -C /etc/ld.so.cache
	echo " done."

	chroot $XBPS_MASTERDIR /xbps/xbps.sh install $pkg
	umount_chroot_fs
}

umount_chroot_fs()
{
	for f in sys proc dev xbps xbps-builddir; do
		umount $XBPS_MASTERDIR/$f
	done

	rm -f $XBPS_MASTERDIR/.xbps_builddir_mount_bind_done
	rm -f $XBPS_MASTERDIR/.xbps_mount_bind_done
	rm -f $XBPS_MASTERDIR/.sys_mount_bind_done
	rm -f $XBPS_MASTERDIR/.dev_mount_bind_done
	rm -f $XBPS_MASTERDIR/.proc_mount_bind_done
}
