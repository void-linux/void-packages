setup() {
	load lib/testfuncs
	prepare_pkg_test jobcounter
}

teardown() {
	cleanup_pkg_test
}

@test "by default, one job" {
	./xbps-src -c "${tmprepo}" -r "${tmprepo}" pkg xbps-src-test-jobcounter
	test -f "${pkgfile}"
	jobs=$(tar xOf ${pkgfile} ./etc/jobs)
	echo "$jobs"
	test 1 = "$jobs"
}

@test "-j 11" {
	./xbps-src -c "${tmprepo}" -r "${tmprepo}" -j 11 pkg xbps-src-test-jobcounter
	test -f "${pkgfile}"
	jobs=$(tar xOf ${pkgfile} ./etc/jobs)
	echo "$jobs"
	test 11 = "$jobs"
}

@test "XBPS_MAKEJOBS=6" {
	echo XBPS_MAKEJOBS=6 > "${tmpconf}"
	./xbps-src -c "${tmprepo}" -r "${tmprepo}" pkg xbps-src-test-jobcounter
	test -f "${pkgfile}"
	jobs=$(tar xOf ${pkgfile} ./etc/jobs)
	echo "$jobs"
	test 6 = "$jobs"
}

@test "-j 2 XBPS_MAKEJOBS=5" {
	echo XBPS_MAKEJOBS=5 > "${tmpconf}"
	./xbps-src -c "${tmprepo}" -r "${tmprepo}" -j 2 pkg xbps-src-test-jobcounter
	test -f "${pkgfile}"
	jobs=$(tar xOf ${pkgfile} ./etc/jobs)
	echo "$jobs"
	test 2 = "$jobs"
}
