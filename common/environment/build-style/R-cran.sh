makedepends+=" R"
depends+=" R"
wrksrc="${XBPS_BUILDDIR}/${pkgname#R-cran-}"

# default to cran
if [ -z "$distfiles" ]; then
	distfiles="https://cran.r-project.org/src/contrib/${pkgname#R-cran-}_${version//r/-}.tar.gz"
fi
