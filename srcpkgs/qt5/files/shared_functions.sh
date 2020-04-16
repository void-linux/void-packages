_cleanup_wrksrc_leak() {
	if [ -d "${PKGDESTDIR}/usr/lib/cmake" ]; then
		# Replace references to ${wrksrc} in cmake files
		vsed -i ${PKGDESTDIR}/usr/lib/cmake/*/*.cmake \
			-e "s;${wrksrc}/host;/usr/lib/qt5;g" \
			-e "s;devices/void-${XBPS_CROSS_TRIPLET}-g++;linux-g++;g"
	fi
	if [ -d "${PKGDESTDIR}/usr/lib/pkgconfig" ]; then
		# Replace references to ${wrksrc} in pkgconfig files
		vsed -i ${PKGDESTDIR}/usr/lib/pkgconfig/*.pc \
			-e "s;${wrksrc}/host;/usr/lib/qt5;g" \
			-e "s;devices/void-${XBPS_CROSS_TRIPLET}-g++;linux-g++;g"
	fi
	# Remove QMAKE_PRL_BUILD_DIR from hint files for static libraries
	# and replace references to ${wrksrc}
	find ${PKGDESTDIR} -iname "*.prl" -exec sed -i "{}" \
		-e "/^QMAKE_PRL_BUILD_DIR/d" \
		-e "s;-L${wrksrc}/qtbase/lib;-L/usr/lib;g" \;
	# Replace ${wrksrc} in project include files
	find ${PKGDESTDIR} -iname "*.pri" -exec sed -i "{}" \
		-e "s;${wrksrc}/qtbase;/usr/lib/qt5;g" \;
}

_msg_cross() {
	msg_normal "***************************************************\n"
	msg_normal "$1 for target ${CROSS_BUILD} ...\n"
	msg_normal "***************************************************\n"
}

_host_tooling_for_target() {
	base=${1##*/}
	dir=${1%%/*}

	_msg_cross " Building ${base}"

	cd ${wrksrc}/${1}
	if [ -x "${wrksrc}/${dir}/bin/${base}" ]; then
		mv -v ${wrksrc}/${dir}/bin/${base}{,-host}
	fi
	[ -f Makefile ] && make clean
	[ -f "${base}.pro" ] && cp -a ${base}.pro{,.orig}
	if [ -f "${FILESDIR}/${base}.pro" ]; then
		# A specific *.pro file is available, use it.
		cp ${FILESDIR}/${base}.pro ${base}.pro
	else
		# Otherwise strip the option(host_build)
		vsed -i ${base}.pro -e "/option(host_build)/d"
	fi
	# Create the Makefile
	[ -f Makefile ] && mv -v Makefile{,.orig}
	${wrksrc}/bin/qmake -o Makefile ${base}.pro

	# Now patch the Makefile(s) to not use the bootstrap libs and
	# use the compiler, linker, flags, etc. for the target arch
	find . -name "Makefile*" -exec sed -i "{}" \
		-e "s; force_bootstrap;;" \
		-e "s;^\(CC\\s*=\).*;\1 $CC;" \
		-e "s;^\(CXX\\s*=\).*;\1 $CXX;" \
		-e "s;^\(LINK\\s*=\).*;\1 $CXX;" \
		-e "s;^\(CFLAGS\\s*=.*\);\1 $CFLAGS;" \
		-e "s;^\(CXXFLAGS\\s*=.*\);\1 $CXXFLAGS;" \
		-e "s;^\(LFLAGS\\s*=.*\);\1 $LDFLAGS;" \
		-e "s;^\(AR\\s*=\).*;\1 $AR cqs;" \
		-e "s;^\(RANLIB\\s*=\).*;\1 $RANLIB;" \
		\;
	# Set a different destination directory and target name
	vsed -i Makefile \
		-e "s;^\(DESTDIR\\s*=\).*;\1 ${DESTDIR}/usr/lib/qt5/bin/;" \
		-e "s;^\(TARGET\\s*=\).*;\1 ${DESTDIR}/usr/lib/qt5/bin/${base}-target;"
	make ${makejobs}
	# Restore profile, if any
	[ -f "${base}.pro.orig" ] && mv -v ${base}.pro{.orig,}
	[ -f Makefile.orig ] && mv -v Makefile{.orig,}
	# Avoid rebuilding the Makefile by changing the rule
	vsed -i Makefile -e 's;^all:.*;all:;'
	vsed -i Makefile -e "s;^Makefile:;Makefile.host:;"
	if [ -x "${wrksrc}/${dir}/bin/${base}-host" ]; then
		mv -v ${wrksrc}/${dir}/bin/${base}{-host,}
		touch ${wrksrc}/${dir}/bin/${base}
	fi
}
