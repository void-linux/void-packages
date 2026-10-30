if [ -z "$hostmakedepends" -o "${hostmakedepends##*gcc-go-tools*}" ]; then
	# gc compiler
	if [ -z "$archs" ]; then
		archs="aarch64* armv[567]* i686* x86_64* ppc64le* riscv64*"
	fi
	hostmakedepends+=" go"
	nopie=yes
else
	# gccgo compiler
	if [ -z "$archs" ]; then
		# we have support for these in our gcc
		archs="aarch64* armv[567]* i686* x86_64* ppc64* riscv64*"
	fi
	if [ "$CROSS_BUILD" ]; then
		# target compiler to use; otherwise it'll just call gccgo
		export GCCGO="${XBPS_CROSS_TRIPLET}-gccgo"
	fi
fi

build_helper+=" go"
