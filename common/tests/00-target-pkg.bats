setup() {
	load lib/testfuncs
	prepare_pkg_test
}

teardown() {
	cleanup_pkg_test
}

@test "Build simple pkg" {
	./xbps-src -c "${tmprepo}" -r "${tmprepo}" pkg xbps-src-test-pkg
	test -f "${pkgfile}"
}
