#
# This helper is for templates using Qt5/Qt6 qmake.
#
do_configure() {
	local qmake
	local qmake_args
	local qt=${QT:-}
	local builddir="${wrksrc}/${build_wrksrc}"
	cd ${builddir}
	if [ "${QT}" ]; then
		qt=${QT}
		if [ ! -x "/usr/lib/${qt}/bin/qmake" ]; then
			msg_error "${QT} is requested, but not found\n"
		fi
	elif [ -x "/usr/lib/qt5/bin/qmake" ]; then
		qt="qt5"
	elif [ -x "/usr/lib/qt6/bin/qmake" ]; then
		qt="qt6"
	else
		msg_error "${pkgver}: Could not find qmake - missing in hostmakedepends?\n"
	fi
	qmake="/usr/lib/${qt}/bin/qmake"
	if [ "$CROSS_BUILD" ]; then
		case $XBPS_TARGET_MACHINE in
			i686*) _qt_arch=i386;;
			x86_64*) _qt_arch=x86_64;;
			aarch64*) _qt_arch=arm64;;
			arm*) _qt_arch=arm;;
			mips*) _qt_arch=mips;;
			ppc64*) _qt_arch=power64;;
			ppc*) _qt_arch=power;;
		esac
		mkdir -p "${builddir}/.target-spec/linux-g++"
		cat > "${builddir}/.target-spec/linux-g++/qmake.conf" <<_EOF
MAKEFILE_GENERATOR      = UNIX
CONFIG                 += incremental no_qt_rpath
QMAKE_INCREMENTAL_STYLE = sublib

include(/usr/lib/${qt}/mkspecs/common/linux.conf)
include(/usr/lib/${qt}/mkspecs/common/gcc-base-unix.conf)
include(/usr/lib/${qt}/mkspecs/common/g++-unix.conf)

QMAKE_TARGET_CONFIG     = ${XBPS_CROSS_BASE}/usr/lib/${qt}/mkspecs/qconfig.pri
QMAKE_TARGET_MODULE     = ${XBPS_CROSS_BASE}/usr/lib/${qt}/mkspecs/qmodule.pri
QMAKEMODULES            = ${XBPS_CROSS_BASE}/usr/lib/${qt}/mkspecs/modules
QMAKE_CC                = ${CC}
QMAKE_CXX               = ${CXX}
QMAKE_LINK              = ${CXX}
QMAKE_LINK_C            = ${CC}
QMAKE_LINK_SHLIB        = ${CXX}

QMAKE_AR                = ${XBPS_CROSS_TRIPLET}-gcc-ar cqs
QMAKE_OBJCOPY           = ${OBJCOPY}
QMAKE_NM                = ${NM} -P
QMAKE_STRIP             = ${STRIP}

QMAKE_CFLAGS            = ${CFLAGS}
QMAKE_CXXFLAGS          = ${CXXFLAGS}
QMAKE_LFLAGS            = ${LDFLAGS}
load(qt_config)
_EOF
		echo "#include \"${XBPS_CROSS_BASE}/usr/lib/${qt}/mkspecs/linux-g++/qplatformdefs.h\"" > "${builddir}/.target-spec/linux-g++/qplatformdefs.h"

		mkdir -p "${builddir}/.host-spec/linux-g++"
		cat > "${builddir}/.host-spec/linux-g++/qmake.conf" <<_EOF
MAKEFILE_GENERATOR      = UNIX
CONFIG                 += incremental no_qt_rpath
QMAKE_INCREMENTAL_STYLE = sublib

include(/usr/lib/${qt}/mkspecs/common/linux.conf)
include(/usr/lib/${qt}/mkspecs/common/gcc-base-unix.conf)
include(/usr/lib/${qt}/mkspecs/common/g++-unix.conf)

QMAKE_TARGET_CONFIG     = ${XBPS_CROSS_BASE}/usr/lib/${qt}/mkspecs/qconfig.pri
QMAKE_TARGET_MODULE     = ${XBPS_CROSS_BASE}/usr/lib/${qt}/mkspecs/qmodule.pri
QMAKE_CC                = ${CC_host}
QMAKE_CXX               = ${CXX_host}
QMAKE_LINK              = ${CXX_host}
QMAKE_LINK_C            = ${CC_host}
QMAKE_LINK_SHLIB        = ${CXX_host}

QMAKE_AR                = gcc-ar cqs
QMAKE_OBJCOPY           = ${OBJCOPY_host}
QMAKE_NM                = ${NM_host} -P
QMAKE_STRIP             = ${STRIP_host}

QMAKE_CFLAGS            = ${CFLAGS_host}
QMAKE_CXXFLAGS          = ${CXXFLAGS_host}
QMAKE_LFLAGS            = ${LDFLAGS_host}
load(qt_config)
_EOF
echo '#include "/usr/lib/${qt}/mkspecs/linux-g++/qplatformdefs.h"' > "${builddir}/.host-spec/linux-g++/qplatformdefs.h"
		cat > "${builddir}/qt.conf" <<_EOF
[Paths]
Sysroot=${XBPS_CROSS_BASE}
Prefix=/usr
ArchData=${XBPS_CROSS_BASE}/usr/lib/${qt}
Data=${XBPS_CROSS_BASE}/usr/share/${qt}
Documentation=${XBPS_CROSS_BASE}/usr/share/doc/${qt}
Headers=${XBPS_CROSS_BASE}/usr/include/${qt}
Libraries=${XBPS_CROSS_BASE}/usr/lib
LibraryExecutables=/usr/lib/${qt}/libexec
Binaries=/usr/lib/${qt}/bin
Tests=${XBPS_CROSS_BASE}/usr/tests
Plugins=/usr/lib/${qt}/plugins
Imports=${XBPS_CROSS_BASE}/usr/lib/${qt}/imports
Qml2Imports=${XBPS_CROSS_BASE}/usr/lib/${qt}/qml
Translations=${XBPS_CROSS_BASE}/usr/share/${qt}/translations
Settings=${XBPS_CROSS_BASE}/etc/xdg
Examples=${XBPS_CROSS_BASE}/usr/share/${qt}/examples
HostPrefix=/usr
HostData=/usr/lib/${qt}
HostBinaries=/usr/lib/${qt}/bin
HostLibraries=/usr/lib
HostLibraryExecutables=/usr/lib/${qt}/libexec
Spec=${builddir}/.host-spec/linux-g++
TargetSpec=${builddir}/.target-spec/linux-g++
_EOF
		qmake_args="-qtconf ${builddir}/qt.conf PKG_CONFIG_EXECUTABLE=${XBPS_WRAPPERDIR}/${PKG_CONFIG}"
		${qmake} ${qmake_args} \
			PREFIX=/usr \
			QT_INSTALL_PREFIX=/usr \
			LIB=/usr/lib \
			QT_TARGET_ARCH=$_qt_arch \
			${configure_args}
	else
		${qmake} ${qmake_args} \
			PREFIX=/usr \
			QT_INSTALL_PREFIX=/usr \
			LIB=/usr/lib \
			QMAKE_CC=$CC QMAKE_CXX=$CXX \
			QMAKE_LINK=$CXX QMAKE_LINK_C=$CC \
			QMAKE_CFLAGS="${CFLAGS}" \
			QMAKE_CXXFLAGS="${CXXFLAGS}" \
			QMAKE_LFLAGS="${LDFLAGS}" \
			CONFIG+=no_qt_rpath \
			${configure_args}
	fi
}

do_build() {
	cd "${wrksrc}/${build_wrksrc}"
	: ${make_cmd:=make}

	${make_cmd} ${makejobs} ${make_build_args} ${make_build_target} \
		CC="$CC" CXX="$CXX" LINK="$CXX"
}

do_install() {
	cd "${wrksrc}/${build_wrksrc}"
	: ${make_cmd:=make}
	: ${make_install_target:=install}

	${make_cmd} STRIP=true PREFIX=/usr DESTDIR=${DESTDIR} \
		INSTALL_ROOT=${DESTDIR} ${make_install_args} ${make_install_target}
}
