#
# This helper sets some required vars to be able to cross build
# packages on xbps. The target is specified in the configuration file
# and will be read any time the cross compilation flag is used.
#
[ -z "$XBPS_CROSS_TARGET" -o ! -d $XBPS_CROSS_DIR/bin ] && return 1

# Check if all required bins are there.
for bin in gcc g++ cpp ar as ranlib ld strip; do
	if [ ! -x $XBPS_CROSS_DIR/bin/$XBPS_CROSS_TARGET-${bin} ]; then
		msg_error "cross-compilation: cannot find ${bin}, aborting."
	fi
done

SAVE_PATH="$PATH"

cross_compile_setvars()
{
	export GCC=$XBPS_CROSS_TARGET-gcc
	export CC=$XBPS_CROSS_TARGET-gcc
	export CXX=$XBPS_CROSS_TARGET-g++
	export CPP=$XBPS_CROSS_TARGET-cpp
	export AR=$XBPS_CROSS_TARGET-ar
	export AS=$XBPS_CROSS_TARGET-as
	export RANLIB=$XBPS_CROSS_TARGET-ranlib
	export LD=$XBPS_CROSS_TARGET-ld
	export STRIP=$XBPS_CROSS_TARGET-strip
	export PATH="$XBPS_CROSS_DIR/bin:$PATH"
}

cross_compile_unsetvars()
{
	unset GCC CC CXX CPP AR AS RANLIB LD STRIP PATH
	export PATH="$SAVE_PATH"
}

if [ "$build_style" = "gnu_configure" ]; then
	configure_args="--build=$XBPS_CROSS_HOST --host=$XBPS_CROSS_TARGET"
	configure_args="$configure_args --target=$XBPS_CROSS_TARGET"
fi
