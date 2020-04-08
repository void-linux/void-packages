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

