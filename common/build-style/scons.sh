#
# This helper is for templates using scons.
#
do_build() {
	: ${make_cmd:=scons}

	${make_cmd} ${makejobs} CC=$CC CXX=$CXX CCFLAGS="$CFLAGS" \
		CXXFLAGS="$CXXFLAGS" LINKFLAGS="$LDFLAGS" \
		prefix=/usr destdir=${DESTDIR} DESTDIR=${DESTDIR} \
		${make_build_args} ${make_build_target}
}
do_install() {
	: ${make_cmd:=scons}
	: ${make_install_target:=install}

	${make_cmd} ${makejobs} CC=$CC CXX=$CXX CCFLAGS="$CFLAGS" \
		CXXFLAGS="$CXXFLAGS" LINKFLAGS="$LDFLAGS" \
		prefix=/usr destdir=${DESTDIR} DESTDIR=${DESTDIR} \
		${make_install_args} ${make_install_target}
}
