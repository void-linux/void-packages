# This hook overrides config.sub and config.guess for aarch64 builds.

hook() {
	case "$XBPS_TARGET_MACHINE" in
		aarch64*);;
		*) return 0;;
	esac
	if [ -z "$build_style" -o "$build_style" = "gnu-configure" ]; then
		for f in $(find ${wrksrc} -type f -name "*config*.sub"); do
			cp -f ${XBPS_CROSSPFDIR}/config.sub ${f}
		done
		for f in $(find ${wrksrc} -type f -name "*config*.guess"); do
			cp -f ${XBPS_CROSSPFDIR}/config.guess ${f}
		done
	fi
}
