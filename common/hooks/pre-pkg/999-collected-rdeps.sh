# This hook displays resolved dependencies for a pkg.

hook() {
	if [ -e "${XBPS_STATEDIR}/${pkgname}-rdeps" ]; then
		echo "   $(cat "${XBPS_STATEDIR}/${pkgname}-rdeps")"
	fi
}
