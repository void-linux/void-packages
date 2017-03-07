#
# This helper is for templates using Qt4/Qt5 qmake.
#
do_configure() {
	qmake ${configure_args} \
		PREFIX=/usr \
		LIB=/usr/lib \
		QMAKE_CC=$CC QMAKE_CXX=$CXX QMAKE_LINK=$CXX \
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
