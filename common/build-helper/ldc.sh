_ldc_helper() {
	local _xbps_ldc_target="$XBPS_LDC_TARGET"
	local _xbps_ldc_dflags="$XBPS_LDC_DFLAGS"
	if [ "$CROSS_BUILD" ]; then
		_xbps_ldc_target="$XBPS_CROSS_LDC_TARGET"
		_xbps_ldc_dflags="$XBPS_CROSS_LDC_DFLAGS"
		if [ "$sourcepkg" != ldc ]; then
			hostmakedepends+=" ldc-cross-config"
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
}

_ldc_helper
