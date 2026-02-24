#
# This helper is for templates using R-cran.
#
do_install() {
	mkdir -p ${DESTDIR}/usr/lib/R/library
	( cd .. && R CMD INSTALL -l ${DESTDIR}/usr/lib/R/library ${pkgname#R-cran-} )
}
