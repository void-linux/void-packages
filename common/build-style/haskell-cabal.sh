#
# This helper is for templates using Cabal.
#
ghc_version="$( ghc --numeric-version )"

do_configure() {
	: ${make_cmd:="runhaskell Setup"}

    ${make_cmd} configure -O \
        --enable-shared \
        --enable-executable-dynamic \
        --disable-library-vanilla \
        --prefix=/usr \
        --bindir=/usr/bin \
        --libdir=/usr/lib \
        --dynlibdir=/usr/lib \
		--libsubdir=ghc-${ghc_version}/site-local/${ghc_package}-${version} \
        --datadir=/usr/share \
        --datasubdir=ghc-${ghc_version}/site-local/${ghc_package}-${version} \
        --libexecdir=/usr/libexec \
		--docdir=/usr/share/doc/${pkgname} \
        ${configure_args}
}

do_build() {
	: ${make_cmd:="runhaskell Setup"}

	${make_cmd} build
	${make_cmd} register --gen-pkg-config
}

do_install() {
	: ${make_cmd:="runhaskell Setup"}

	${make_cmd} copy --destdir="${DESTDIR}"

	vinstall ${ghc_package}.conf 644 usr/share/ghc-${ghc_version}/package.conf
}

do_check() {
    :
    # TODO
}
