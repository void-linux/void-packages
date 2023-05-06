makedepends+=" R"
depends+=" R"
create_wrksrc=required
build_wrksrc="${pkgname#R-cran-}"

# default to cran
if [ -z "$distfiles" ]; then
	distfiles=" https://cran.r-project.org/src/contrib/Archive/${pkgname#R-cran-}/${pkgname#R-cran-}_${version//r/-}.tar.gz"
	case " $XBPS_DISTFILES_MIRROR " in
	*" https://cran.r-project.org/src/contrib "*) ;;
	*) XBPS_DISTFILES_MIRROR+=" https://cran.r-project.org/src/contrib" ;;
	esac
fi
