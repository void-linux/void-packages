#!/bin/bash
# vim: set ts=4 sw=4 et:

usage() {
	cat << _EOF
$(basename $0): [options] <target> [arguments]

Targets: (only one may be specified)

 binary-bootstrap [arch]
   Install bootstrap packages from host repositories into <masterdir>.
   If the optional 'arch' argument is set, it will install bootstrap packages
   from this architecture, and its required xbps utilities. The <masterdir>
   will be initialized for chroot operations.

 bootstrap
   Build and install from source the bootstrap packages into <masterdir>.

 bootstrap-update
   Updates bootstrap packages with latest versions available from registered
   repositories in the XBPS configuration file.

 build <pkgname>
   Build package source (fetch + extract + configure + build).

 build-pkg <pkgname>
   Build binary package for <pkgname> and all required dependencies.

 chroot
   Enter to the chroot in <masterdir>.

 clean <pkgname>
   Remove <pkgname> build directory.

 remove-autodeps
   Removes all package dependencies installed automatically.

 configure <pkgname>
   Configure a package (fetch + extract + configure).

 extract <pkgname>
   Extract package source distribution file(s) into the build directory.
   By default set to <masterdir>/builddir.

 fetch <pkgname>
   Download package source distribution file(s).

 install-destdir <pkgname>
   Install target package into <destdir> but not building the binary package
   and not removing build directory for inspection purposes.

 remove-destdir <pkgname>
   Remove target package from <destdir>. If <pkgname>-<version> is not matched
   from build template nothing is removed.

 show <pkgname>
   Show information for the specified package.

 show-build-deps <pkgname>
   Show required build dependencies for <pkgname>.

 show-deps <pkgname>
   Show required run-time dependencies for <pkgname>. Package must be
   installed into destdir.

 show-files <pkgname>
   Show files installed by <pkgname>. Package must be installed into destdir.

 show-options <pkgname>
   Show available build options by <pkgname>.

 show-shlib-provides <pkgname>
   Show list of provided shlibs for <pkgname>. Package must be installed into destdir.

 show-shlib-requires <pkgname>
   Show list of required shlibs for <pkgname>. Package must be installed into destdir.

 zap
   Removes a masterdir but preserving ccache, distcc and host directories.

Options:
 -a  <profile>
     Cross compile packages for this profile. Supported values:

     armv6hf-musl   - for ARMv6 EABI (LE Hard Float) Musl/Linux
     armv6hf        - for ARMv6 EABI (LE Hard Float) GNU/Linux
     armv7hf-musl   - for ARMv7 EABI (LE Hard Float) Musl/Linux
     armv7hf        - for ARMv7 EABI (LE Hard Float) GNU/Linux
     i686-musl      - for i686 Musl/Linux
     i686           - for i686 GNU/Linux
     mips           - for MIPS o32 (BE Soft Float) GNU/Linux
     mipsel         - for MIPS o32 (LE Soft Float) GNU/Linux
     x86_64-musl    - for x86_64 Musl/Linux

 -C  Do not remove build directory, automatic dependencies and
     package destdir after successful install.

 -f  Force building and registering binary packages into the local repository,
     even if same version is already registered.

 -g  Enable building -dbg packages with debugging symbols.

 -H  <hostdir>
     Absolute path to a directory to be bind mounted at <masterdir>/host.
     The host directory stores binary packages, sources and package dependencies
     downloaded from remote repositories.

 -h  Usage output.

 -I  Ignore required dependencies, useful for extracting/fetching sources.

 -j  Number of parallel build jobs to use when building packages.

 -L  Disable ASCII colors.

 -m  <masterdir>
     Absolute path to a directory to be used as masterdir.
     The masterdir is the main directory to build/store/compile packages.

 -N  Disable use of remote repositories to resolve dependencies.

 -o  <opt,~opt2,...>
     Enable or disable (prefixed with ~) package build options.
     Supported options can be shown with the 'show-options' target.

 -r  <repo>
     Use an alternative local repository to store generated binary packages.
     If unset defaults to <masterdir>/host/binpkgs. If set the binpkgs will
     be stored into <masterdir>/host/binpkgs/<repo>.
     This alternative repository will also be used to resolve dependencies.
_EOF
}

check_reqhost_utils() {
	local broken

	[ -n "$IN_CHROOT" ] && return 0

	for f in ${REQHOST_UTILS}; do
		if ! command -v ${f} &>/dev/null; then
			echo "${f} is missing in your system, can't continue!"
			broken=1
		fi
	done
	[ -n "$broken" ] && exit 1
	[ -z "$1" ] && return 0

	for f in ${REQHOST_UTILS_BOOTSTRAP}; do
		if ! command -v ${f} &>/dev/null; then
			echo "${f} is missing in your system, can't continue!"
			broken=1
		fi
	done
	[ -n "$broken" ] && exit 1
}

check_config_vars() {
    if [ -s "$XBPS_CONFIG_FILE" ]; then
        . $XBPS_CONFIG_FILE &>/dev/null
    fi
    if [ -z "$XBPS_MASTERDIR" ]; then
        export XBPS_MASTERDIR="${XBPS_DISTDIR}/masterdir"
    fi
	if [ -d "$XBPS_MASTERDIR" -a ! -w "$XBPS_MASTERDIR" ]; then
		echo "ERROR: not enough perms for masterdir $XBPS_MASTERDIR."
		exit 1
	fi
}

check_build_requirements() {
    local found

    for f in $XBPS_SHUTILSDIR/*.sh; do
	    [ -r $f ] && . $f
    done
    for f in $XBPS_COMMONDIR/environment/setup/*.sh; do
	    [ -r $f ] && . $f
    done

    if [ -z "$XBPS_SRC_REQ" -o -z "$XBPS_UTILS_REQ" -o -z "$XBPS_UTILS_API_REQ" ]; then
	    echo "ERROR: cannot satisfy xbps requirements!"
    exit 1
    fi
    case "$XBPS_TARGET" in
        *bootstrap*) found=1;;
        *) ;;
    esac
    if [ -z "$found" ]; then
        xbps-uhelper cmpver $(echo "$XBPS_SRC_VERSION"|awk '{print $1}') "$XBPS_SRC_REQ"
	    if [ $? -eq 255 ]; then
		    echo "ERROR: this xbps-src version is outdated! (>=$XBPS_SRC_REQ is required)"
		    echo "Bootstrap packages must be updated with 'xbps-src bootstrap-update'"
		    exit 1
	    fi
	    xbps-uhelper cmpver "$XBPS_VERSION" "$XBPS_UTILS_REQ"
	    if [ $? -eq 255 ]; then
		    echo "ERROR: requires xbps-$XBPS_UTILS_REQ API: $XBPS_UTILS_API_REQ"
		    echo "Bootstrap packages must be updated with 'xbps-src bootstrap-update'"
		    exit 1
	    fi
	    xbps-uhelper cmpver "$XBPS_APIVER" "$XBPS_UTILS_API_REQ"
	    if [ $? -eq 255 ]; then
		    echo "ERROR: requires xbps-$XBPS_UTILS_REQ API: $XBPS_UTILS_API_REQ"
		    echo "Bootstrap packages must be updated with 'xbps-src bootstrap-update'"
		    exit 1
	    fi
    fi
    # Set XBPS_REPOSITORY to our current branch.
    if [ -z "$XBPS_ALT_REPOSITORY" ]; then
	    pushd "$PWD" &>/dev/null
	    cd $XBPS_DISTDIR
	    _gitbranch="$(git symbolic-ref --short HEAD 2>/dev/null)"
	    if [ -n "${_gitbranch}" -a "${_gitbranch}" != "master" ]; then
		    export XBPS_REPOSITORY="${XBPS_REPOSITORY}/${_gitbranch}"
		    msg_normal "Using \`$XBPS_REPOSITORY\' as local repository.\n"
	    fi
	    popd &>/dev/null
    else
        export XBPS_REPOSITORY="${XBPS_REPOSITORY}/${XBPS_ALT_REPOSITORY}"
        msg_normal "Using \`$XBPS_REPOSITORY\' as local repository.\n"
    fi
}

install_bbotstrap() {
    [ -n "$CHROOT_READY" ] && return
	# binary bootstrap
	msg_normal "Installing bootstrap from binary package repositories...\n"
	# XBPS_TARGET_PKG == arch
	if [ -n "$XBPS_TARGET_PKG" ]; then
		_bootstrap_arch="env XBPS_TARGET_ARCH=$XBPS_TARGET_PKG"
        if [ "${XBPS_TARGET_PKG}" != "${XBPS_TARGET_PKG#*-}" ]; then
            _subarch="-${XBPS_TARGET_PKG#*-}"
        fi
	fi
	${_bootstrap_arch} xbps-install -S ${XBPS_INSTALL_ARGS} -c host/repocache -r $XBPS_MASTERDIR -y base-chroot${_subarch}
	if [ $? -ne 0 ]; then
		msg_error "Failed to install bootstrap packages!\n"
	fi
	# Reconfigure base-directories.
	xbps-reconfigure -r $XBPS_MASTERDIR -f base-directories &>/dev/null
	msg_normal "Installed bootstrap successfully!\n"
	chroot_prepare $XBPS_TARGET_PKG || msg_error "Failed to initialize chroot!\n"
}

masterdir_zap() {
	for f in bin boot builddir destdir dev etc home lib lib32 lib64 mnt \
		opt proc root run sbin sys tmp usr var xbps .xbps_chroot_init; do
		if [ -d "$XBPS_MASTERDIR/$f" ]; then
			echo "Removing directory $XBPS_MASTERDIR/$f ..."
			rm -rf $XBPS_MASTERDIR/$f
		elif [ -h "$XBPS_MASTERDIR/$f" ]; then
			echo "Removing link $XBPS_MASTERDIR/$f ..."
			rm -f $XBPS_MASTERDIR/$f
		elif [ -f "$XBPS_MASTERDIR/$f" ]; then
			echo "Removing file $XBPS_MASTERDIR/$f ..."
			rm -f $XBPS_MASTERDIR/$f
		fi
	done
	echo "$XBPS_MASTERDIR masterdir cleaned up."
}

exit_func() {
	if [ -z "$XBPS_KEEP_ALL" ]; then
		if [ -n "$IN_CHROOT" ]; then
			remove_pkg_autodeps
		fi
    fi
    if [ -n "$sourcepkg" ]; then
	    remove_pkg $XBPS_CROSS_BUILD
	    remove_pkg_wrksrc
    fi
	if [ -z "$IN_CHROOT" ]; then
		msg_red "xbps-src: a failure has ocurred! exiting...\n"
	fi
	exit 2
}

#
# main()
#
while getopts "a:CfghH:Ij:Lm:No:r:V" opt; do
	case $opt in
	a) readonly XBPS_CROSS_BUILD="$OPTARG";;
	C) readonly XBPS_KEEP_ALL=1;;
	f) readonly XBPS_BUILD_FORCEMODE=1;;
	g) readonly XBPS_DEBUG_PKGS=1;;
	H) readonly XBPS_HOSTDIR="$(readlink -m $OPTARG 2>/dev/null)";;
	h) usage && exit 0;;
	I) readonly XBPS_SKIP_DEPS=1;;
	j) readonly XBPS_MAKEJOBS="$OPTARG";;
	L) export NOCOLORS=1;;
	m) readonly XBPS_MASTERDIR=$(readlink -m $OPTARG 2>/dev/null);;
	N) readonly XBPS_SKIP_REMOTEREPOS=1;;
	o) readonly XBPS_BUILD_OPTS="$OPTARG";;
	r) readonly XBPS_ALT_REPOSITORY="$OPTARG";;
	V) echo $XBPS_SRC_VERSION && exit 0;;
	--) shift; break;;
	esac
done
shift $(($OPTIND - 1))

[ $# -eq 0 -o $# -gt 3 ] && usage && exit 1

umask 022

#
# Check for required utilities in host system.
#
# Required utilities in host system for the bootstrap target.
readonly REQHOST_UTILS_BOOTSTRAP="awk bash bison sed gcc g++ msgfmt makeinfo \
	perl fakeroot tar xz gzip bzip2 patch flex"

# Required utilities in host system for chroot ops.
readonly REQHOST_UTILS="xbps-install xbps-query xbps-rindex xbps-uhelper \
	xbps-reconfigure xbps-remove xbps-create git"

check_reqhost_utils

if [ -n "$IN_CHROOT" ]; then
    readonly XBPS_CONFIG_FILE=/etc/xbps/xbps-src.conf
	readonly XBPS_DISTDIR=/xbps-packages
else
    _distdir="$(dirname $0)"
    if [ "${_distdir}" = "." ]; then
        readonly XBPS_DISTDIR="$(pwd -P)"
    else
        readonly XBPS_DISTDIR="${_distdir}"
    fi
    readonly XBPS_CONFIG_FILE=$XBPS_DISTDIR/etc/conf
fi

#
# Check configuration vars before anyting else, and set defaults vars.
#
check_config_vars

if [ -n "$IN_CHROOT" ]; then
	readonly XBPS_UHELPER_CMD="xbps-uhelper"
	readonly XBPS_INSTALL_CMD="xbps-install"
	readonly XBPS_QUERY_CMD="xbps-query"
	readonly XBPS_RINDEX_CMD="xbps-rindex"
	readonly XBPS_RECONFIGURE_CMD="xbps-reconfigure"
	readonly XBPS_REMOVE_CMD="xbps-remove"
else
	readonly XBPS_UHELPER_CMD="xbps-uhelper -r $XBPS_MASTERDIR"
	readonly XBPS_INSTALL_CMD="xbps-install -C _empty.conf_ --repository=$XBPS_REPOSITORY -r $XBPS_MASTERDIR"
	readonly XBPS_QUERY_CMD="xbps-query -C _empty.conf_ --repository=$XBPS_REPOSITORY -r $XBPS_MASTERDIR"
	readonly XBPS_RINDEX_CMD="xbps-rindex"
	readonly XBPS_RECONFIGURE_CMD="xbps-reconfigure -r $XBPS_MASTERDIR"
	readonly XBPS_REMOVE_CMD="xbps-remove -r $XBPS_MASTERDIR"
fi
if [ -n "$XBPS_HOSTDIR" ]; then
	export XBPS_REPOSITORY=$XBPS_HOSTDIR/binpkgs
	readonly XBPS_SRCDISTDIR=$XBPS_HOSTDIR/sources
else
	export XBPS_REPOSITORY=$XBPS_MASTERDIR/host/binpkgs
	readonly XBPS_SRCDISTDIR=$XBPS_MASTERDIR/host/sources
fi
readonly XBPS_SRCPKGDIR=$XBPS_DISTDIR/srcpkgs
readonly XBPS_COMMONDIR=$XBPS_DISTDIR/common
readonly XBPS_SHUTILSDIR=$XBPS_COMMONDIR/xbps-src/shutils
readonly XBPS_DESTDIR=$XBPS_MASTERDIR/destdir
readonly XBPS_BUILDDIR=$XBPS_MASTERDIR/builddir
readonly XBPS_TRIGGERSDIR=$XBPS_SRCPKGDIR/xbps-triggers/files
readonly XBPS_CROSSPFDIR=$XBPS_COMMONDIR/cross-profiles
readonly XBPS_BUILDSTYLEDIR=$XBPS_COMMONDIR/build_style
readonly XBPS_LIBEXECDIR=$XBPS_COMMONDIR/xbps-src/libexec
readonly CHROOT_CMD=$XBPS_LIBEXECDIR/xbps-src-chroot-helper

# XBPS_FETCH_CMD can be overriden
export XBPS_FETCH_CMD="xbps-uhelper fetch"
readonly XBPS_DIGEST_CMD="xbps-uhelper digest"
readonly XBPS_CMPVER_CMD="xbps-uhelper cmpver"

readonly XBPS_VERSION=$(xbps-uhelper -V|awk '{print $2}')
readonly XBPS_APIVER=$(xbps-uhelper -V|awk '{print $4}')
readonly XBPS_SRC_VERSION="@@XBPS_SRC_VERSION@@"
readonly FAKEROOT_CMD="fakeroot --"
readonly XBPS_MACHINE=$(uname -m)

XBPS_TARGET="$1"
XBPS_TARGET_PKG="$2"

# Check if stdout is a tty; if false disable colors.
test -t 1 || export NOCOLORS=1

if [ "$(id -u)" -eq 0 ]; then
    echo "ERROR: root cannot use xbps-src, switch to a regular user."
    exit 1
fi

if [ -f $XBPS_MASTERDIR/.xbps_chroot_init ]; then
	export CHROOT_READY=1
fi

if [ -s $XBPS_MASTERDIR/.xbps_chroot_init ]; then
    export XBPS_ARCH=$(cat $XBPS_MASTERDIR/.xbps_chroot_init)
fi

export XBPS_SHUTILSDIR XBPS_CROSSPFDIR XBPS_TRIGGERSDIR \
	XBPS_SRCPKGDIR XBPS_COMMONDIR XBPS_BUILDDIR \
	XBPS_REPOSITORY XBPS_ALT_REPOSITORY XBPS_SRCDISTDIR XBPS_DIGEST_CMD \
	XBPS_UHELPER_CMD XBPS_INSTALL_CMD XBPS_QUERY_CMD \
	XBPS_RINDEX_CMD XBPS_RECONFIGURE_CMD XBPS_REMOVE_CMD \
	XBPS_CMPVER_CMD XBPS_FETCH_CMD XBPS_VERSION XBPS_APIVER \
	XBPS_BUILDSTYLEDIR XBPS_CFLAGS XBPS_CXXFLAGS XBPS_LDFLAGS \
    XBPS_MAKEJOBS XBPS_BUILD_FORCEMODE XBPS_USE_GIT_REVS XBPS_DEBUG_PKGS \
    XBPS_CCACHE XBPS_DISTCC XBPS_DISTCC_HOSTS XBPS_SKIP_DEPS \
    XBPS_SKIP_REMOTEREPOS XBPS_CROSS_BUILD XBPS_BUILD_OPTS \
    XBPS_CONFIG_FILE XBPS_KEEP_ALL XBPS_HOSTDIR XBPS_MASTERDIR \
    XBPS_SRC_VERSION XBPS_DESTDIR FAKEROOT_CMD CHROOT_CMD XBPS_MACHINE

for i in REPOSITORY DESTDIR BUILDDIR SRCDISTDIR; do
    eval val="\$XBPS_$i"
    if [ ! -d "$val" ]; then
        mkdir -p $val
    fi
    unset val
done

#
# Sanitize PATH.
#
if [ -z "$IN_CHROOT" ]; then
	# In non chroot case always prefer host tools.
	MYPATH="$XBPS_MASTERDIR/usr/bin:$XBPS_MASTERDIR/usr/sbin"
	export PATH="$PATH:$MYPATH"
else
	MYPATH="/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"
	export PATH="$MYPATH"
	if [ -n "$XBPS_CCACHE" ]; then
		CCACHEPATH="/usr/lib/ccache/bin"
		if [ -n "$XBPS_HOSTDIR" -a -d "$XBPS_HOSTDIR/ccache" ]; then
			export CCACHE_DIR="$XBPS_HOSTDIR/ccache"
		else
			if [ ! -d "$XBPS_MASTERDIR/ccache" ]; then
				mkdir -p $XBPS_MASTERDIR/ccache
			fi
			export CCACHE_DIR="$XBPS_MASTERDIR/ccache"
		fi
		export PATH="$CCACHEPATH:$PATH"
	fi
	if [ -n "$XBPS_DISTCC" ]; then
		DISTCCPATH="/usr/lib/distcc/bin"
		if [ -n "$XBPS_HOSTDIR" -a -d "$XBPS_HOSTDIR/distcc" ]; then
			export DISTCC_DIR="$XBPS_HOSTDIR/distcc"
		else
			if [ ! -d "$XBPS_MASTERDIR/distcc" ]; then
				mkdir -p $XBPS_MASTERDIR/distcc
			fi
			export DISTCC_DIR="$XBPS_MASTERDIR/distcc"
		fi
		export DISTCC_HOSTS="$XBPS_DISTCC_HOSTS"
		export PATH="$DISTCCPATH:$PATH"
	fi
fi

if [ -z "$CHROOT_READY" ]; then
	if [ -n "$BASE_CHROOT_REQ" ]; then
		check_installed_pkg base-chroot-$BASE_CHROOT_REQ
		if [ $? -eq 0 ]; then
			# Prepare chroot if required base-chroot pkg is installed.
			msg_normal "Preparing chroot on $XBPS_MASTERDIR...\n"
			chroot_prepare || return $?
			export CHROOT_READY=1
		fi
	fi
fi

check_build_requirements

trap 'exit_func' INT TERM HUP

#
# Main switch.
#
case "$XBPS_TARGET" in
binary-bootstrap)
	install_bbotstrap
	;;
bootstrap)
	# bootstrap from sources
	# check for required host utils
	check_reqhost_utils bootstrap
	[ ! -d $XBPS_SRCPKGDIR/base-chroot ] && \
		msg_error "Cannot find $XBPS_SRCPKGDIR/base-chroot directory!\n"
	XBPS_TARGET_PKG="base-chroot"
	setup_pkg $XBPS_TARGET_PKG && install_pkg $XBPS_TARGET
	;;
bootstrap-update)
	if [ -n "$CHROOT_READY" -a -z "$IN_CHROOT" ]; then
		chroot_handler ${XBPS_TARGET} dummy
	else
		${FAKEROOT_CMD} ${XBPS_INSTALL_CMD} -yu
	fi
	;;
chroot)
	chroot_handler chroot dummy
	;;
clean)
    setup_pkg $XBPS_TARGET_PKG $XBPS_CROSS_BUILD
	if [ -n "$CHROOT_READY" -a -z "$IN_CHROOT" ]; then
		chroot_handler $XBPS_TARGET $XBPS_TARGET_PKG || exit $?
	else
		remove_pkg_wrksrc $wrksrc
		if declare -f do_clean >/dev/null; then
			run_func do_clean
		fi
	fi
	;;
remove-autodeps)
	if [ -n "$CHROOT_READY" -a -z "$IN_CHROOT" ]; then
		chroot_handler remove-autodeps
	else
		pkgver=xbps-src
		remove_pkg_autodeps
	fi
	;;
fetch|extract|build|configure|install-destdir|build-pkg)
	BEGIN_INSTALL=1
    setup_pkg $XBPS_TARGET_PKG $XBPS_CROSS_BUILD
	if [ -n "$CHROOT_READY" -a -z "$IN_CHROOT" ]; then
		chroot_handler $XBPS_TARGET $XBPS_TARGET_PKG
	else
		install_pkg $XBPS_TARGET $XBPS_CROSS_BUILD
	fi
	;;
remove-destdir)
    setup_pkg $XBPS_TARGET_PKG $XBPS_CROSS_BUILD
	remove_pkg $XBPS_CROSS_BUILD
	;;
list)
	$XBPS_QUERY_CMD -l
	;;
show)
    setup_pkg $XBPS_TARGET_PKG $XBPS_CROSS_BUILD
	show_pkg
	;;
show-files)
    setup_pkg $XBPS_TARGET_PKG $XBPS_CROSS_BUILD
	show_pkg_files
	;;
show-deps)
    setup_pkg $XBPS_TARGET_PKG $XBPS_CROSS_BUILD
	show_pkg_deps
	;;
show-build-deps)
    setup_pkg $XBPS_TARGET_PKG $XBPS_CROSS_BUILD
	show_pkg_build_deps
	;;
show-options)
    setup_pkg $XBPS_TARGET_PKG $XBPS_CROSS_BUILD
	show_pkg_options
	;;
show-shlib-provides)
    setup_pkg $XBPS_TARGET_PKG $XBPS_CROSS_BUILD
	show_pkg_shlib_provides
	;;
show-shlib-requires)
    setup_pkg $XBPS_TARGET_PKG $XBPS_CROSS_BUILD
	show_pkg_shlib_requires
	;;
zap)
	masterdir_zap
	;;
*)
	msg_red "xbps-src: invalid target $target.\n"
	usage && exit 1
	;;
esac

# Agur
exit $?
