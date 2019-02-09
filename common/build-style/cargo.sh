#
# This helper is for building rust projects which use cargo for building
#

do_build() {
	: ${make_cmd:=cargo}

	${make_cmd} build --release --target ${RUST_TARGET} ${configure_args}
}

do_check() {
	: ${make_cmd:=cargo}

	${make_cmd} test --release ${make_check_args}
}

do_install() {
	: ${make_cmd:=cargo}

	${make_cmd} install --path . --target ${RUST_TARGET} --root="${DESTDIR}/usr" \
		${make_install_args}
	rm "${DESTDIR}"/usr/.crates.toml
}
