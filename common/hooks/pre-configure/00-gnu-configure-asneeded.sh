# This hook enables ld(1) --as-needed in gnu-configure packages.

hook() {
	: ${configure_script:=./configure}

	if [ ! -f "${configure_script}" ]; then
		return 0
	fi
	# http://lists.gnu.org/archive/html/libtool-patches/2004-06/msg00002.html
	if [ "$build_style" = "gnu-configure" ]; then
		sed -i "s/^\([ \t]*tmp_sharedflag\)='-shared'/\1='-shared -Wl,--as-needed'/" ${configure_script}
	fi
}
