# Helper function to split library & development files

vsplit_lib() {
	# libpkg and lib_short_desc will be reused for devel package
	libpkg="${1:-lib${pkgname}}"
	lib_short_desc="${2:-$short_desc - runtime library}"
	local _lib_depends_line _lib_shlib_line
	if [ -n "$3" ]; then
		_lib_depends_line="depends='$3'"
	fi
	if [ -n "$lib_shlib_provides" ]; then
		_lib_shlib_line="shlib_provides='$lib_shlib_provides'"
	fi
	eval "
	${libpkg}_package() {
		$_lib_depends_line
		$_lib_shlib_line
		short_desc='${lib_short_desc}'
		pkg_install() {
			vmove 'usr/lib/*.so.*'
			if command -v lib_post_install >/dev/null 2>&1; then
				lib_post_install
			fi
			if command -v ${libpkg}_post_install >/dev/null 2>&1; then
				${libpkg}_post_install
			fi
		}
	}
	"
}

vsplit_devel() {
	local _basepkg="${libpkg:-${pkgname}}"
	local _develpkg="${1:-${_basepkg}-devel}"
	local _base_short_desc="${lib_short_desc:-$short_desc}"
	local _devel_short_desc="${2:-${_base_short_desc} - development files}"
	local _devel_depends="${3:-$makedepends ${_basepkg}>=${version}_${revision}}"
	eval "
	${_develpkg}_package() {
		depends='$_devel_depends'
		short_desc='${devel_short_desc:-${_base_short_desc} - development files}'
		pkg_install() {
			for d in usr/include \\
				usr/lib/pkgconfig usr/share/pkgconfig \\
				usr/share/vala usr/share/gir-1.0 \\
				usr/share/man/man2 usr/share/man/man3 \\
				usr/share/aclocal usr/share/sgml \\
				usr/share/cmake usr/lib/cmake \\
				usr/share/gtk-doc usr/lib/qt5/mkspecs
			do
				if [ -d \"\$DESTDIR/\$d\" ]; then
					vmove \"\$d\"
				fi
			done
			for f in \"\$DESTDIR/usr/lib/\"*.so \\
				\"\$DESTDIR/usr/lib/\"*.a \\
				\"\$DESTDIR/usr/bin/\"*-config \\
				\"\$DESTDIR/usr/share/man/man1/\"*-config.1*
			do
				if [ -f \"\$f\" ]; then
					vmove \"\${f#\$DESTDIR}\"
				fi
			done
			if command -v devel_post_install >/dev/null 2>&1; then
				devel_post_install
			fi
			if command -v ${_develpkg}_post_install >/dev/null 2>&1; then
				${_develpkg}_post_install
			fi
		}
	}
	"
}
