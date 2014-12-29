#!/bin/sh
scan_dirs() {
	scanelf -qS "$@" | while read SONAME FILE; do
		TARGET="${FILE##*/}"
		LINK="${FILE%/*}/$SONAME"
		case "$FILE" in
		/lib/*|/usr/lib/*|/usr/local/lib/*) ;;
		*) [ -h "$LINK" -o ! -e "$LINK" ] && ln -sf "$TARGET" "$LINK"
		esac
	done
	return 0
}
# eat ldconfig options
while getopts "nNvXvf:C:r:" opt; do
	:
done
shift $(( $OPTIND - 1 ))
[ $# -gt 0 ] && scan_dirs "$@"
