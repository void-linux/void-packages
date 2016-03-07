# This hook overwrites timestamp macros.
#
hook() {
	local i mcr val macros="$XBPS_STATEDIR/timestamp-macros.h"

	[ -n "$XBPS_USE_BUILD_MTIME" ] && return 0
	[ -z "$SOURCE_DATE_EPOCH" ] && return 0
	msg_normal "Creating $macros\n"
	CFLAGS+=" -Wno-builtin-macro-redefined -include$macros"
	CXXFLAGS+=" -Wno-builtin-macro-redefined -include$macros"
	rm -f "$macros"
	for i in "DATE,%b %d %Y" "TIME,%H:%M:%S" "DATETIME,%b %d %Y %H:%M:%S"; do
		mcr=${i%%,*}
		val=$(LC_ALL=C date --date "@$SOURCE_DATE_EPOCH" +"${i#*,}")
		echo "#undef __${mcr}__" >> "$macros"
		echo "#define __${mcr}__ \"${val}\"" >> "$macros"
	done
}
