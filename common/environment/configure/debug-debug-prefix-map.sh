local _wrksrc="$wrksrc${build_wrksrc:+/$build_wrksrc}"
case "$build_style" in
cmake)
	CFLAGS="${CFLAGS} -fdebug-prefix-map=$_wrksrc/${cmake_builddir:-build}=."
	CXXFLAGS="${CXXFLAGS} -fdebug-prefix-map=$_wrksrc/${cmake_builddir:-build}=."
	;;
meson)
	CFLAGS="${CFLAGS} -fdebug-prefix-map=$_wrksrc/${meson_builddir:-build}=."
	CXXFLAGS="${CXXFLAGS} -fdebug-prefix-map=$_wrksrc/${meson_builddir:-build}=."
	;;
*)
	CFLAGS="${CFLAGS} -fdebug-prefix-map=$_wrksrc=."
	CXXFLAGS="${CXXFLAGS} -fdebug-prefix-map=$_wrksrc=."
esac

unset _wrksrc
