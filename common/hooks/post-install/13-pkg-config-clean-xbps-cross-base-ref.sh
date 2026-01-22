# This hook removes reference to $XBPS_CROSS_BASE in
# /usr/{lib,share}/pkgconfig/*.pc
#
# We don't touch /usr/bin/*-config since there're other information that
# references $XBPS_CROSS_BASE

hook() {
	if [ -z "$CROSS_BUILD" ]; then
		return 0
	fi
	for f in "$PKGDESTDIR"/usr/lib/pkgconfig/*.pc \
		"$PKGDESTDIR"/usr/share/pkgconfig/*.pc
	do
		if [ -f "$f" ]; then
			# Sample sed script
			# s,/usr/armv7l-linux-musleabihf/usr,/usr,g
			# trailing /usr to avoid clashing with
			# other $XBPS_CROSS_BASE and $XBPS_CROSS_TRIPLET.
			sed -i --follow-symlinks \
				-e "s,$XBPS_CROSS_BASE/usr,/usr,g" "$f"
		fi
	done
}
