#
# This helper is for templates building slashpackage software.
# http://cr.yp.to/slashpackage.html
#
# required variables
#
#   build_style=slashpackage
#   build_wrksrc=${pkgname}-${version}
#   distfiles=<download link>
#
# example (daemontools)
#
#   Template file for 'daemontools'
#   pkgname=daemontools
#   version=0.76
#   revision=1
#   build_wrksrc=${pkgname}-${version}
#   build_style=slashpackage
#   short_desc="A collection of tools for managing UNIX services"
#   maintainer="bougyman <tj@geoforce.com>"
#   license="Public Domain"
#   homepage="http://cr.yp.to/daemontools.html"
#   distfiles="http://cr.yp.to/daemontools/${pkgname}-${version}.tar.gz"

do_build() {
	package/compile
}

do_install() {
	for command in command/*; do
		vbin $command
	done
}
