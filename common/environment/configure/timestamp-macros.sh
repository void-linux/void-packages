if [ -n "$XBPS_COMMIT_TIMESTAMP" ]; then
	CFLAGS+=" -Wno-builtin-macro-redefined"
	CXXFLAGS+=" -Wno-builtin-macro-redefined"
	for i in "DATE,%b\x20%d\x20%Y" "TIME,%H:%M:%S" "DATETIME,%b\x20%d\x20%Y\x20%H:%M:%S"; do
		CFLAGS+=" -U__${i%%,*}__ -D__${i%%,*}__=\\\"$(LC_ALL=C date --date "$XBPS_COMMIT_TIMESTAMP" +"${i#*,}")\\\""
		CXXFLAGS+=" -U__${i%%,*}__ -D__${i%%,*}__=\\\"$(LC_ALL=C date --date "$XBPS_COMMIT_TIMESTAMP" +"${i#*,}")\\\""
	done
fi
