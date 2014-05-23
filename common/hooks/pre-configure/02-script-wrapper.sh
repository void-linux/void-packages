# This hook creates wrappers for foo-config scripts in cross builds.
#
# Wrappers are created in ${wrksrc}/.xbps/bin and this path is appended
# to make configure scripts find them.

WRAPPERDIR="${wrksrc}/.xbps/bin"

generic_wrapper() {
	local wrapper="$1"
	[ ! -x ${XBPS_CROSS_BASE}/usr/bin/${wrapper} ] && return 0
	[ -x ${WRAPPERDIR}/${wrapper} ] && return 0

	echo "#!/bin/sh" >> ${WRAPPERDIR}/${wrapper}
	echo "exec ${XBPS_CROSS_BASE}/usr/bin/${wrapper} --prefix=${XBPS_CROSS_BASE}/usr \"\$@\"" >> ${WRAPPERDIR}/${wrapper}
	chmod 755 ${WRAPPERDIR}/${wrapper}
}

libpng_config_wrapper() {
	[ ! -x ${XBPS_CROSS_BASE}/usr/bin/libpng-config ] && return 0
	[ -x ${WRAPPERDIR}/libpng-config ] && return 0

	cat >>${WRAPPERDIR}/libpng-config<<_EOF
#!/bin/sh
if [ "\$1" = "--prefix" ]; then
	echo "${XBPS_CROSS_BASE}/usr"
elif [ "\$1" = "--cflags" ]; then
	echo "-I${XBPS_CROSS_BASE}/usr/include/libpng16"
else
	echo "exec ${XBPS_CROSS_BASE}/usr/bin/libpng-config "\$@"
fi
exit \$?
_EOF
	chmod 755 ${WRAPPERDIR}/libpng-config
}

hook() {
	[ -z "$CROSS_BUILD" ] && return 0

	mkdir -p ${WRAPPERDIR}

	# create wrapers
	generic_wrapper icu-config
	generic_wrapper libgcrypt-config
	generic_wrapper freetype-config
	generic_wrapper sdl-config
	generic_wrapper sdl2-config
	libpng_config_wrapper

	export PATH=${WRAPPERDIR}:$PATH
}
