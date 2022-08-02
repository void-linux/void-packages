makedepends+=" R"
depends+=" R"
wrksrc="${XBPS_BUILDDIR}/${pkgname#R-cran-}"

# default to cran
if [ -z "$distfiles" ]; then
	distfiles="https://cran.r-project.org/src/contrib/${pkgname#R-cran-}_${version//r/-}.tar.gz"
	# Old releases get put into archive, and removed from above location.
	# Use the archive as a fallback to handle that case.
	_archive="https://cran.r-project.org/src/contrib/Archive/${pkgname#R-cran-}"
	if [[ "$XBPS_DISTFILES_MIRROR" != *"$_archive"* ]]; then
		XBPS_DISTFILES_MIRROR+=" $_archive"
	fi
fi
