# Template file for 'chroot-git'
pkgname=chroot-git
version=2.31.1
revision=1
bootstrap=yes
wrksrc="git-${version}"
build_style=gnu-configure
configure_args="--without-curl --without-openssl
 --without-python --without-expat --without-tcltk
 ac_cv_lib_curl_curl_global_init=no ac_cv_lib_expat_XML_ParserCreate=no"
make_check_target=test
makedepends="zlib-devel"
short_desc="GIT Tree History Storage Tool -- for xbps-src use"
maintainer="Enno Boland <gottox@voidlinux.org>"
license="GPL-2.0-only"
homepage="https://git-scm.com/"
distfiles="https://www.kernel.org/pub/software/scm/git/git-${version}.tar.xz"
checksum=9f61417a44d5b954a5012b6f34e526a3336dcf5dd720e2bb7ada92ad8b3d6680

if [ "$CHROOT_READY" ]; then
	hostmakedepends="perl tar"
else
	configure_args+=" --with-zlib=${XBPS_MASTERDIR}/usr"
fi

post_configure() {
	cat <<-EOF >config.mak
	CC_LD_DYNPATH=-L
	NO_INSTALL_HARDLINKS=Yes
	NO_GETTEXT=Yes
	EOF
}

do_install() {
	# remove unneeded stuff.
	make DESTDIR=${wrksrc}/build-tmp install

	vbin ${wrksrc}/build-tmp/usr/bin/git chroot-git
}
