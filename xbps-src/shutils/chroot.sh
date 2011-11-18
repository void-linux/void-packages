#-
# Copyright (c) 2008-2011 Juan Romero Pardines.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#-

_mount()
{
	MASTERDIR="${XBPS_MASTERDIR}" DISTRIBUTIONDIR="${XBPS_DISTRIBUTIONDIR}" \
		HOSTDIR="${XBPS_HOSTDIR}" XBPS_ETCDIR="${XBPS_ETCDIR}" \
		XBPS_SHAREDIR="${XBPS_SHAREDIR}" ${SUDO_CMD} \
		${XBPS_LIBEXECDIR}/chroot-helper.sh mount
	return $?
}

_umount()
{
	MASTERDIR="${XBPS_MASTERDIR}" DISTRIBUTIONDIR="${XBPS_DISTRIBUTIONDIR}" \
		HOSTDIR="${XBPS_HOSTDIR}" XBPS_ETCDIR="${XBPS_ETCDIR}" \
		XBPS_SHAREDIR="${XBPS_SHAREDIR}" ${SUDO_CMD} \
		${XBPS_LIBEXECDIR}/chroot-helper.sh umount
	return $?
}

chroot_init()
{
	trap "_umount && return $?" 0 INT QUIT TERM

	[ -n "$bootstrap" ] && return 0

	if [ "${CHROOT_CMD}" = "chroot" ]; then
		if [ "$(id -u)" -ne 0 ]; then
			msg_error "Root permissions are required for the chroot, try again."
		fi
	fi

	check_installed_pkg base-chroot-0.11
	if [ $? -ne 0 ]; then
		echo "${XBPS_MASTERDIR} has not been prepared for chroot operations."
		echo "Please install 'base-chroot>=0.11' and try again."
		exit 1
	fi

	msg_normal "Entering into the chroot on $XBPS_MASTERDIR.\n"

	if [ ! -d $XBPS_MASTERDIR/usr/local/etc ]; then
		mkdir -p $XBPS_MASTERDIR/usr/local/etc
	fi

	XBPSSRC_CF=$XBPS_MASTERDIR/usr/local/etc/xbps/xbps-src.conf

	cat > $XBPSSRC_CF <<_EOF
# Generated configuration file by xbps-src, DO NOT EDIT!
XBPS_DISTRIBUTIONDIR=/xbps
XBPS_MASTERDIR=/
XBPS_CFLAGS="$XBPS_CFLAGS"
XBPS_CXXFLAGS="$XBPS_CFLAGS"
XBPS_LDFLAGS="$XBPS_LDFLAGS"
XBPS_FETCH_CMD="xbps-uhelper.static fetch"
XBPS_COMPRESS_CMD="$XBPS_COMPRESS_CMD"
_EOF

	if [ -n "$XBPS_MAKEJOBS" ]; then
		echo "XBPS_MAKEJOBS=$XBPS_MAKEJOBS" >> $XBPSSRC_CF
	fi
	if [ -n "$XBPS_PREFER_BINPKG_DEPS" ]; then
		echo "XBPS_PREFER_BINPKG_DEPS=$XBPS_PREFER_BINPKG_DEPS" >> $XBPSSRC_CF
	fi
	if [ -n "$XBPS_COMPRESS_LEVEL" ]; then
		echo "XBPS_COMPRESS_LEVEL=$XBPS_COMPRESS_LEVEL" >> $XBPSSRC_CF
	fi
	if [ -n "$XBPS_HOSTDIR" ]; then
		echo "XBPS_HOSTDIR=/host" >> $XBPSSRC_CF
	fi
	if [ -n "$XBPS_CCACHE" ]; then
		echo "XBPS_CCACHE=$XBPS_CCACHE" >> $XBPSSRC_CF
	fi
	echo "# End of configuration file." >> $XBPSSRC_CF

	if [ -d $XBPS_MASTERDIR/tmp ]; then
		if [ ! -f $XBPS_MASTERDIR/.xbps_mount_bind_done ]; then
			msg_normal "Cleaning up /tmp...\n"
			[ -h ${XBPS_MASTERDIR}/tmp ] || rm -rf $XBPS_MASTERDIR/tmp/*
		fi
	fi

	# Create custom script to start the chroot bash shell.
	cat > $XBPS_MASTERDIR/bin/xbps-shell <<_EOF
#!/bin/sh

. /usr/local/etc/xbps/xbps-src.conf
. /usr/local/share/xbps-src/shutils/init_funcs.sh
set_defvars

PATH=/tools/bin:/usr/local/sbin:/bin:/usr/bin:/sbin
PATH=\$PATH:/usr/local/bin:/usr/lib/perl5/core_perl/bin
export PATH

exec env PS1="[\u@masterdir-chroot \W]$ " /bin/bash
_EOF
	chmod 755 $XBPS_MASTERDIR/bin/xbps-shell
}

prepare_chroot()
{
	local f

	# Create some required files.
	cp -f /etc/mtab $XBPS_MASTERDIR/etc
	cp -f /etc/resolv.conf $XBPS_MASTERDIR/etc
	[ -f /etc/localtime ] && cp -f /etc/localtime $XBPS_MASTERDIR/etc

	for f in run/utmp log/btmp log/lastlog log/wtmp; do
		touch -f $XBPS_MASTERDIR/var/$f
	done
	for f in run/utmp log/lastlog; do
		chmod 644 $XBPS_MASTERDIR/var/$f
	done
	[ ! -d $XBPS_MASTERDIR/boot ] && mkdir -p $XBPS_MASTERDIR/boot

	cat > $XBPS_MASTERDIR/etc/passwd <<_EOF
root:x:0:0:root:/root:/bin/bash
nobody:x:99:99:Unprivileged User:/dev/null:/bin/false
$(whoami):x:$(id -u):$(id -g):$(whoami) user:/dev/null:/bin/bash
_EOF

	# Default group list as specified by LFS.
	cat > $XBPS_MASTERDIR/etc/group <<_EOF
root:x:0:
bin:x:1:
sys:x:2:
kmem:x:3:
wheel:x:4:
tty:x:5:
tape:x:6:
daemon:x:7:
floppy:x:8:
disk:x:9:
lp:x:10:
dialout:x:11:
audio:x:12:
video:x:13:
utmp:x:14:
usb:x:15:
cdrom:x:16:
optical:x:17:
mail:x:18:
storage:x:19:
scanner:x:20:
nogroup:x:99:
users:x:1000:
$(whoami):x:$(id -g):
_EOF

	# Default file as in Ubuntu.
	cat > $XBPS_MASTERDIR/etc/hosts <<_EOF
127.0.0.1	xbps	localhost.localdomain	localhost
127.0.1.1	xbps

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
_EOF

	create_binsh_symlink

	touch $XBPS_MASTERDIR/.xbps_perms_done
}

create_binsh_symlink()
{
	if [ ! -h $XBPS_MASTERDIR/bin/sh ]; then
		cd $XBPS_MASTERDIR/bin
		if [ -x bash ]; then
			ln -sf bash sh
		elif [ -x dash ]; then
			ln -sf dash sh
		elif [ -x busybox ]; then
			ln -sf busybox sh
		else
			msg_error "cannot find a suitable shell for chroot!\n"
		fi

	fi
}

prepare_binpkg_repos()
{
	local repo CONF_FILE

	case "${XBPS_VERSION}" in
	0.1[0-9].[0-9]*)
		mkdir -p ${XBPS_MASTERDIR}/usr/local/etc/xbps
		for f in /etc /usr/local/etc; do
			for conf in conf repositories; do
				if [ ! -f $XBPS_MASTERDIR/usr/local/etc/xbps/${conf}.plist ]; then
					[ -d $f ] && cp -f $f/xbps/${conf}.plist \
						${XBPS_MASTERDIR}/usr/local/etc/xbps
				fi
			done
		done
		msg_normal "Synchronizing index for remote repositories...\n"
		${XBPS_REPO_CMD} sync 2>/dev/null
		;;
	0.[89].[0-9]*)
		CONF_FILE=$XBPS_MASTERDIR/usr/local/etc/xbps-conf.plist
		for f in /etc /usr/local/etc; do
			if [ -f $f/xbps-conf.plist -a \
			   ! -f $CONF_FILE ]; then
				cp -f $f/xbps-conf.plist \
					${XBPS_MASTERDIR}/usr/local/etc
			fi
		done
		# XBPS utils >= 0.9.0.
		msg_normal "Synchronizing index for remote repositories...\n"
		${XBPS_REPO_CMD} sync
		;;
	*)
		for repo in ${XBPS_REPO_LIST}; do
			${XBPS_REPO_CMD} add ${repo} 2>/dev/null
			[ $? -ne 0 ] && \
				msg_warn "Failed to sync pkg-index from ${repo}\n"
		done
		;;
	esac
}

create_busybox_links()
{
	local lbindir=$XBPS_MASTERDIR/usr/local/bin

	[ ! -d ${lbindir} ] && mkdir -p ${lbindir}

	# Create other symlinks in /usr/local/bin
	cd ${lbindir} || return 1

	for f in $(${XBPS_MASTERDIR}/bin/busybox --list); do
		if [ "$f" = "tar" -o "$f" = "sh" -o "$f" = "xz" ]; then
			continue
		fi
		ln -sf ../../../bin/busybox $f
	done
}

install_xbps_utils()
{
	local needed _cmd
	local xbps_prefix=$XBPS_MASTERDIR/usr/local

	if [ ! -f ${XBPS_MASTERDIR}/.xbps_utils_done ]; then
		echo "=> Installing static XBPS utils into masterdir."
		for f in bin repo uhelper; do
			_cmd=$(which xbps-${f}.static 2>/dev/null)
			if [ -z "${_cmd}" ]; then
				echo "Unexistent xbps-uhelper.static file!"
				exit 1
			fi
			cp -f ${_cmd} $xbps_prefix/sbin
		done
		touch ${XBPS_MASTERDIR}/.xbps_utils_done
	fi
}

install_xbps_src()
{
	set -e
	install -Dm755 ${XBPS_SBINDIR}/xbps-src \
		${XBPS_MASTERDIR}/usr/local/sbin/xbps-src
	install -Dm755 ${XBPS_LIBEXECDIR}/doinst-helper.sh \
		${XBPS_MASTERDIR}/usr/local/libexec/xbps-src/doinst-helper.sh
	install -d ${XBPS_MASTERDIR}/usr/local/share/xbps-src/shutils
	install -m644 ${XBPS_SHAREDIR}/shutils/*.sh \
		${XBPS_MASTERDIR}/usr/local/share/xbps-src/shutils
	install -d ${XBPS_MASTERDIR}/usr/local/share/xbps-src/common
	install -m644 ${XBPS_SHAREDIR}/common/* \
		${XBPS_MASTERDIR}/usr/local/share/xbps-src/common
	install -d ${XBPS_MASTERDIR}/usr/local/share/xbps-src/helpers
	install -m644 ${XBPS_SHAREDIR}/helpers/*.sh \
		${XBPS_MASTERDIR}/usr/local/share/xbps-src/helpers
	set +e
}

xbps_chroot_handler()
{
	local action="$1" pkg="$2" rv=0 arg

	[ -z "$action" -a -z "$pkg" ] && return 1

	if [ ! -f $XBPS_MASTERDIR/.xbps_perms_done ]; then
		echo -n "==> Preparing chroot on $XBPS_MASTERDIR... "
		prepare_chroot
		echo "done."
	fi

	[ ! -d "$XBPS_MASTERDIR/tmp" ] && mkdir -p "$XBPS_MASTERDIR/tmp"

	chroot_init
	create_binsh_symlink
	create_busybox_links
	install_xbps_utils
	install_xbps_src

	_mount || return $?

	if [ -n "$XBPS_PREFER_BINPKG_DEPS" ]; then
		prepare_binpkg_repos
	fi

	# Update ld.so(8) cache
	msg_normal "Updating ld.so(8) cache...\n"
	${CHROOT_CMD} $XBPS_MASTERDIR sh -c "ldconfig" || return $?

	if [ "$action" = "chroot" ]; then
		env IN_CHROOT=1 LANG=C \
			${CHROOT_CMD} $XBPS_MASTERDIR /bin/xbps-shell || rv=$?
	else
		[ -n "$KEEP_WRKSRC" ] && arg="$arg -C"
		[ -n "$KEEP_AUTODEPS" ] && arg="$arg -K"
		[ -n "$DESTDIR_ONLY_INSTALL" ] && arg="$arg -D"
		[ -n "$BUILD_BINPKG" ] && arg="$arg -B"

		action="$arg $action"
		env in_chroot=1 IN_CHROOT=1 LANG=C _ORIGINPKG="$pkg" \
			${CHROOT_CMD} $XBPS_MASTERDIR sh -c \
			"xbps-src $action $pkg" || rv=$?
	fi

	msg_normal "Exiting from the chroot on $XBPS_MASTERDIR.\n"

	return $rv
}
