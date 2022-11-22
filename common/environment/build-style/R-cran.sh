makedepends+=" R"
depends+=" R"
create_wrksrc=required
build_wrksrc="${pkgname#R-cran-}"

# default to cran
if [ -z "$distfiles" ]; then
	distfiles="https://cran.r-project.org/src/contrib/${pkgname#R-cran-}_${version//r/-}.tar.gz
	 https://cran.r-project.org/src/contrib/Archive/${pkgname#R-cran-}/${pkgname#R-cran-}_${version//r/-}.tar.gz"
fi
