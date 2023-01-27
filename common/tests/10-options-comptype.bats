setup() {
	load lib/testfuncs
	prepare_pkg_test
}

teardown() {
	cleanup_pkg_test
}

@test "XBPS_PKG_COMPTYPE=none" {
	echo XBPS_PKG_COMPTYPE=none > "${tmpconf}"
	./xbps-src -c "${tmprepo}" -r "${tmprepo}" pkg xbps-src-test-pkg
	test -f "${pkgfile}"
	mime=$(file -b --mime-type "${pkgfile}")
	echo "$mime"
	test application/x-tar = "$mime"
}

@test "XBPS_PKG_COMPTYPE=gzip" {
	echo XBPS_PKG_COMPTYPE=gzip > "${tmpconf}"
	./xbps-src -c "${tmprepo}" -r "${tmprepo}" pkg xbps-src-test-pkg
	test -f "${pkgfile}"
	mime=$(file -b --mime-type "${pkgfile}")
	echo "$mime"
	test application/gzip = "$mime"
}

@test "XBPS_PKG_COMPTYPE=bzip2" {
	echo XBPS_PKG_COMPTYPE=bzip2 > "${tmpconf}"
	./xbps-src -c "${tmprepo}" -r "${tmprepo}" pkg xbps-src-test-pkg
	test -f "${pkgfile}"
	mime=$(file -b --mime-type "${pkgfile}")
	echo "$mime"
	test application/x-bzip2 = "$mime"
}

@test "XBPS_PKG_COMPTYPE=xz" {
	echo XBPS_PKG_COMPTYPE=xz > "${tmpconf}"
	./xbps-src -c "${tmprepo}" -r "${tmprepo}" pkg xbps-src-test-pkg
	test -f "${pkgfile}"
	mime=$(file -b --mime-type "${pkgfile}")
	echo "$mime"
	test application/x-xz = "$mime"
}

@test "XBPS_PKG_COMPTYPE=lz4" {
	echo XBPS_PKG_COMPTYPE=lz4 > "${tmpconf}"
	./xbps-src -c "${tmprepo}" -r "${tmprepo}" pkg xbps-src-test-pkg
	test -f "${pkgfile}"
	mime=$(file -b --mime-type "${pkgfile}")
	echo "$mime"
	test application/x-lz4 = "$mime"
}

@test "XBPS_PKG_COMPTYPE=zstd" {
	echo XBPS_PKG_COMPTYPE=zstd > "${tmpconf}"
	./xbps-src -c "${tmprepo}" -r "${tmprepo}" pkg xbps-src-test-pkg
	test -f "${pkgfile}"
	mime=$(file -b --mime-type "${pkgfile}")
	echo "$mime"
	test application/zstd = "$mime"
}
