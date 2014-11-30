#
# This helper is for templates using GNU Makefiles.
#
do_build() {
	: ${make_cmd:=make}

	${make_cmd} \
		CC="$CC" CXX="$CXX" LD="$LD" AR="$AR" RANLIB="$RANLIB" \
		CPP="$CPP" AS="$AS" OBJDUMP="$OBJDUMP" STRIP="$STRIP" \
		CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS" LDFLAGS="$LDFLAGS" \
		${makejobs} ${make_build_args} ${make_build_target}
}

do_install() {
	: ${make_cmd:=make}
	: ${make_install_target:=install}

	make_install_args+=" PREFIX=/usr DESTDIR=${DESTDIR}"

	${make_cmd} ${make_install_args} ${make_install_target}
}
