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
# Installs a pkg by reading its build template file.
#
make_repoidx()
{
	local f

	case "${XBPS_VERSION}" in
	# >= 0.11.0
	[0-9].[1-9][1-9].[0-9])
		for f in ${XBPS_MACHINE} noarch nonfree/${XBPS_MACHINE}; do
			msg_normal "Updating pkg-index for local repository at:\n"
			msg_normal " $XBPS_PACKAGESDIR/$f\n"
			${XBPS_REPO_CMD} genindex ${XBPS_PACKAGESDIR}/${f} 2>/dev/null
		done
		;;
	*)
		msg_normal "Updating pkg-index for local repository at:\n"
		msg_normal " $XBPS_PACKAGESDIR\n"
		${XBPS_REPO_CMD} genindex ${XBPS_PACKAGESDIR} 2>/dev/null
		;;
	esac
}

_build_pkg_and_update_repos()
{
	local rval f

	[ -z "$BUILD_BINPKG" ] && return 0

	# Build binary package and update local repo index if -B is set.
	xbps_make_binpkg
	if [ $? -ne 0 -a $? -ne 6 ]; then
		return $?
	fi
	make_repoidx

	return 0
}

install_pkg()
{
	local curpkgn="$1" fullpkg pkg cdestdir

	pkg="$curpkgn-$version"
	[ -n "$INSTALLING_DEPS" ] && setup_tmpl $curpkgn
	#
	# Refuse to install the same package that is already installed.
	#
	check_installed_pkg "$pkg"
	if [ $? -eq 1 -o $? -eq 0 ]; then
		instver="$($XBPS_PKGDB_CMD version $pkgname)"
		if [ -n "$instver" -a -z "$DESTDIR_ONLY_INSTALL" ]; then
			echo "=> $pkgname-$instver already installed."
			return 0
		fi
	fi

	# Always fetch distfiles before installing dependencies if
	# template doesn't use nofetch and do_fetch().
	[ -z "$nofetch" ] && fetch_distfiles

	#
	# Install dependencies required by this package.
	#
	if [ -z "$INSTALLING_DEPS" ]; then
		install_dependencies_pkg $pkg || return $?
		#
		# At this point all required deps are installed, and
		# only remaining is the origin package; install it.
		#
		unset INSTALLING_DEPS
		setup_tmpl $curpkgn
		msg_normal "$pkgver: starting installation...\n"
	fi

	# Fetch distfiles after installing required dependencies,
	# because some of them might be required for do_fetch().
	[ -n "$nofetch" ] && fetch_distfiles

	#
	# Fetch, extract, build and install into the destination directory.
	#
	if [ ! -f "$XBPS_EXTRACT_DONE" ]; then
		extract_distfiles || return $?
	fi

	# Apply patches if requested by template file
	if [ ! -f $XBPS_APPLYPATCHES_DONE ]; then
		apply_tmpl_patches || return $?
	fi

	if [ ! -f "$XBPS_CONFIGURE_DONE" ]; then
		configure_src_phase || return $?
		if [ "$INSTALL_TARGET" = "configure" ]; then
			return 0
		fi
	fi

	if [ ! -f "$XBPS_BUILD_DONE" ]; then
		build_src_phase || return $?
		if [ "$INSTALL_TARGET" = "build" ]; then
			return 0
		fi
	fi

	# Install pkg into destdir.
	env XBPS_MACHINE=${XBPS_MACHINE} wrksrc=${wrksrc}	\
		MASTERDIR="${XBPS_MASTERDIR}"			\
		BOOTSTRAP_PKG_REBUILD=$BOOTSTRAP_PKG_REBUILD	\
		CONFIG_FILE=${XBPS_CONFIG_FILE}			\
		${FAKEROOT_CMD} ${FAKEROOT_CMD_ARGS}		\
		${XBPS_LIBEXECDIR}/doinst-helper.sh 		\
		${curpkgn} || return $?

	# Strip binaries/libraries.
	strip_files

	# Always write metadata to package's destdir.
	trap 'remove_pkgdestdir_sighandler $pkgname $KEEP_AUTODEPS' INT
	xbps_write_metadata_pkg
	if [ $? -ne 0 ]; then
		msg_red "cannot write package metadata for '$pkgname'!\n"
		trap - INT
		return 1
	fi
	trap - INT

	# If only installation to destdir, return.
	if [ -n "$DESTDIR_ONLY_INSTALL" ]; then
		if [ -d "$wrksrc" -a -z "$KEEP_WRKSRC" ]; then
			remove_tmpl_wrksrc $wrksrc
		fi
		autoremove_pkg_dependencies $KEEP_AUTODEPS
		_build_pkg_and_update_repos
		return $?
	fi

	# Stow package into masterdir.
	stow_pkg_handler stow || return $?

	# Copy generated pkg metadata files into its metadata dir.
	if [ ! -f ${DESTDIR}/files.plist ]; then
		msg_error "${pkgname}: missing metadata files.plist!"
	fi
	cp -f ${DESTDIR}/files.plist ${XBPS_PKGMETADIR}/${pkgname}
	if [ ! -f ${DESTDIR}/props.plist ]; then
		msg_error "${pkgname}: missing metadata props.plist!"
	fi
	cp -f ${DESTDIR}/props.plist ${XBPS_PKGMETADIR}/${pkgname}
	if [ -f ${DESTDIR}/INSTALL ]; then
		install -m750 ${DESTDIR}/INSTALL \
			${XBPS_PKGMETADIR}/${pkgname}
	fi
	if [ -f ${DESTDIR}/REMOVE ]; then
		install -m750 ${DESTDIR}/REMOVE \
			${XBPS_PKGMETADIR}/${pkgname}
	fi
	#
	# Remove $wrksrc if -C not specified.
	#
	if [ -d "$wrksrc" -a -z "$KEEP_WRKSRC" ]; then
		remove_tmpl_wrksrc $wrksrc
	fi

	#
	# Autoremove packages installed as dependencies if
	# XBPS_PREFER_BINPKG_DEPS is set.
	#
	autoremove_pkg_dependencies $KEEP_AUTODEPS || return $?
	#
	# Build binary package and update local repo index if -B is set.
	#
	_build_pkg_and_update_repos

	return $?
}

#
# Lists files installed by a package.
#
list_pkg_files()
{
	local pkg="$1" ver=

	[ -z $pkg ] && msg_error "unexistent package, aborting.\n"

	ver=$($XBPS_PKGDB_CMD version $pkg)
	if [ -z "$ver" ]; then
		msg_warn "$pkg is not installed.\n"
		return 1
	fi

	cat $XBPS_PKGMETADIR/$pkg/flist
}

#
# Removes a currently installed package (unstow + removed from destdir).
#
remove_pkg()
{
	local subpkg found pkg

	[ -z $pkgname ] && msg_error "unexistent package, aborting.\n"

	for subpkg in ${subpackages}; do
		. ${XBPS_SRCPKGDIR}/${sourcepkg}/${subpkg}.template
		set_tmpl_common_vars
		pkg="${subpkg}-${version}"
		if [ -d "$XBPS_DESTDIR/${pkg}" ]; then
			msg_normal "${pkg}: removing files from destdir...\n"
			rm -rf "$XBPS_DESTDIR/${pkg}"
			found=1
		else
			msg_warn "${pkg}: not installed in destdir!\n"
		fi
		# Remove leftover files in $wrksrc.
		if [ -f "${wrksrc}/.xbps_do_install_${subpkg}_done" ]; then
			rm -f ${wrksrc}/.xbps_do_install_${subpkg}_done
			found=1
		fi
	done

	pkg="${pkgname}-${version}"
	if [ -d "$XBPS_DESTDIR/${pkg}" ]; then
		msg_normal "${pkg}: removing files from destdir...\n"
		rm -rf "$XBPS_DESTDIR/${pkg}"
		found=1
	fi

	[ -f $XBPS_PRE_INSTALL_DONE ] && rm -f $XBPS_PRE_INSTALL_DONE
	[ -f $XBPS_POST_INSTALL_DONE ] && rm -f $XBPS_POST_INSTALL_DONE
	[ -f $XBPS_INSTALL_DONE ] && rm -f $XBPS_INSTALL_DONE

	if [ -n "$DESTDIR_ONLY_INSTALL" ]; then
		if [ -n "$found" ]; then
			return 0
		else
			msg_warn "${pkg}: not installed in destdir!\n"
		fi
	fi

	stow_pkg_handler unstow || return $?

	[ -n "$found" ] && return 0

	return 1
}
