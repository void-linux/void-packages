#-
# Copyright (c) 2008-2011 Juan Romero Pardines.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#-

#
# Runs the "configure" phase for a pkg. This setups the Makefiles or any
# other stuff required to be able to build binaries or such.
#

# This variable can be used for packages wanting to use common arguments
# to GNU configure scripts.
#
export CONFIGURE_SHARED_ARGS="--prefix=/usr --sysconfdir=/etc \
	--infodir=/usr/share/info --mandir=/usr/share/man"

do_gnu_configure()
{
	#
	# Packages using GNU autoconf
	#
	${configure_script} ${CONFIGURE_SHARED_ARGS} ${configure_args}
}

do_configure()
{
	#
	# Packages using custom configure scripts.
	#
	${configure_script} ${configure_args}
}

do_perl_configure()
{
	#
	# Packages that are perl modules and use Makefile.PL files.
	# They are all handled by the helper perl-module.sh.
	#
	. $XBPS_HELPERSDIR/perl-module.sh
	perl_module_build $pkgname
}

configure_src_phase()
{
	local f lver

	[ -z $pkgname ] && return 1

	# Apply patches if requested by template file
	if [ ! -f $XBPS_APPLYPATCHES_DONE ]; then
		apply_tmpl_patches
	fi

	#
	# Skip this phase for: meta-template, only-install, custom-install,
	# gnu_makefile and python-module style builds.
	#
	[ "$build_style" = "meta-template" -o	\
	  "$build_style" = "only-install" -o	\
	  "$build_style" = "custom-install" -o	\
	  "$build_style" = "gnu_makefile" -o \
	  "$build_style" = "python-module" ] && return 0

	if [ -n "$revision" ]; then
		lver="${version}_${revision}"
	else
		lver="${version}"
	fi

	cd $wrksrc || msg_error "unexistent build directory [$wrksrc].\n"

	# Run pre_configure func.
	if [ ! -f $XBPS_PRECONFIGURE_DONE ]; then
		run_func pre_configure
		if [ $? -eq 0 ]; then
			msg_normal "'$pkgname-$lver': pre_configure phase done.\n"
			touch -f $XBPS_PRECONFIGURE_DONE
		fi
	fi

	[ -z "$configure_script" ] && configure_script="./configure"

	cd $wrksrc || return 1
	if [ -n "$build_wrksrc" ]; then
		cd $build_wrksrc || return 1
	fi

	case "$build_style" in
	gnu_configure|gnu-configure) run_func do_gnu_configure ;;
	configure) run_func do_configure ;;
	perl-module|perl_module) run_func do_perl_configure ;;
	*)
		#
		# Unknown build_style type won't work :-)
		#
		msg_error "'$pkgname-$lver': unknown build_style [$build_style]\n"
		;;
	esac

	msg_normal "'$pkgname-$lver': configure phase done.\n"

	# Run post_configure func.
	if [ ! -f $XBPS_POSTCONFIGURE_DONE ]; then
		run_func post_configure
		if [ $? -eq 0 ]; then
			msg_normal "'$pkgname-$lver': post_configure phase done."
			touch -f $XBPS_POSTCONFIGURE_DONE
		fi
	fi

	touch -f $XBPS_CONFIGURE_DONE
}
