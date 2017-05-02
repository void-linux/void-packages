#
# This helper is for templates using GNU Makefiles.
#
do_build() {
	: ${make_cmd:=make}

	if [ -z "$make_use_env" ]; then
		${make_cmd} \
			CC="$CC" CXX="$CXX" LD="$LD" AR="$AR" RANLIB="$RANLIB" \
			CPP="$CPP" AS="$AS" OBJDUMP="$OBJDUMP" \
			CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" \
			${makejobs} ${make_build_args} ${make_build_target}
	else
		${make_cmd} ${makejobs} ${make_build_args} ${make_build_target}
	fi
}

do_install() {
	: ${make_cmd:=make}
	: ${make_install_target:=install}

	${make_cmd} STRIP=true PREFIX=/usr DESTDIR=${DESTDIR} ${make_install_args} ${make_install_target}
}
