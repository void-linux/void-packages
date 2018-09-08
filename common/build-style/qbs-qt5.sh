#
# This helper is for templates using the Qt Build System (qbs) for Qt5 builds
#
do_configure() {
	qbs-setup-qt /usr/lib/qt5/bin/qmake qt5

	if [ "$XBPS_CROSS_TRIPLET" ]; then
		qbs setup-toolchains /usr/bin/$CC cc
		qbs config profiles.qt5.sysroot /usr/$XBPS_CROSS_TRIPLET
	fi

	qbs-config defaultProfile qt5

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
