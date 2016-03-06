if [ -n "$SOURCE_DATE_EPOCH" ]; then
	CFLAGS+=" -Wno-builtin-macro-redefined -include$XBPS_STATEDIR/timestamp-macros.h"
	CXXFLAGS+=" -Wno-builtin-macro-redefined -include$XBPS_STATEDIR/timestamp-macros.h"
	printf "" > $XBPS_STATEDIR/timestamp-macros.h
	for i in "DATE,%b %d %Y" "TIME,%H:%M:%S" "DATETIME,%b %d %Y %H:%M:%S"; do
		mcr=${i%%,*}
		val=$(LC_ALL=C date --date "@$SOURCE_DATE_EPOCH" +"${i#*,}")
		cat >> $XBPS_STATEDIR/timestamp-macros.h <<EOF
#undef __${mcr}__
#define __${mcr}__ "${val}"
EOF
	done
fi
