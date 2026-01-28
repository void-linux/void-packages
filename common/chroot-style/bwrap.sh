#!/bin/sh
#
# This chroot script uses bubblewrap (see https://github.com/containers/bubblewrap)
#
set -e
readonly MASTERDIR="$1"
readonly DISTDIR="$2"
readonly HOSTDIR="$3"
readonly EXTRA_ARGS="$4"
shift 4

if ! command -v bwrap >/dev/null 2>&1; then
	exit 1
fi

if [ -z "$MASTERDIR" -o -z "$DISTDIR" ]; then
	echo "$0 MASTERDIR/DISTDIR not set"
	exit 1
fi

if [ -z "$XBPS_TEMP_MASTERDIR" ]; then
	exec bwrap --bind "$MASTERDIR" / \
		--ro-bind "$DISTDIR" /void-packages \
		--dev /dev --tmpfs /tmp --proc /proc \
		${HOSTDIR:+--bind "$HOSTDIR" /host} ${EXTRA_ARGS} "$@"
fi

cleanup() {
	[ -z "$tmpdir" ] && return
	chmod -f 755 "${tmpdir}/workdir/work"
	rm -rf "${tmpdir}"
}

trap 'cleanup' EXIT HUP INT QUIT TERM

tmpdir="$(mktemp -d "$(realpath "$MASTERDIR").XXXXXXX")"
[ -z "${tmpdir}" ] && exit 1
mkdir -p "${tmpdir}/masterdir" "${tmpdir}/workdir"

bwrap --overlay-src "$MASTERDIR" \
	--overlay "${tmpdir}/masterdir" "${tmpdir}/workdir" / \
	--ro-bind "$DISTDIR" /void-packages \
	--dev /dev --tmpfs /tmp --proc /proc \
	${HOSTDIR:+--bind "$HOSTDIR" /host} ${EXTRA_ARGS} "$@"
