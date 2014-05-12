# This hook creates wrappers for foo-config scripts in cross builds.
#
# Wrappers are created in ${wrksrc}/.xbps/bin and this path is appended
# to make configure scripts find them.

WRAPPERDIR="${wrksrc}/.xbps/bin"

icu_config_wrapper() {
	[ ! -x ${XBPS_CROSS_BASE}/usr/bin/icu-config ] && return 0

	echo "#!/bin/sh" >> ${WRAPPERDIR}/icu-config
	echo "exec ${XBPS_CROSS_BASE}/usr/bin/icu-config --prefix=${XBPS_CROSS_BASE}/usr \"\$@\"" >> ${WRAPPERDIR}/icu-config
	chmod 755 ${WRAPPERDIR}/icu-config
}

hook() {
	[ -z "$CROSS_BUILD" ] && return 0

	mkdir -p ${WRAPPERDIR}

	# create wrapers
	icu_config_wrapper

	export PATH=${WRAPPERDIR}:$PATH
}
