#
# This helper is for templates using the Qt Build System (qbs) for Qt4 builds
#
do_configure() {
	qbs-setup-qt /usr/lib/qt4/bin/qmake qt4
	qbs-config defaultProfile qt4

	# In theory qbs supports generating makefiles, however most projects
	# who utilize qbs utilize behavior qbs apparently can't use when using
	# makefiles
	#qbs generate -g makefile ${configure_args}
}

do_build() {
	qbs build --no-install ${makejobs} config:release ${configure_args}
}

do_install() {
	qbs install --no-build --install-root "$DESTDIR/usr" ${makejobs} \
		config:release ${configure_args}
}
