# This hook creates wrappers for foo-config scripts in cross builds.
#
# Wrappers are created in ${wrksrc}/.xbps/bin and this path is appended
# to make configure scripts find them.

WRAPPERDIR="${wrksrc}/.xbps/bin"

generic_wrapper() {
	local wrapper="$1"
	[ ! -x ${XBPS_CROSS_BASE}/usr/bin/${wrapper} ] && return 0

	echo "#!/bin/sh" >> ${WRAPPERDIR}/${wrapper}
	echo "exec ${XBPS_CROSS_BASE}/usr/bin/${wrapper} --prefix=${XBPS_CROSS_BASE}/usr \"\$@\"" >> ${WRAPPERDIR}/${wrapper}
	chmod 755 ${WRAPPERDIR}/${wrapper}
}

hook() {
	[ -z "$CROSS_BUILD" ] && return 0

	mkdir -p ${WRAPPERDIR}

	# create wrapers
	generic_wrapper icu-config
	generic_wrapper libgcrypt-config
	generic_wrapper freetype-config

	export PATH=${WRAPPERDIR}:$PATH
}
