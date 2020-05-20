#!/bin/sh
#
# This hook removes reference to $XBPS_CROSS_BASE in
# /usr/{lib,share}/pkgconfig/*.pc

if [ -z "$CROSS_BUILD" ]; then
	return 0
fi
for f in "$PKGDESTDIR"/usr/lib/pkgconfig/*.pc \
	"$PKGDESTDIR"/usr/share/pkgconfig/*.pc
do
	if [ -f "$f" ]; then
		# Sample sed script
		# s,/usr/armv7l-linux-musleabihf/,/,g
		# trailing / to avoid clashing with other $XBPS_CROSS_BASE and
		# $XBPS_CROSS_TRIPLET reference.
		sed -i -e "s,$XBPS_CROSS_BASE/,/,g" "$f"
	fi
done
