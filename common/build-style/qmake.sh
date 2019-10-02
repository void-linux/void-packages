#
# This helper is for templates using Qt4/Qt5 qmake.
#
do_configure() {
	local qmake
	local qmake_args
	if [ -x "/usr/lib/qt5/bin/qmake" ]; then
		# Qt5 qmake
		qmake="/usr/lib/qt5/bin/qmake"
	fi
	if [ -x "/usr/lib/qt/bin/qmake" ]; then
		# Qt4 qmake
		qmake="/usr/lib/qt/bin/qmake"
	fi
	if [ -z "${qmake}" ]; then
		msg_error "${pkgver}: Could not find qmake - missing in hostdepends?\n"
	fi
	if [ "$CROSS_BUILD" ] && [ "$qmake" == "/usr/lib/qt5/bin/qmake" ]; then
		cat > "${wrksrc}/qt.conf" <<_EOF
[Paths]
Sysroot=${XBPS_CROSS_BASE}
Prefix=${XBPS_CROSS_BASE}/usr
ArchData=${XBPS_CROSS_BASE}/usr/lib/qt5
Data=${XBPS_CROSS_BASE}/usr/share/qt5
Documentation=${XBPS_CROSS_BASE}/usr/share/doc/qt5
Headers=${XBPS_CROSS_BASE}/usr/include/qt5
Libraries=${XBPS_CROSS_BASE}/usr/lib
LibraryExecutables=/usr/lib/qt5/libexec
Binaries=/usr/lib/qt5/bin
Tests=${XBPS_CROSS_BASE}/usr/tests
Plugins=/usr/lib/qt5/plugins
Imports=${XBPS_CROSS_BASE}/usr/lib/qt5/imports
Qml2Imports=${XBPS_CROSS_BASE}/usr/lib/qt5/qml
Translations=${XBPS_CROSS_BASE}/usr/share/qt5/translations
Settings=${XBPS_CROSS_BASE}/etc/xdg
Examples=${XBPS_CROSS_BASE}/usr/share/qt5/examples
HostPrefix=/usr
HostData=/usr/lib/qt5
HostBinaries=/usr/lib/qt5/bin
HostLibraries=/usr/lib
Spec=linux-g++
TargetSpec=linux-g++
_EOF
		qmake_args="-qtconf ${wrksrc}/qt.conf"
	fi
	${qmake} ${qmake_args} ${configure_args} \
		PREFIX=/usr \
		LIB=/usr/lib \
		QMAKE_CC=$CC QMAKE_CXX=$CXX QMAKE_LINK=$CXX QMAKE_LINK_C=$CC \
		QMAKE_CFLAGS="${CFLAGS}" \
		QMAKE_CXXFLAGS="${CXXFLAGS}" \
		QMAKE_LFLAGS="${LDFLAGS}"
}

do_build() {
	: ${make_cmd:=make}

	${make_cmd} ${makejobs} ${make_build_args} ${make_build_target} \
		CC="$CC" CXX="$CXX" LINK="$CXX"
}

do_install() {
	: ${make_cmd:=make}
	: ${make_install_target:=install}

	${make_cmd} STRIP=true PREFIX=/usr DESTDIR=${DESTDIR} \
		INSTALL_ROOT=${DESTDIR} ${make_install_args} ${make_install_target}
}
