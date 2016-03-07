# Remove leaked CFLAGS and CXXFLAGS parts which were defined
# by common/hooks/pre-configure/03-timestamp-macros.sh
# from shell scripts, perl scripts, package config files etc.

hook() {
	local f mimetype
	local strip=" -Wno-builtin-macro-redefined -include${XBPS_BUILDDIR}/\.xbps-.*/timestamp-macros\.h"

	[ -n "$XBPS_USE_BUILD_MTIME" ] && return 0
	[ -z "$SOURCE_DATE_EPOCH" ] && return 0

	# Clean up shell scripts, perl files, pkgconfig files etc.
	for f in $(grep -r -l -e "$strip" "$PKGDESTDIR" ); do
		mimetype=$(file --mime-type "$f" | awk '{ print $2 }')
		if [ "$mimetype" == "text/plain" -o "$mimetype" == "text/x-shellscript" ]; then
			sed -i "$f" -e "s;$strip;;"
			msg_warn "Cleaned up ${f#${PKGDESTDIR}} ...\n"
		else
			# Unhandled mime-type file contains the $strip string
			# E.g. binaries containing the build environment as a string
			msg_warn "Can't clean ${f#${PKGDESTDIR}} (mime-type: $mimetype) ...\n"
		fi
	done
}
