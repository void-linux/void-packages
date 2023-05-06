#!/bin/sh
#
# This chroot script uses symlinks to emulate being in a chroot using
# the host system as the masterdir
#
# It will damage your host system, only use it in disposable
# containers.
#
# 2 extra steps required when using this chroot-style:
# 1. Symlink / to masterdir inside the void-packages repo
# 2. write the arch of the host system, as dictated by xbps-uhelper arch
# into /.xbps_chroot_init
#
# The supported way to make use of thie chroot-style is to create
# a root filesystem that has base-chroot and git installed and
# have it inside a container engine like Docker.
#
# Docker example:
# $ mkdir -p /tmp/image
# $ xbps-install -y -r /tmp/image \
#				 -R http://mirrors.servercentral.com/voidlinux/current \
#				 -S base-chroot
# $ tar -pC /tmp/image -c . | sudo docker import - voidlinux/masterdir
# $ rm -rf /tmp/image
# # docker run --rm -it \
#			   -e XBPS_CHROOT_CMD=ethereal \
#			   -e XBPS_ALLOW_CHROOT_BREAKOUT=yes \
#			   -v $(pwd):/hostrepo voidlinux/masterdir \
#			   /bin/bash -c 'ln -s / /hostrepo/masterdir && /hostrepo/xbps-src pkg <pkgname>'
#

readonly MASTERDIR="$1"
readonly DISTDIR="$2"
readonly HOSTDIR="$3"
readonly EXTRA_ARGS="$4"
readonly CMD="$5"
shift 5

if [ -z "$MASTERDIR" -o -z "$DISTDIR" ]; then
	echo "$0 MASTERDIR/DISTDIR not set"
	exit 1
fi

msg_red() {
	# error messages in bold/red
	[ -n "$NOCOLORS" ] || printf >&2 "\033[1m\033[31m"
	printf "=> ERROR: %s\\n" "$@" >&2
	[ -n "$NOCOLORS" ] || printf >&2 "\033[m"
}

fake_mount() {
	# If we already have a symlink from the desired place
	# to the base location then just return 0
	if [ -L "$2" -a "$(readlink "$2")" = "$1" ]; then
		return 0
	fi

	if [ -d "$2" ] && ! rmdir "$2" >/dev/null 2>&1; then
		msg_red "Failed to remove $2, not empty ?\n"
		exit 1
	fi

	[ -f "$2" -o -L "$2" ] && rm -f "$2"

	ln -s "$1" "$2"
	echo "linked $2 -> $1"
}

if [ "${XBPS_ALLOW_CHROOT_BREAKOUT}" != "yes" ]; then
	msg_red "chroot-style 'ethereal' requires XBPS_ALLOW_CHROOT_BREAKOUT=yes\n"
	msg_red "This chroot-style is meant for disposable containers and will destroy your system\n"
	exit 1
fi

if [ ! -L "$MASTERDIR" -o "$(readlink "$MASTERDIR")" != "/" ]; then
	msg_red "$MASTERDIR isn't symlinked to /!\n"
	exit 1
fi

fake_mount "$DISTDIR" "$MASTERDIR"/void-packages

# Do the same for hostdir
if [ -n "$HOSTDIR" ]; then
	fake_mount "$HOSTDIR" "$MASTERDIR"/host
fi

# xbps-src may send some other binds, parse them here
while getopts 'b:' c -- "$EXTRA_ARGS"; do
	# Skip everything that's not a bind
	[ "$c" = "b" ] || continue

	from="${OPTARG%:*}"
	to="${OPTARG#*:}"

	fake_mount "$from" "$to"

	mounts="${mounts} $to"
done

# Store current directory for returning later
OLDPWD="$(pwd)"

# To give the illusion we entered the chroot, cd to /
cd / || {
	msg_red "Failed to change directory to root!\n"
	exit 1 ; }

# Tell xbps-src that we are "in the chroot"
# Start with `env` so our environment var's stay the same
env IN_CHROOT=1 $CMD $@

# Store return of the command we care about
ret="$?"

# Return to OLDPWD
cd "${OLDPWD}"

# Remove the symlink and restore an empty dir to simulate
# an umount operation.
if [ -n "$HOSTDIR" ]; then
	rm -f "$MASTERDIR"/host
	mkdir -p "$MASTERDIR"/host
fi

# Same as the operation above, do it all for all mountpoints
# that were passed to us.
for m in $mounts; do
	rm -f "$m"
	mkdir -p "$m"
done

rm -f "$MASTERDIR"/void-packages
mkdir -p "$MASTERDIR"/void-packages

exit $ret
