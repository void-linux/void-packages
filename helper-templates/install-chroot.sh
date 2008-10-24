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

if [ ! -f $XBPS_MASTERDIR/.xbps_perms_done ]; then
	echo "==> Preparing chroot on $XBPS_MASTERDIR... "
	chown -R root:root $XBPS_MASTERDIR/*
	chmod +s $XBPS_MASTERDIR/usr/libexec/pt_chown
	cp -af /etc/passwd /etc/shadow /etc/group /etc/hosts $XBPS_MASTERDIR/etc
	touch $XBPS_MASTERDIR/.xbps_perms_done
else
	echo "==> Entering into the chroot on $XBPS_MASTERDIR..."
fi

for f in bin sbin tmp var sys proc dev xbps xbps_builddir xbps_destdir; do
	[ ! -d $XBPS_MASTERDIR/$f ] && mkdir -p $XBPS_MASTERDIR/$f
done
unset f

for f in sys proc dev xbps xbps_builddir xbps_destdir; do
	if [ ! -f $XBPS_MASTERDIR/.${f}_mount_bind_done ]; then
		echo -n "=> Mounting $f in chroot... "
		local blah=
		case $f in
			xbps) blah=$XBPS_DISTRIBUTIONDIR;;
			xbps_builddir) blah=$XBPS_BUILDDIR;;
			xbps_destdir) blah=$XBPS_DESTDIR;;
			*) blah=/$f;;
		esac
		mount --bind $blah $XBPS_MASTERDIR/$f
		if [ $? -eq 0 ]; then
			touch $XBPS_MASTERDIR/.${f}_mount_bind_done
			echo "done."
		else
			echo "failed."
		fi
	fi
done
unset f

echo "XBPS_DISTRIBUTIONDIR=/xbps" > $XBPS_MASTERDIR/etc/xbps.conf
echo "XBPS_MASTERDIR=/" >> $XBPS_MASTERDIR/etc/xbps.conf
echo "XBPS_DESTDIR=/xbps_destdir" >> $XBPS_MASTERDIR/etc/xbps.conf
echo "XBPS_BUILDDIR=/xbps_builddir" >> $XBPS_MASTERDIR/etc/xbps.conf
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
	echo "==> Exiting from the chroot on $XBPS_MASTERDIR..."
}

umount_chroot_fs()
{
	local fs=
	local dir=

	for fs in sys proc dev xbps xbps_builddir xbps_destdir; do
		[ ! -f $XBPS_MASTERDIR/.${fs}_mount_bind_done ] && continue
		echo -n "=> Unmounting $fs from chroot... "
		umount -f $XBPS_MASTERDIR/$fs
		if [ $? -eq 0 ]; then
			rm -f $XBPS_MASTERDIR/.${fs}_mount_bind_done
			echo "done."
		else
			echo "failed."
		fi
		unset fs
	done

	for dir in xbps xbps_builddir xbps_destdir; do
		[ -d $XBPS_MASTERDIR/$dir ] && rmdir $XBPS_MASTERDIR/$dir
	done
}
