# This shell snippet unsets all variables/functions that can be used in
# the package template (excluding subpackages).

## VARIABLES
unset -v pkgname version revision short_desc homepage license maintainer
unset -v only_for_archs distfiles checksum build_style nocross broken
unset -v configure_script configure_args wrksrc build_wrksrc create_wrksrc
unset -v make_cmd make_build_args make_install_args make_build_target make_install_target python_version stackage
unset -v patch_args disable_parallel_build keep_libtool_archives make_use_env
unset -v reverts subpackages makedepends hostmakedepends checkdepends depends restricted
unset -v nopie build_options build_options_default bootstrap repository reverts
unset -v CFLAGS CXXFLAGS FFLAGS CPPFLAGS LDFLAGS LD_LIBRARY_PATH
unset -v CC CXX CPP GCC LD AR AS RANLIB NM OBJDUMP OBJCOPY STRIP READELF

# hooks/do-extract/00-distfiles
unset -v skip_extraction

# hooks/post-install/03-strip-and-debug-pkgs
unset -v nodebug

## FUNCTIONS
unset -f pre_fetch do_fetch post_fetch
unset -f pre_extract do_extract post_extract
unset -f pre_configure do_configure post_configure
unset -f pre_build do_build post_build
unset -f pre_check do_check post_check
unset -f pre_install do_install post_install
unset -f do_clean
