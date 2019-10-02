makedepends+=" R"
depends+=" R"
distfiles="https://cran.r-project.org/src/contrib/${pkgname#R-cran-}_${version//r/-}.tar.gz"
wrksrc="${XBPS_BUILDDIR}/${pkgname#R-cran-}"
