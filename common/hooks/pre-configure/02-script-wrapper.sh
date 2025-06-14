# This hook creates wrappers for foo-config scripts in cross builds.
#
# Wrappers are created in ${wrksrc}/.xbps/bin and this path is appended
# to make configure scripts find them.

generic_wrapper() {
	local wrapper="$1"
	[ ! -x ${XBPS_CROSS_BASE}/usr/bin/${wrapper} ] && return 0
	[ -x ${XBPS_WRAPPERDIR}/${wrapper} ] && return 0

	cat >>${XBPS_WRAPPERDIR}/${wrapper}<<_EOF
#!/bin/sh
exec ${XBPS_CROSS_BASE}/usr/bin/${wrapper} --prefix=${XBPS_CROSS_BASE}/usr "\$@"
_EOF

	chmod 755 ${XBPS_WRAPPERDIR}/${wrapper}
}

generic_wrapper2() {
	local wrapper="$1"

	[ ! -x ${XBPS_CROSS_BASE}/usr/bin/${wrapper} ] && return 0
	[ -x ${XBPS_WRAPPERDIR}/${wrapper} ] && return 0

	cat >>${XBPS_WRAPPERDIR}/${wrapper}<<_EOF
#!/bin/sh
if [ "\$1" = "--prefix" ]; then
	echo "${XBPS_CROSS_BASE}/usr"
elif [ "\$1" = "--cflags" ]; then
	${XBPS_CROSS_BASE}/usr/bin/${wrapper} --cflags | sed -e "s,-I/usr/include,-I${XBPS_CROSS_BASE}/usr/include,g"
elif [ "\$1" = "--libs" ]; then
	${XBPS_CROSS_BASE}/usr/bin/${wrapper} --libs | sed -e "s,-L/usr/lib,-L${XBPS_CROSS_BASE}/usr/lib,g"
else
	exec ${XBPS_CROSS_BASE}/usr/bin/${wrapper} "\$@"
fi
exit \$?
_EOF
	chmod 755 ${XBPS_WRAPPERDIR}/${wrapper}
}

generic_wrapper3() {
	local wrapper="$1"
	[ ! -x ${XBPS_CROSS_BASE}/usr/bin/${wrapper} ] && return 0
	[ -x ${XBPS_WRAPPERDIR}/${wrapper} ] && return 0

	cp ${XBPS_CROSS_BASE}/usr/bin/${wrapper} ${XBPS_WRAPPERDIR}
	sed -e "s,^libdir=.*,libdir=${XBPS_CROSS_BASE}/usr/lib,g" -i ${XBPS_WRAPPERDIR}/${wrapper}
	sed -e "s,^prefix=.*,prefix=${XBPS_CROSS_BASE}/usr," -i ${XBPS_WRAPPERDIR}/${wrapper}

	chmod 755 ${XBPS_WRAPPERDIR}/${wrapper}
}

qemu_wrapper() {
	local wrapper="$1"
	[ ! -x ${XBPS_CROSS_BASE}/usr/bin/${wrapper} ] && return 0
	[ -x ${XBPS_WRAPPERDIR}/${wrapper}-qemu ] && return 0

cat >>${XBPS_WRAPPERDIR}/${wrapper}-qemu<<_EOF
#!/bin/sh
export QEMU_LD_PREFIX=${XBPS_CROSS_BASE}
exec qemu-${XBPS_TARGET_QEMU_MACHINE} ${XBPS_CROSS_BASE}/usr/bin/${wrapper} "\$@"
_EOF
	chmod 755 ${XBPS_WRAPPERDIR}/${wrapper}-qemu
}

apr_apu_wrapper() {
	local wrapper="$1"

	[ ! -x ${XBPS_CROSS_BASE}/usr/bin/${wrapper} ] && return 0
	[ -x ${XBPS_WRAPPERDIR}/${wrapper} ] && return 0

	cat >>${XBPS_WRAPPERDIR}/${wrapper}<<_EOF
#!/bin/sh
${XBPS_CROSS_BASE}/usr/bin/${wrapper} "\$@" | sed -e "s,/usr/,${XBPS_CROSS_BASE}/usr/,g"
exit \$?
_EOF
	chmod 755 ${XBPS_WRAPPERDIR}/${wrapper}
}

python_wrapper() {
	local wrapper="$1" version="$2"

	[ -x ${XBPS_WRAPPERDIR}/${wrapper} ] && return 0
	cat >>${XBPS_WRAPPERDIR}/${wrapper}<<_EOF
#!/bin/sh
case "\$1" in
--includes|--cflags)
	echo "-I${XBPS_CROSS_BASE}/usr/include/python${version}" ;;
esac
exit 0
_EOF
	chmod 755 ${XBPS_WRAPPERDIR}/${wrapper}
}

pkgconfig_wrapper() {
	if [ ! -x /usr/bin/pkg-config ]; then
		return 0
	fi
	[ -x ${XBPS_WRAPPERDIR}/${XBPS_CROSS_TRIPLET}-pkg-config ] && return 0
	cat >>${XBPS_WRAPPERDIR}/${XBPS_CROSS_TRIPLET}-pkg-config<<_EOF
#!/bin/sh

export PKG_CONFIG_SYSROOT_DIR="$XBPS_CROSS_BASE"
export PKG_CONFIG_PATH="$XBPS_CROSS_BASE/usr/lib/pkgconfig:$XBPS_CROSS_BASE/usr/share/pkgconfig\${PKG_CONFIG_PATH:+:\${PKG_CONFIG_PATH}}"
export PKG_CONFIG_LIBDIR="$XBPS_CROSS_BASE/usr/lib/pkgconfig\${PKG_CONFIG_LIBDIR:+:\${PKG_CONFIG_LIBDIR}}"
exec /usr/bin/pkg-config "\$@"
_EOF
	chmod 755 ${XBPS_WRAPPERDIR}/${XBPS_CROSS_TRIPLET}-pkg-config
	if [ -z "$no_generic_pkgconfig_link" ]; then
		ln -sf ${XBPS_CROSS_TRIPLET}-pkg-config ${XBPS_WRAPPERDIR}/pkg-config
	fi
}

vapigen_wrapper() {
	local _vala_version _file
	if [ ! -x /usr/bin/vapigen ]; then
		return 0
	fi
	[ -x ${XBPS_WRAPPERDIR}/vapigen ] && return 0
	for _file in /usr/bin/vapigen-*; do
		if [ -x "${_file}" ]; then
			_vala_version=${_file#*-}
		fi
	done
	cat >>${XBPS_WRAPPERDIR}/vapigen<<_EOF
#!/bin/sh
exec /usr/bin/vapigen \\
	 "\$@" \\
	 --vapidir=${XBPS_CROSS_BASE}/usr/share/vala/vapi \\
	 --vapidir=${XBPS_CROSS_BASE}/usr/share/vala-${_vala_version}/vapi \\
	 --girdir=${XBPS_CROSS_BASE}/usr/share/gir-1.0
_EOF
	chmod 755 ${XBPS_WRAPPERDIR}/vapigen
	ln -sf vapigen ${XBPS_WRAPPERDIR}/vapigen-${_vala_version}
}

valac_wrapper() {
	local _vala_version _file
	if [ ! -x /usr/bin/valac ]; then
		return 0
	fi
	[ -x ${XBPS_WRAPPERDIR}/valac ] && return 0
	for _file in /usr/bin/valac-*; do
		if [ -x "${_file}" ]; then
			_vala_version=${_file#*-}
		fi
	done
	cat >>${XBPS_WRAPPERDIR}/valac<<_EOF
#!/bin/sh
exec /usr/bin/valac \\
	 "\$@" \\
	 --vapidir=${XBPS_CROSS_BASE}/usr/share/vala/vapi \\
	 --vapidir=${XBPS_CROSS_BASE}/usr/share/vala-${_vala_version}/vapi \\
	 --girdir=${XBPS_CROSS_BASE}/usr/share/gir-1.0
_EOF
	chmod 755 ${XBPS_WRAPPERDIR}/valac
	ln -sf valac ${XBPS_WRAPPERDIR}/valac-${_vala_version}
}

install_wrappers() {
	local fname

	for f in ${XBPS_COMMONDIR}/wrappers/*.sh; do
		fname=${f##*/}
		fname=${fname%.sh}
		install -p -m0755 ${f} ${XBPS_WRAPPERDIR}/${fname}
	done
}

install_cross_wrappers() {
	local fname prefix

	if [ -n "$XBPS_CCACHE" ]; then
		[ -x "/usr/bin/ccache" ] && prefix="/usr/bin/ccache "
	elif [ -n "$XBPS_DISTCC" ]; then
		[ -x "/usr/bin/distcc" ] && prefix="/usr/bin/distcc "
	fi

	for fname in cc gcc; do
		sed -e "s,@BIN@,${prefix}/usr/bin/$XBPS_CROSS_TRIPLET-gcc,g" \
			${XBPS_COMMONDIR}/wrappers/cross-cc > \
			${XBPS_WRAPPERDIR}/${XBPS_CROSS_TRIPLET}-${fname}
		chmod 755 ${XBPS_WRAPPERDIR}/${XBPS_CROSS_TRIPLET}-${fname}
	done
	for fname in c++ g++; do
		sed -e "s,@BIN@,${prefix}/usr/bin/$XBPS_CROSS_TRIPLET-g++,g" \
			${XBPS_COMMONDIR}/wrappers/cross-cc > \
			${XBPS_WRAPPERDIR}/${XBPS_CROSS_TRIPLET}-${fname}
		chmod 755 ${XBPS_WRAPPERDIR}/${XBPS_CROSS_TRIPLET}-${fname}
	done
}

link_wrapper() {
	local wrapper="$1"
	[ ! -x "${XBPS_CROSS_BASE}/usr/bin/${wrapper}" ] && return 0
	[ -L "${XBPS_WRAPPERDIR}/${wrapper}" ] && return 0
	ln -sf "${XBPS_CROSS_BASE}/usr/bin/${wrapper}" "${XBPS_WRAPPERDIR}"
}

hook() {
	export PATH="$XBPS_WRAPPERDIR:$PATH"

	install_wrappers

	[ -z "$CROSS_BUILD" ] && return 0

	install_cross_wrappers
	pkgconfig_wrapper
	vapigen_wrapper
	valac_wrapper

	if [ -x /usr/bin/pkg-config ]; then
		link_wrapper freetype-config
	else
		generic_wrapper freetype-config
	fi

	generic_wrapper icu-config
	generic_wrapper libgcrypt-config
	generic_wrapper sdl-config
	generic_wrapper sdl2-config
	generic_wrapper gpgme-config
	generic_wrapper gphoto2-config
	generic_wrapper gphoto2-port-config
	generic_wrapper imlib2-config
	generic_wrapper libmikmod-config
	generic_wrapper pcre-config
	generic_wrapper net-snmp-config
	generic_wrapper wx-config
	generic_wrapper wx-config-3.0
	generic_wrapper wx-config-gtk3
	generic_wrapper2 curl-config
	generic_wrapper2 gpg-error-config
	generic_wrapper2 libassuan-config
	generic_wrapper2 mysql_config
	generic_wrapper2 taglib-config
	generic_wrapper2 nspr-config
	generic_wrapper2 gdal-config
	generic_wrapper3 libpng-config
	generic_wrapper3 xmlrpc-c-config
	generic_wrapper3 krb5-config
	generic_wrapper3 cups-config
	generic_wrapper3 Magick-config
	generic_wrapper3 fltk-config
	generic_wrapper3 xslt-config
	generic_wrapper3 xml2-config
	generic_wrapper3 fox-config
	generic_wrapper3 xapian-config
	generic_wrapper3 ncurses5-config
	generic_wrapper3 ncursesw5-config
	generic_wrapper3 libetpan-config
	generic_wrapper3 giblib-config
	python_wrapper python-config 2.7
	python_wrapper python3-config 3.13
	apr_apu_wrapper apu-1-config
	qemu_wrapper llvm-config
}
