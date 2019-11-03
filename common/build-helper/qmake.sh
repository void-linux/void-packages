# This build-helper sets up qmake’s cross environment
# in cases the build-style is mixed,
# e.g. when in a gnu-configure style the configure
# script calls qmake or a makefile in a gnu-makefile style,
# respectively.

if [ "$CROSS_BUILD" ]; then
	cat > "${XBPS_WRAPPERDIR}/qt.conf" <<_EOF
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

	# create the qmake-wrapper here because it only
	# makes sense together with the qmake build-helper
	# and not to interfere with e.g. the qmake build-style
        cat > "${XBPS_WRAPPERDIR}/qmake" <<_EOF
#!/bin/sh
exec /usr/lib/qt5/bin/qmake "\$@" \
	QMAKE_CC=$CC QMAKE_CXX=$CXX QMAKE_LINK=$CXX QMAKE_LINK_C=$CC \
	QMAKE_CFLAGS+="${CFLAGS}" QMAKE_CXXFLAGS+="${CXXFLAGS}" \
	QMAKE_LFLAGS+="${LDFLAGS}" \
	-qtconf "${XBPS_WRAPPERDIR}/qt.conf"
_EOF

	chmod 755 ${XBPS_WRAPPERDIR}/qmake
	cp -p ${XBPS_WRAPPERDIR}/qmake{,-qt5}
fi
