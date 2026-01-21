_xbps_ldc_target="$XBPS_LDC_TARGET"
_xbps_ldc_dflags="$XBPS_LDC_DFLAGS"
if [ "$CROSS_BUILD" ]; then
	_xbps_ldc_target="$XBPS_CROSS_LDC_TARGET"
	_xbps_ldc_dflags="$XBPS_CROSS_LDC_DFLAGS"
	if [ "$CHROOT_READY" ] && [ -f /etc/ldc2.conf ] &&
	   [ -d $wrksrc ] && [ ! -f $wrksrc/ldc2.conf ]; then
		cp /etc/ldc2.conf $wrksrc
		cat <<-_EOF >>"$wrksrc/ldc2.conf"

		"$(echo $XBPS_CROSS_LDC_TARGET | sed 's/-/-.*/')":
		{
		  lib-dirs = [
		    "$XBPS_CROSS_BASE/usr/lib",
		  ];
		};
		_EOF
	fi
fi
if [ ! -x "${XBPS_WRAPPERDIR}/ldmd2" ]; then
	cat <<-_EOF >"${XBPS_WRAPPERDIR}/ldmd2"
	#!/bin/sh
	exec /usr/bin/ldmd2 \\
	    -target=$_xbps_ldc_target \\
	    -release \\
	$(printf '\t%s \\\n' $_xbps_ldc_dflags | sed 's/--d-version/-version/')
	    "\$@"
	_EOF
	chmod +x "${XBPS_WRAPPERDIR}/ldmd2"
fi

if [ ! -x "${XBPS_WRAPPERDIR}/ldc2" ]; then
	cat <<-_EOF >"${XBPS_WRAPPERDIR}/ldc2"
	#!/bin/sh
	exec /usr/bin/ldc2 \\
	    -mtriple=$_xbps_ldc_target \\
	    -release \\
	$(printf '    %s \\\n' $_xbps_ldc_dflags)
	    "\$@"
	_EOF
	chmod +x "${XBPS_WRAPPERDIR}/ldc2"
fi
