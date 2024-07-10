#
# This helper is for building rust projects which use cargo for building
#

do_build() {
	: ${make_cmd:=cargo auditable}

	if ! [[ ${configure_args} =~ .*--profile([[:space:]]|=).* ]]; then
		configure_args+=" --profile=release"
	fi

	${make_cmd} build --locked --target ${RUST_TARGET} ${configure_args}
}

do_check() {
	: ${make_cmd:=cargo auditable}

	${make_check_pre} ${make_cmd} test --locked --target ${RUST_TARGET} \
		${configure_args} ${make_check_args}
}

do_install() {
	: ${make_cmd:=cargo auditable}
	: ${make_install_args:=--path .}

	${make_cmd} install --target ${RUST_TARGET} --root="${DESTDIR}/usr" \
		--offline --locked ${configure_args} ${make_install_args}

	rm -f "${DESTDIR}"/usr/.crates.toml
	rm -f "${DESTDIR}"/usr/.crates2.json
}
