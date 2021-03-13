@test "Build simple pkg" {
	load lib/testfuncs
	prepare_pkg_test
	./xbps-src -c "${tmprepo}" -r "${tmprepo}" pkg xbps-src-test-pkg
	test -f "${pkgfile}"
	cleanup_pkg_test
}
