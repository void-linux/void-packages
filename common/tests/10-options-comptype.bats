@test "XBPS_PKG_COMPTYPE=none" {
	load lib/testfuncs
	prepare_pkg_test
	echo XBPS_PKG_COMPTYPE=none > "${tmpconf}"
	./xbps-src -c "${tmprepo}" -r "${tmprepo}" pkg xbps-src-test-pkg
	test -f "${pkgfile}"
	mime=$(file -b --mime-type "${pkgfile}")
	echo "$mime"
	test application/x-tar = "$mime"
	cleanup_pkg_test
}

@test "XBPS_PKG_COMPTYPE=gzip" {
	load lib/testfuncs
	prepare_pkg_test
	echo XBPS_PKG_COMPTYPE=gzip > "${tmpconf}"
	./xbps-src -c "${tmprepo}" -r "${tmprepo}" pkg xbps-src-test-pkg
	test -f "${pkgfile}"
	mime=$(file -b --mime-type "${pkgfile}")
	echo "$mime"
	test application/gzip = "$mime"
	cleanup_pkg_test
}

@test "XBPS_PKG_COMPTYPE=bzip2" {
	load lib/testfuncs
	prepare_pkg_test
	echo XBPS_PKG_COMPTYPE=bzip2 > "${tmpconf}"
	./xbps-src -c "${tmprepo}" -r "${tmprepo}" pkg xbps-src-test-pkg
	test -f "${pkgfile}"
	mime=$(file -b --mime-type "${pkgfile}")
	echo "$mime"
	test application/x-bzip2 = "$mime"
	cleanup_pkg_test
}

@test "XBPS_PKG_COMPTYPE=xz" {
	load lib/testfuncs
	prepare_pkg_test
	echo XBPS_PKG_COMPTYPE=xz > "${tmpconf}"
	./xbps-src -c "${tmprepo}" -r "${tmprepo}" pkg xbps-src-test-pkg
	test -f "${pkgfile}"
	mime=$(file -b --mime-type "${pkgfile}")
	echo "$mime"
	test application/x-xz = "$mime"
	cleanup_pkg_test
}

@test "XBPS_PKG_COMPTYPE=lz4" {
	load lib/testfuncs
	prepare_pkg_test
	echo XBPS_PKG_COMPTYPE=lz4 > "${tmpconf}"
	./xbps-src -c "${tmprepo}" -r "${tmprepo}" pkg xbps-src-test-pkg
	test -f "${pkgfile}"
	mime=$(file -b --mime-type "${pkgfile}")
	echo "$mime"
	test application/x-lz4 = "$mime"
	cleanup_pkg_test
}

@test "XBPS_PKG_COMPTYPE=zstd" {
	load lib/testfuncs
	prepare_pkg_test
	echo XBPS_PKG_COMPTYPE=zstd > "${tmpconf}"
	./xbps-src -c "${tmprepo}" -r "${tmprepo}" pkg xbps-src-test-pkg
	test -f "${pkgfile}"
	mime=$(file -b --mime-type "${pkgfile}")
	echo "$mime"
	test application/zstd = "$mime"
	cleanup_pkg_test
}
