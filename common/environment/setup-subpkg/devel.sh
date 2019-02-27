# This shell snippet sets the devel_pkg_install function which
# will be used with any devel packages that do not define their own.

devel_pkg_install() {
	local dirs ignores="$1"

	dirs="
	 usr/include
	 usr/lib/pkgconfig
	 usr/share/pkgconfig
	 usr/share/aclocal
	 usr/share/gettext
	 usr/share/vala/vapi
	 usr/share/gir-1.0
	 usr/share/man/man3
	 usr/lib/cmake
	 usr/share/cmake
	 usr/lib/qt5/mkspecs
	 usr/share/qt5/mkspecs
	 usr/lib/qt/mkspecs
	 usr/share/qt/mkspecs
	 usr/share/gtk-doc
	 usr/share/glade/catalogs"

	 # FIXME(maxice8): add a way to ignore certain paths from dirs
	 # in special occasions like glade3 needs usr/share/glade/catalogs
	 # but nobody else needs it besides their own.

	for d in $dirs; do
		if [ -d ${DESTDIR}/${d} ]; then
			mkdir -p ${PKGDESTDIR}/${d%/*}
			mv ${DESTDIR}/${d} ${PKGDESTDIR}/${d}
		fi
	done

	shopt -s nullglob

	# Move .so links and static archivs
	for i in ${DESTDIR}/usr/lib/*.so ${DESTDIR}/usr/lib/*.a; do
	    mkdir -p ${PKGDESTDIR}/usr/lib
	    mv $i ${PKGDESTDIR}/usr/lib
	done

	shopt -u nullglob
}
