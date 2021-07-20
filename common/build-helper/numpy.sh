#
# numpy - build-helper for packages that compile against python3-numpy
#
# This build-helper makes sure packages can find python3-numpy libraries and
# headers on the target architecture rather than the host, as well as making
# sure the gfortran cross compiler is properly identified.

# Even for cross compilation, numpy should be available on the host to ensure
# that the host interpreter doesn't complain about missing deps
if [[ $hostmakedepends != *"python3-numpy"* ]]; then
	hostmakedepends+=" python3-numpy"
fi

if [ "$CROSS_BUILD" ]; then
	if [[ $makedepends != *"python3-numpy"* ]]; then
		makedepends+=" python3-numpy"
	fi

	# python3-setuptools finds numpy libs and headers on the host first;
	# addding search paths up front allows the target to take priority
	CFLAGS+=" -I${XBPS_CROSS_BASE}/${py3_sitelib}/numpy/core/include"
	LDFLAGS+=" -L${XBPS_CROSS_BASE}/${py3_sitelib}/numpy/core/lib"
	LDFLAGS+=" -L${XBPS_CROSS_BASE}/${py3_sitelib}/numpy/random/lib"

	# distutils from python3-numpy looks to environment variables F77 and
	# F90 rather than the XBPS-set FC
	export F77="${FC}"
	export F90="${FC}"

	# When compiling and linking FORTRAN, distutils from python3-numpy
	# refuses respect any linker name except "gfortran"; symlink to the
	# cross-compiler to that the right linker and compiler will be used
	if _gfortran=$(command -v "${FC}"); then
		ln -sf "${_gfortran}" "${XBPS_WRAPPERDIR}/gfortran"
	fi
	unset _gfortran
fi
