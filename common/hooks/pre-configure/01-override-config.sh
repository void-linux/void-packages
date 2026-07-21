# This hook overrides config.sub and config.guess.

hook() {
	local _cfgdir="${XBPS_COMMONDIR}/environment/configure/automake"

	if [ -z "$build_style" -o "$build_style" = "gnu-configure" ]; then
		for f in $(find "${wrksrc}" -type f -name "*config*.sub"); do
			cp -f ${_cfgdir}/config.sub ${f}
		done
		for f in $(find "${wrksrc}" -type f -name "*config*.guess"); do
			cp -f ${_cfgdir}/config.guess ${f}
		done
	fi
}
