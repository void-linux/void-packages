# This hook overrides config.sub for musl builds.

hook() {
	case "$XBPS_TARGET_MACHINE" in
		*-musl);;
		*) return 0;;
	esac
	if [ -z "$build_style" -o "$build_style" = "gnu-configure" ]; then
		for f in $(find ${wrksrc} -type f -name "*config*.sub"); do
			cp -f ${XBPS_CROSSPFDIR}/config.sub ${f}
		done
	fi
}
