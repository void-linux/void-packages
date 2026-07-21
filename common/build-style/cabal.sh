#
# This helper is for building haskell projects using Cabal.
#

do_configure() {
	: ${cabal_cmd:=cabal}

	local _cabal_project_file="cabal.project"

	if [ -e "${FILESDIR}/${_cabal_project_file}.freeze" ]; then
		cp "${FILESDIR}/${_cabal_project_file}.freeze" .
	fi

	if [ -n "${cabal_index_state}" ]; then
		# index-state alone is enough to fully fix a cabal build
		configure_args+=" --index-state=${cabal_index_state}"
	elif [ -e "${_cabal_project_file}.freeze" ]; then
		# With a freeze file we have to make sure that it fixes
		# the index also
		if ! grep -q '^index-state:' "${_cabal_project_file}.freeze"; then
			msg_error "${_cabal_project_file}.freeze is missing index-state\n"
		fi
	elif [ -e "${_cabal_project_file}" ]; then
		if ! grep -q '^index-state:' "${_cabal_project_file}"; then
			msg_error "${_cabal_project_file} is missing index-state\n"
		fi
	else
		msg_error "cabal build not fixed, set cabal_index_state or add a freeze file to FILESDIR\n"
	fi

	${cabal_cmd} update
	${cabal_cmd} configure --prefix=/usr ${configure_args}
}

do_build() {
	: ${make_cmd:=cabal}

	if [ "$XBPS_TARGET_NO_ATOMIC8" ]; then
		make_build_args+=" --ghc-option=-latomic"
	fi

	${make_cmd} build ${make_build_target} ${makejobs} ${make_build_args}
}

do_check() {
	: ${make_cmd:=cabal}
	: ${make_check_target:=test}

	${make_check_pre} ${make_cmd} ${make_check_target} ${make_check_args}
}

do_install() {
	: ${make_cmd:=cabal}
	: ${make_install_target:=all}

	if ${make_cmd} list-bin ${make_install_target} >/dev/null 2>&1; then
		vbin $(${make_cmd} list-bin ${make_install_target})
	else
		for name in $(${make_cmd} list-bin ${make_install_target} 2>&1 | tr -d '\n ' | grep -Eo "theexecutable'[^']+'" | tr "'" ' ' | awk '{ print $2 }'); do
			local _bin=$(${make_cmd} list-bin exe:$name)
			if [ -s "$_bin" ]; then
				vbin "$_bin"
			fi
		done
	fi
}
