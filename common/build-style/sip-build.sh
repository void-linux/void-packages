#
# This helper is for templates using sip-build.
#

do_configure() {
	local _qt=
	local _spec=
	local _mkspec=

	: "${sip_builddir:=build}"
	mkdir -p "$sip_builddir"

	if [ ! -d /$py3_sitelib/pyqtbuild ]; then
		: "who uses sip-build without qmake anyway?"
	elif [ -x /usr/lib/qt6/bin/qmake ]; then
		_qt=qt6
	elif [ -x /usr/lib/qt5/bin/qmake ]; then
		_qt=qt5
	else
		msg_error 'qmake not found\n'
	fi

	if [ ! "$_qt" ]; then
		: "who use sip-build without qmake anyway?"
	elif [ "$CROSS_BUILD" ]; then
		_mkspec="usr/lib/$_qt/mkspecs"
		_spec="$XBPS_WRAPPERDIR/sip-build/target-spec/linux-g++"
		mkdir -p "$_spec"
		cat >"$_spec/qmake.conf" <<-_EOF
		MAKEFILE_GENERATOR      = UNIX
		CONFIG                 += incremental no_qt_rpath
		QMAKE_INCREMENTAL_STYLE = sublib

		include(/$_mkspec/common/linux.conf)
		include(/$_mkspec/common/gcc-base-unix.conf)
		include(/$_mkspec/common/g++-unix.conf)

		QMAKE_TARGET_CONFIG     = $XBPS_CROSS_BASE/$_mkspec/qconfig.pri
		QMAKE_TARGET_MODULE     = $XBPS_CROSS_BASE/$_mkspec/qmodule.pri
		QMAKEMODULES            = $XBPS_CROSS_BASE/$_mkspec/modules
		QMAKE_CC                = $CC
		QMAKE_CXX               = $CXX
		QMAKE_LINK              = $CXX
		QMAKE_LINK_C            = $CC
		QMAKE_LINK_SHLIB        = $CXX

		QMAKE_AR                = $XBPS_CROSS_TRIPLET-gcc-ar cqs
		QMAKE_OBJCOPY           = $OBJCOPY
		QMAKE_NM                = $NM -P
		QMAKE_STRIP             = $STRIP

		QMAKE_CFLAGS            = $CFLAGS -I$XBPS_CROSS_BASE/usr/include/python$py3_ver
		QMAKE_CXXFLAGS          = $CXXFLAGS -I$XBPS_CROSS_BASE/usr/include/python$py3_ver
		QMAKE_LFLAGS            = -L$XBPS_CROSS_BASE/usr/lib $LDFLAGS
		load(qt_config)
		_EOF

		printf '#include "%s/%s/linux-g++/qplatformdefs.h"\n' \
			"$XBPS_CROSS_BASE" "$_mkspec" >"$_spec/qplatformdefs.h"
		cat >"$XBPS_WRAPPERDIR/sip-build/qt.conf" <<-_EOF
		[Paths]
		Sysroot=$XBPS_CROSS_BASE
		Prefix=$XBPS_CROSS_BASE/usr
		ArchData=$XBPS_CROSS_BASE/usr/lib/$_qt
		Data=$XBPS_CROSS_BASE/usr/share/$_qt
		Documentation=$XBPS_CROSS_BASE/usr/share/doc/$_qt
		Headers=$XBPS_CROSS_BASE/usr/include/$_qt
		Libraries=$XBPS_CROSS_BASE/usr/lib
		LibraryExecutables=/usr/lib/$_qt/libexec
		Binaries=/usr/lib/$_qt/bin
		Tests=$XBPS_CROSS_BASE/usr/tests
		Plugins=/usr/lib/$_qt/plugins
		Imports=$XBPS_CROSS_BASE/usr/lib/$_qt/imports
		Qml2Imports=$XBPS_CROSS_BASE/usr/lib/$_qt/qml
		Translations=$XBPS_CROSS_BASE/usr/share/$_qt/translations
		Settings=$XBPS_CROSS_BASE/etc/xdg
		Examples=$XBPS_CROSS_BASE/usr/share/$_qt/examples
		HostPrefix=/usr
		HostData=/usr/lib/$_qt
		HostBinaries=/usr/lib/$_qt/bin
		HostLibraries=/usr/lib
		HostLibraryExecutables=/usr/lib/$_qt/libexec
		Spec=linux-g++
		TargetSpec=$_spec
		_EOF
		# Call it sip-qmake to not override qmake build-helper
		#
		# XXX: Intentionally quote {C,CXX,LD}FLAGS here but not native.
		# - Cross Build:
		#   + base flags will be picked up from QMAKE_{C,CXX,LD}FLAGS
		#   + hardening flags will be picked up from environment variables
		# - Native Build:
		#   + hardening flags will be picked up first (Makefile, qt.conf?)
		#   + base flags will be picked up from QMAKE_{C,CXX,LD}FLAGS
		# Maybe there're better workaround, I don't know.
		cat >"$XBPS_WRAPPERDIR/sip-qmake" <<-_EOF
		#!/bin/sh
		exec /usr/lib/$_qt/bin/qmake "\$@" \\
		        -qtconf "$XBPS_WRAPPERDIR/sip-build/qt.conf" \\
		        PKG_CONFIG_EXECUTABLE=${XBPS_WRAPPERDIR}/${PKG_CONFIG} \\
		        QMAKE_CFLAGS+="\$CFLAGS" \\
		        QMAKE_CXXFLAGS+="\$CXXFLAGS" \\
		        QMAKE_LFLAGS+="\$LDFLAGS"
		_EOF
		chmod 755 ${XBPS_WRAPPERDIR}/sip-qmake
	else
		cat >"${XBPS_WRAPPERDIR}/sip-qmake" <<-_EOF
		#!/bin/sh
		exec /usr/lib/$_qt/bin/qmake \\
		        "\$@" \\
		        PREFIX=/usr \\
		        QT_INSTALL_PREFIX=/usr \\
		        LIB=/usr/lib \\
		        QMAKE_CC="$CC" QMAKE_CXX="$CXX" \\
		        QMAKE_LINK="$CXX" QMAKE_LINK_C="$CC" \\
		        QMAKE_CFLAGS+="$CFLAGS" \\
		        QMAKE_CXXFLAGS+="$CXXFLAGS" \\
		        QMAKE_LFLAGS+="$LDFLAGS" \\
		        CONFIG+=no_qt_rpath
		_EOF
		chmod 755 ${XBPS_WRAPPERDIR}/sip-qmake
	fi

	sip-build --no-make \
		${_qt:+--qmake "$XBPS_WRAPPERDIR/sip-qmake"} \
		--api-dir /usr/share/$_qt/qsci/api/python \
		$configure_args \
		--build-dir "$sip_builddir"

	if [ "$CROSS_BUILD" ]; then
		# -I/usr/include/python$py3_ver is set by sip-build :(
		find "$sip_builddir" -name Makefile |
		xargs sed -i "s,-I\\(/usr/include\\),-I$XBPS_CROSS_BASE\\1,g"
	fi
}

do_build() {
	: "${sip_builddir:=build}"
	make -C "${sip_builddir}" ${makejobs}
}

do_install() {
	: "${sip_builddir:=build}"
	make -C "${sip_builddir}" \
		DESTDIR=${DESTDIR} INSTALL_ROOT=${DESTDIR} \
		install
}
