distdir="${BATS_TEST_DIRNAME}/../.."
template=
tmprepodir=
tmprepo=
tmpconf=

prepare_pkg_test() {
	template=${1:-pkg}
	cd "${distdir}"
	tmprepodir="$(mktemp -d -p ${PWD}/hostdir/binpkgs)"
	tmprepo="$(basename ${tmprepodir})"
	tmpconf="etc/conf.${tmprepo}"
	pkgfile="${tmprepodir}/xbps-src-test-${template}-1_1.$(xbps-uhelper arch).xbps"
	rm -fr srcpkgs/xbps-src-test-${template}
	mkdir srcpkgs/xbps-src-test-${template}
	cp "${BATS_TEST_DIRNAME}/templates/${template}" srcpkgs/xbps-src-test-${template}/template
	echo XBPS_SUCMD=true > "${tmpconf}"
}

cleanup_pkg_test() {
	rm -r srcpkgs/xbps-src-test-${template}
	rm -r "${tmprepodir}"
	rm "etc/conf.${tmprepo}"
}
