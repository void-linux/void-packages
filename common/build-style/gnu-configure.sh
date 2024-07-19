#
# This helper is for templates using GNU configure scripts.
#
do_configure() {
	: ${configure_script:=./configure}

	export lt_cv_sys_lib_dlsearch_path_spec="/usr/lib64 /usr/lib32 /usr/lib /lib /usr/local/lib"
	${configure_script} ${configure_args}
}

do_build() {
	: ${make_cmd:=make}

	export lt_cv_sys_lib_dlsearch_path_spec="/usr/lib64 /usr/lib32 /usr/lib /lib /usr/local/lib"
	${make_cmd} ${makejobs} ${make_build_args} ${make_build_target}
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

	${make_check_pre} ${make_cmd} ${makejobs} ${make_check_args} ${make_check_target}
}

do_install() {
	: ${make_cmd:=make}
	: ${make_install_target:=install}

	${make_cmd} DESTDIR=${DESTDIR} ${make_install_args} ${make_install_target}
}
