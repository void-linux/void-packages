#
# This helper is for building rust projects which use cargo for building
#

do_configure() {
	mkdir -p .cargo
	# respect makejobs, do cross stuff
	cat > .cargo/config <<EOF
[build]
jobs = ${makejobs#*j}
target = "${RUST_TARGET}"

[target.${RUST_TARGET}]
linker = "${CC}"
EOF
}

do_build() {
	: ${make_cmd:=cargo}

	${make_cmd} build --release ${configure_args}
}

do_check() {
	: ${make_cmd:=cargo}

	${make_cmd} test --release ${make_check_args}
}

do_install() {
	: ${make_cmd:=cargo}

	${make_cmd} install --root="${DESTDIR}/usr" ${make_install_args}
	rm "${DESTDIR}"/usr/.crates.toml
}
