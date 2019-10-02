# This hook overrides config.sub and config.guess.

hook() {
	if [ -z "$build_style" -o "$build_style" = "gnu-configure" ]; then
		for f in $(find ${wrksrc} -type f -name "*config*.sub"); do
			cp -f ${XBPS_CROSSPFDIR}/config.sub ${f}
		done
		for f in $(find ${wrksrc} -type f -name "*config*.guess"); do
			cp -f ${XBPS_CROSSPFDIR}/config.guess ${f}
		done
	fi
}
