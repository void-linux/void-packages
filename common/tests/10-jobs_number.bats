@test "by default, one job" {
	load lib/testfuncs
	prepare_pkg_test jobcounter
	./xbps-src -c "${tmprepo}" -r "${tmprepo}" pkg xbps-src-test-jobcounter
	test -f "${pkgfile}"
	jobs=$(tar xOf ${pkgfile} ./etc/jobs)
	echo "$jobs"
	test 1 = "$jobs"
	cleanup_pkg_test
}

@test "-j 11" {
	load lib/testfuncs
	prepare_pkg_test jobcounter
	./xbps-src -c "${tmprepo}" -r "${tmprepo}" -j 11 pkg xbps-src-test-jobcounter
	test -f "${pkgfile}"
	jobs=$(tar xOf ${pkgfile} ./etc/jobs)
	echo "$jobs"
	test 11 = "$jobs"
	cleanup_pkg_test
}

@test "XBPS_MAKEJOBS=6" {
	load lib/testfuncs
	prepare_pkg_test jobcounter
	echo XBPS_MAKEJOBS=6 > "${tmpconf}"
	./xbps-src -c "${tmprepo}" -r "${tmprepo}" pkg xbps-src-test-jobcounter
	test -f "${pkgfile}"
	jobs=$(tar xOf ${pkgfile} ./etc/jobs)
	echo "$jobs"
	test 6 = "$jobs"
	cleanup_pkg_test
}

@test "-j 2 XBPS_MAKEJOBS=5" {
	load lib/testfuncs
	prepare_pkg_test jobcounter
	echo XBPS_MAKEJOBS=5 > "${tmpconf}"
	./xbps-src -c "${tmprepo}" -r "${tmprepo}" -j 2 pkg xbps-src-test-jobcounter
	test -f "${pkgfile}"
	jobs=$(tar xOf ${pkgfile} ./etc/jobs)
	echo "$jobs"
	test 2 = "$jobs"
	cleanup_pkg_test
}
