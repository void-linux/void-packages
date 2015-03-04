if [ -n "$build_pie" ]; then
	CFLAGS+=" -fPIE"
	LDFLAGS+=" -pie"
fi
