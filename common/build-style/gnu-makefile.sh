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

do_check() {
	if [ -z "$make_cmd" ] && [ -z "$make_check_target" ]; then 
		if make -q check 2>/dev/null; then
			:
		else
			if [ $? -eq 2 ]; then
				msg_warn 'No target to "make check".\n'
				return 0
			fi
		fi
	fi

	: ${make_cmd:=make}
	: ${make_check_target:=check}

	${make_cmd} ${make_check_args} ${make_check_target}
}

do_install() {
	: ${make_cmd:=make}
	: ${make_install_target:=install}

	${make_cmd} STRIP=true PREFIX=/usr DESTDIR=${DESTDIR} ${make_install_args} ${make_install_target}
}
