case "$build_style" in
cmake)
	CFLAGS="${CFLAGS} -fdebug-prefix-map=$wrksrc/${cmake_builddir:-build}=."
	CXXFLAGS="${CXXFLAGS} -fdebug-prefix-map=$wrksrc/${cmake_builddir:-build}=."
	;;
meson)
	CFLAGS="${CFLAGS} -fdebug-prefix-map=$wrksrc/${meson_builddir:-build}=."
	CXXFLAGS="${CXXFLAGS} -fdebug-prefix-map=$wrksrc/${meson_builddir:-build}=."
	;;
*)
	CFLAGS="${CFLAGS} -fdebug-prefix-map=$wrksrc=."
	CXXFLAGS="${CXXFLAGS} -fdebug-prefix-map=$wrksrc=."
esac
