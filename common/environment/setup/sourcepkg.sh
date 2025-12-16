# This shell snippet unsets all variables/functions that can be used in
# the package template (excluding subpackages).

# Exported variables
for var in $(awk 'BEGIN{for (i in ENVIRON) {print i}}' </dev/null); do
	# Those variables in chroot.sh will be kept
	case "$var" in
	BASH_FUNC_*'%%')
		# bash exported functions
		var="${var%??}"
		var="${var#BASH_FUNC_}"
		unset -f "$var"
		;;
	XBPS_* | IN_CHROOT | CHROOT_READY | SOURCE_DATE_EPOCH | NOCOLORS)
		# xbps-src specific
		;;
	SOURCEFORGE_SITE | NONGNU_SITE | XORG_SITE | DEBIAN_SITE | GNOME_SITE)
		;;
	KERNEL_SITE | CPAN_SITE | PYPI_SITE | MOZILLA_SITE | GNU_SITE)
		;;
	FREEDESKTOP_SITE | KDE_SITE | VIDEOLAN_SITE | UBUNTU_SITE)
		;;
	_ | PWD | SHLVL | USER | PATH | SHELL | HOME | LC_COLLATE | LANG | TERM | PS1)
		# known variables for shell
		;;
	DISTCC_HOSTS | DISTCC_DIR)
		;;
	CCACHE_DIR | CCACHE_COMPRESS)
		;;
	HTTP_PROXY | HTTPS_PROXY | SOCKS_PROXY | NO_PROXY | HTTP_PROXY_AUTH)
		;;
	FTP_PROXY | FTP_RETRIES)
		;;
	http_proxy | https_proxy | ftp_proxy | all_proxy | no_proxy)
		;;
	*)
		unset -v "$var"
		;;
	esac
done
unset -v var

## VARIABLES
unset -v pkgname version revision short_desc homepage license maintainer
unset -v archs distfiles checksum build_style build_helper nocross broken
unset -v configure_script configure_args wrksrc build_wrksrc create_wrksrc
unset -v make_build_args make_check_args make_install_args
unset -v make_build_target make_check_target make_install_target
unset -v make_cmd meson_cmd gem_cmd fetch_cmd make_check_pre
unset -v python_version stackage
unset -v cmake_builddir meson_builddir
unset -v meson_crossfile
unset -v qmake_default_version
unset -v gemspec
unset -v go_import_path go_package go_mod_mode
unset -v patch_args disable_parallel_build disable_parallel_check
unset -v keep_libtool_archives make_use_env
unset -v reverts subpackages makedepends hostmakedepends checkdepends depends restricted
unset -v nopie build_options build_options_default bootstrap repository reverts
unset -v CFLAGS CXXFLAGS FFLAGS CPPFLAGS LDFLAGS LD_LIBRARY_PATH
unset -v CC CXX CPP GCC LD AR AS RANLIB NM OBJDUMP OBJCOPY STRIP READELF PKG_CONFIG
unset -v CMAKE_GENERATOR
unset -v scons_use_destdir
# build-helper python3
unset -v PYPREFIX LDSHARED PYTHON_CONFIG PYTHONPATH _PYTHON_SYSCONFIGDATA_NAME

# unset all $build_option_ variables
unset -v "${!build_option_@}"

# hooks/do-extract/00-distfiles
unset -v skip_extraction

# hooks/post-install/03-strip-and-debug-pkgs
unset -v nodebug

# build-helpers/gir.sh for cross builds
unset -v GIR_EXTRA_LIBS_PATH GIR_EXTRA_OPTIONS

## FUNCTIONS
unset -f pre_fetch do_fetch post_fetch
unset -f pre_extract do_extract post_extract
unset -f pre_patch do_patch post_patch
unset -f pre_configure do_configure post_configure
unset -f pre_build do_build post_build
unset -f pre_check do_check post_check
unset -f pre_install do_install post_install
unset -f do_clean
