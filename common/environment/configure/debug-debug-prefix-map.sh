local _wrksrc="$wrksrc${build_wrksrc:+/$build_wrksrc}"
case "$build_style" in
cmake)
	CFLAGS="${CFLAGS} -ffile-prefix-map=$_wrksrc/${cmake_builddir:-build}=."
	CXXFLAGS="${CXXFLAGS} -ffile-prefix-map=$_wrksrc/${cmake_builddir:-build}=."
	;;
meson)
	CFLAGS="${CFLAGS} -ffile-prefix-map=$_wrksrc/${meson_builddir:-build}=."
	CXXFLAGS="${CXXFLAGS} -ffile-prefix-map=$_wrksrc/${meson_builddir:-build}=."
	;;
*)
	CFLAGS="${CFLAGS} -ffile-prefix-map=$_wrksrc=."
	CXXFLAGS="${CXXFLAGS} -ffile-prefix-map=$_wrksrc=."
esac

unset _wrksrc
