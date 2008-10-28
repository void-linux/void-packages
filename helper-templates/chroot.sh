#
# Helper to install packages into a sandbox in masterdir.
# Actually this needs the xbps-base-chroot package installed.
#

# Umount stuff if SIGINT or SIGQUIT was caught
trap umount_chroot_fs INT QUIT

[ -n "$base_chroot" ] && return 0

check_installed_pkg xbps-base-chroot 0.1
if [ $? -ne 0 ]; then
	echo "*** ERROR: xbps-base-chroot pkg not installed ***"
	exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
	if [ -z "$base_chroot" ]; then
		echo "*** ERROR: this package must be built inside of the chroot ***"
		exit 1
	fi
	echo "*** ERROR: you must be root to use this target ***"
	exit 1
fi

if [ ! -f $XBPS_MASTERDIR/.xbps_perms_done ]; then
	echo -n "==> Preparing chroot on $XBPS_MASTERDIR... "
	chown -R root:root $XBPS_MASTERDIR/*
	chmod +s $XBPS_MASTERDIR/usr/libexec/pt_chown
	cp -af /etc/passwd /etc/shadow /etc/group /etc/hosts $XBPS_MASTERDIR/etc
	touch $XBPS_MASTERDIR/.xbps_perms_done
	echo "done."
else
	echo "==> Entering into the chroot on $XBPS_MASTERDIR."
fi

REQDIRS="bin sbin tmp var sys proc dev xbps xbps_builddir \
	 xbps_destdir xbps_srcdistdir"
for f in ${REQDIRS}; do
	[ ! -d $XBPS_MASTERDIR/$f ] && mkdir -p $XBPS_MASTERDIR/$f
done
unset f REQDIRS

REQFS="sys proc dev xbps xbps_builddir xbps_destdir xbps_srcdistdir"
for f in ${REQFS}; do
	if [ ! -f $XBPS_MASTERDIR/.${f}_mount_bind_done ]; then
		echo -n "=> Mounting $f in chroot... "
		local blah=
		case $f in
			xbps) blah=$XBPS_DISTRIBUTIONDIR;;
			xbps_builddir) blah=$XBPS_BUILDDIR;;
			xbps_destdir) blah=$XBPS_DESTDIR;;
			xbps_srcdistdir) blah=$XBPS_SRCDISTDIR;;
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
echo "XBPS_SRCDISTDIR=/xbps_srcdistdir" >> $XBPS_MASTERDIR/etc/xbps.conf
echo "XBPS_CFLAGS=\"$XBPS_CFLAGS\"" >> $XBPS_MASTERDIR/etc/xbps.conf
echo "XBPS_CXXFLAGS=\"\$XBPS_CFLAGS\"" >> $XBPS_MASTERDIR/etc/xbps.conf
if [ -n "$XBPS_MAKEJOBS" ]; then
	echo "XBPS_MAKEJOBS=$XBPS_MAKEJOBS" >> $XBPS_MASTERDIR/etc/xbps.conf
fi

rebuild_ldso_cache()
{
	echo -n "==> Rebuilding chroot's dynamic linker cache..."
	chroot $XBPS_MASTERDIR /sbin/ldconfig -c /etc/ld.so.conf
	chroot $XBPS_MASTERDIR /sbin/ldconfig -C /etc/ld.so.cache
	echo " done."
}

chroot_pkg_handler()
{
	local action="$1"
	local pkg="$2"

	[ -z "$action" -o -z "$pkg" ] && return 1

	[ "$action" != "configure" -a "$action" != "build" -a \
	  "$action" != "install" -a "$action" != "chroot" ] && return 1

	rebuild_ldso_cache
	if [ "$action" = "chroot" ]; then
		env in_chroot=yes chroot $XBPS_MASTERDIR /bin/bash
	else
		env in_chroot=yes chroot $XBPS_MASTERDIR /xbps/xbps.sh \
			$action $pkg
	fi
	echo "==> Exiting from the chroot on $XBPS_MASTERDIR."
	umount_chroot_fs
}

umount_chroot_fs()
{
	local fs=
	local dir=

	for fs in ${REQFS}; do
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

	for dir in xbps xbps_builddir xbps_destdir xbps_srcdistdir; do
		[ -d $XBPS_MASTERDIR/$dir ] && rmdir $XBPS_MASTERDIR/$dir
	done
}
