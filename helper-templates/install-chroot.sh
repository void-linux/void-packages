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

echo "==> Preparing chroot on $XBPS_MASTERDIR... "

if [ ! -f $XBPS_MASTERDIR/.xbps_perms_done ]; then
	chown -R root:root $XBPS_MASTERDIR/*
	chmod +s $XBPS_MASTERDIR/usr/libexec/pt_chown
	cp -af /etc/passwd /etc/shadow /etc/group /etc/hosts $XBPS_MASTERDIR/etc
	touch $XBPS_MASTERDIR/.xbps_perms_done
fi

for f in bin sbin tmp var sys proc dev xbps; do
	[ ! -d $XBPS_MASTERDIR/$f ] && mkdir -p $XBPS_MASTERDIR/$f
done

for f in sys proc dev xbps; do
	if [ ! -f $XBPS_MASTERDIR/.${f}_mount_bind_done ]; then
		echo -n "=> Mounting $f in chroot... "
		if [ "$f" = "xbps" ]; then
			mount -o bind $XBPS_DISTRIBUTIONDIR $XBPS_MASTERDIR/$f
		else
			mount -o bind /$f $XBPS_MASTERDIR/$f
		fi
		if [ $? -eq 0 ]; then
			touch $XBPS_MASTERDIR/.${f}_mount_bind_done
			echo "done."
		else
			echo "failed."
		fi
	fi
done

if [ ! -f $XBPS_MASTERDIR/.xbps_builddir_mount_bind_done ]; then
	[ ! -d $XBPS_MASTERDIR/xbps-builddir ] && mkdir -p \
		$XBPS_MASTERDIR/xbps-builddir
	echo -n "=> Mounting xbps-builddir in chroot... "
	mount -o bind $XBPS_BUILDDIR $XBPS_MASTERDIR/xbps-builddir
	if [ $? -eq 0 ]; then
		touch $XBPS_MASTERDIR/.xbps_builddir_mount_bind_done
		echo "done."
	else
		echo "failed."
	fi
fi

echo "XBPS_DISTRIBUTIONDIR=/xbps" > $XBPS_MASTERDIR/etc/xbps.conf
echo "XBPS_MASTERDIR=/" >> $XBPS_MASTERDIR/etc/xbps.conf
echo "XBPS_DESTDIR=/xbps/packages" >> $XBPS_MASTERDIR/etc/xbps.conf
echo "XBPS_BUILDDIR=/xbps-builddir" >> $XBPS_MASTERDIR/etc/xbps.conf
echo "XBPS_SRCDISTDIR=/xbps/srcdistdir" >> $XBPS_MASTERDIR/etc/xbps.conf
echo "XBPS_CFLAGS=\"$XBPS_CFLAGS\"" >> $XBPS_MASTERDIR/etc/xbps.conf
echo "XBPS_CXXFLAGS=\"\$XBPS_CFLAGS\"" >> $XBPS_MASTERDIR/etc/xbps.conf

install_chroot_pkg()
{
	local pkg="$1"

	[ -z "$pkg" ] && return 1

	echo -n "==> Rebuilding chroot's dynamic linker cache..."
	chroot $XBPS_MASTERDIR /sbin/ldconfig -c /etc/ld.so.conf
	chroot $XBPS_MASTERDIR /sbin/ldconfig -C /etc/ld.so.cache
	echo " done."

	chroot $XBPS_MASTERDIR /xbps/xbps.sh install $pkg
	umount_chroot_fs
}

umount_chroot_fs()
{
	for f in sys proc dev xbps; do
		[ ! -f $XBPS_MASTERDIR/.${f}_mount_bind_done ] && continue
		echo -n "=> Unmounting $f from chroot... "
		umount -f $XBPS_MASTERDIR/$f
		if [ $? -eq 0 ]; then
			rm -f $XBPS_MASTERDIR/.${f}_mount_bind_done
			echo "done."
		else
			echo "failed."
		fi
	done

	if [ -f $XBPS_MASTERDIR/.xbps_builddir_mount_bind_done ]; then
		echo -n "=> Unmounting xbps-builddir from chroot... "
		umount -f $XBPS_MASTERDIR/xbps-builddir
		if [ $? -eq 0 ]; then
			rm -f $XBPS_MASTERDIR/.xbps_builddir_mount_bind_done
			echo "done."
		else
			echo "failed."
		fi
	fi
}
