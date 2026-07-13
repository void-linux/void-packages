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

[ -z "$CROSS_BUILD" ] && return 0

if [[ $makedepends != *"python3-numpy"* ]]; then
	makedepends+=" python3-numpy"
fi

# python3-setuptools finds numpy libs and headers on the host first;
# adding search paths up front allows the target to take priority
CFLAGS+=" -I${XBPS_CROSS_BASE}/${py3_sitelib}/numpy/_core/include"
LDFLAGS+=" -L${XBPS_CROSS_BASE}/${py3_sitelib}/numpy/_core/lib"
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

# Write a secondary meson cross file for numpy configuration
if [[ "${build_helper}" = *meson* ]]; then
	_npy_meson_cross="${XBPS_WRAPPERDIR}/meson/xbps_numpy.cross"
	_cross_py_site="${XBPS_CROSS_BASE}/${py3_sitelib}"

	if [ ! -e "${_npy_meson_cross}" ] || [ -n "$XBPS_BUILD_FORCEMODE" ]; then
		mkdir -p "${XBPS_WRAPPERDIR}/meson"
		cat > "${_npy_meson_cross}" <<-EOF
			[properties]
			numpy-include-dir = '${_cross_py_site}/numpy/_core/include'
			pythran-include-dir = '${_cross_py_site}/pythran'
			EOF
	fi
	unset _npy_meson_cross _cross_py_site
fi
