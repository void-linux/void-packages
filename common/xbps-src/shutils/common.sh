# vim: set ts=4 sw=4 et:

run_func() {
    local func="$1" desc="$2" restoretrap= logpipe= logfile= teepid=

    if [ -d "${wrksrc}" ]; then
        logpipe=$(mktemp -u --tmpdir=${wrksrc} .xbps_${XBPS_CROSS_BUILD}_XXXXXXXX.logpipe)
        logfile=${wrksrc}/.xbps_${XBPS_CROSS_BUILD}_${func}.log
    else
        logpipe=$(mktemp -t -u .xbps_${XBPS_CROSS_BUILD}_${func}_${pkgname}_logpipe.XXXXXXX)
        logfile=$(mktemp -t .xbps_${XBPS_CROSS_BUILD}_${func}_${pkgname}.log.XXXXXXXX)
    fi

    msg_normal "${pkgver:-xbps-src}: running ${desc:-${func}} ...\n"

    set -E
    restoretrap=$(trap -p ERR)
    trap 'error_func $func $LINENO' ERR

    mkfifo "$logpipe"
    tee "$logfile" < "$logpipe" &
    teepid=$!

    $func &>"$logpipe"

    wait $teepid
    rm "$logpipe"

    eval "$restoretrap"
    set +E
}

error_func() {
    if [ -n "$1" -a -n "$2" ]; then
        msg_red "$pkgver: failed to run $1() at line $2.\n"
    fi
    exit 2
}

msg_red() {
    # error messages in bold/red
    [ -n "$NOCOLORS" ] || printf >&2 "\033[1m\033[31m"
    printf >&2 "=> ERROR: $@"
    [ -n "$NOCOLORS" ] || printf >&2 "\033[m"
}

msg_red_nochroot() {
    [ -n "$NOCOLORS" ] || printf >&2 "\033[1m\033[31m"
    printf >&2 "$@"
    [ -n "$NOCOLORS" ] || printf >&2 "\033[m"
}

msg_error() {
    msg_red "$@"
    kill -INT $$; exit 1
}

msg_error_nochroot() {
    [ -n "$NOCOLORS" ] || printf >&2 "\033[1m\033[31m"
    printf >&2 "=> ERROR: $@"
    [ -n "$NOCOLORS" ] || printf >&2 "\033[m"
    exit 1
}

msg_warn() {
    # warn messages in bold/yellow
    [ -n "$NOCOLORS" ] || printf >&2 "\033[1m\033[33m"
    printf >&2 "=> WARNING: $@"
    [ -n "$NOCOLORS" ] || printf >&2  "\033[m"
}

msg_warn_nochroot() {
    [ -n "$NOCOLORS" ] || printf >&2 "\033[1m\033[33m"
    printf >&2 "=> WARNING: $@"
    [ -n "$NOCOLORS" ] || printf >&2 "\033[m"
}

msg_normal() {
    # normal messages in bold
    [ -n "$NOCOLORS" ] || printf "\033[1m"
    printf "=> $@"
    [ -n "$NOCOLORS" ] || printf "\033[m"
}

msg_normal_append() {
    [ -n "$NOCOLORS" ] || printf "\033[1m"
    printf "$@"
    [ -n "$NOCOLORS" ] || printf "\033[m"
}

set_build_options() {
    local f j opt optval _optsset pkgopts
    local -A options _pkgname

    if [ -z "$build_options" ]; then
        return 0
    fi

    for f in ${build_options}; do
        _pkgname=${pkgname//\-/\_}
        eval pkgopts="\$XBPS_PKG_OPTIONS_${_pkgname}"
        if [ -z "$pkgopts" -o "$pkgopts" = "" ]; then
            pkgopts=${XBPS_PKG_OPTIONS}
        fi
        OIFS="$IFS"; IFS=','
        for j in ${pkgopts}; do
            opt=${j#\~}
            opt_disabled=${j:0:1}
            if [ "$opt" = "$f" ]; then
                if [ "$opt_disabled" != "~" ]; then
                    eval options[$opt]=1
                else
                    eval options[$opt]=0
                fi
            fi
        done
        IFS="$OIFS"
    done

    for f in ${build_options_default}; do
        optval=${options[$f]}
        if [[ -z "$optval" ]] || [[ $optval -eq 1 ]]; then
            options[$f]=1
        fi
    done

    # Prepare final options.
    for f in ${!options[@]}; do
        optval=${options[$f]}
        if [[ $optval -eq 1 ]]; then
            eval build_option_${f}=1
        fi
    done

    # Re-read pkg template to get conditional vars.
    if [ -z "$XBPS_BUILD_OPTIONS_PARSED" ]; then
        source_file $XBPS_SRCPKGDIR/$pkgname/template
        XBPS_BUILD_OPTIONS_PARSED=1
        unset PKG_BUILD_OPTIONS
        set_build_options
        unset XBPS_BUILD_OPTIONS_PARSED
        return 0
    fi

    for f in ${build_options}; do
        eval optval=${options[$f]}
        if [[ $optval -eq 1 ]]; then
            _optsset+=" ${f}"
        else
            _optsset+=" ~${f}"
        fi
    done

    for f in ${_optsset}; do
        if [ -z "$PKG_BUILD_OPTIONS" ]; then
            PKG_BUILD_OPTIONS="$f"
        else
            PKG_BUILD_OPTIONS+=" $f"
        fi
    done

    # Sort pkg build options alphabetically.
    export PKG_BUILD_OPTIONS="$(echo "$PKG_BUILD_OPTIONS"|tr ' ' '\n'|sort|tr '\n' ' ')"
}

source_file() {
    local f="$1"

    if [ ! -f "$f" -o ! -r "$f" ]; then
        return 0
    fi
    if ! source "$f"; then
        msg_error "xbps-src: failed to read $f!\n"
    fi
}

run_pkg_hooks() {
    local phase="$1" hookn

    eval unset -f hook
    for f in ${XBPS_COMMONDIR}/hooks/${phase}/*.sh; do
        [ ! -r $f ] && continue
        hookn=$(basename $f)
        hookn=${hookn%.sh}
        . $f
        run_func hook "$phase hook: $hookn"
    done
}

get_subpkgs() {
    local args list

    args="$(typeset -F|grep -E '_package$')"
    set -- ${args}
    while [ $# -gt 0 ]; do
        list+=" ${3%_package}"; shift 3
    done
    # first all non development pkgs ...
    for f in ${list}; do
        [[ $f =~ '-devel' ]] || echo "$f"
    done
    # ... and then only development pkgs
    for f in ${list}; do
        [[ $f =~ '-devel' ]] && echo "$f"
    done
}

setup_pkg() {
    local pkg="$1" cross="$2"
    local val _vars f

    [ -z "$pkg" ] && return 1

    # Start with a sane environment
    unset -v PKG_BUILD_OPTIONS XBPS_CROSS_CFLAGS XBPS_CROSS_CXXFLAGS XBPS_CROSS_CPPFLAGS XBPS_CROSS_LDFLAGS
    unset -v run_depends build_depends host_build_depends

    for f in ${subpackages}; do
        eval unset -f ${f}_package
    done

    if [ -n "$cross" ]; then
        source_file $XBPS_CROSSPFDIR/${cross}.sh

        REQ_VARS="TARGET_ARCH CROSS_TRIPLET CROSS_CFLAGS CROSS_CXXFLAGS"
        for f in ${REQ_VARS}; do
            eval val="\$XBPS_$f"
            if [ -z "$val" ]; then
                echo "ERROR: XBPS_$f is not defined!"
                exit 1
            fi
        done

        export XBPS_TARGET_MACHINE=$XBPS_TARGET_ARCH
        export XBPS_CROSS_BASE=/usr/$XBPS_CROSS_TRIPLET

        XBPS_INSTALL_XCMD="env XBPS_TARGET_ARCH=$XBPS_TARGET_ARCH $XBPS_INSTALL_CMD -c /host/repocache -r $XBPS_CROSS_BASE"
        XBPS_QUERY_XCMD="env XBPS_TARGET_ARCH=$XBPS_TARGET_ARCH $XBPS_QUERY_CMD -c /host/repocache -r $XBPS_CROSS_BASE"
        XBPS_RECONFIGURE_XCMD="env XBPS_TARGET_ARCH=$XBPS_TARGET_ARCH $XBPS_RECONFIGURE_CMD -r $XBPS_CROSS_BASE"
        XBPS_REMOVE_XCMD="env XBPS_TARGET_ARCH=$XBPS_TARGET_ARCH $XBPS_REMOVE_CMD -r $XBPS_CROSS_BASE"
        XBPS_RINDEX_XCMD="env XBPS_TARGET_ARCH=$XBPS_TARGET_ARCH $XBPS_RINDEX_CMD"
        XBPS_UHELPER_XCMD="env XBPS_TARGET_ARCH=$XBPS_TARGET_ARCH xbps-uhelper -r $XBPS_CROSS_BASE"

    else
        export XBPS_TARGET_MACHINE=${XBPS_ARCH:-$XBPS_MACHINE}
        unset XBPS_CROSS_BASE XBPS_CROSS_LDFLAGS
        unset XBPS_CROSS_CFLAGS XBPS_CROSS_CXXFLAGS XBPS_CROSS_CPPFLAGS

        XBPS_INSTALL_XCMD="$XBPS_INSTALL_CMD"
        XBPS_QUERY_XCMD="$XBPS_QUERY_CMD"
        XBPS_RECONFIGURE_XCMD="$XBPS_RECONFIGURE_CMD"
        XBPS_REMOVE_XCMD="$XBPS_REMOVE_CMD"
        XBPS_RINDEX_XCMD="$XBPS_RINDEX_CMD"
        XBPS_UHELPER_XCMD="$XBPS_UHELPER_CMD"

    fi

    export XBPS_INSTALL_XCMD XBPS_QUERY_XCMD XBPS_RECONFIGURE_XCMD \
        XBPS_REMOVE_XCMD XBPS_RINDEX_XCMD XBPS_UHELPER_XCMD

    # Source all sourcepkg environment setup snippets.
    for f in ${XBPS_COMMONDIR}/environment/setup/*.sh; do
        source_file "$f"
    done
    # Source all subpkg environment setup snippets.
    for f in ${XBPS_COMMONDIR}/environment/setup-subpkg/*.sh; do
        source_file "$f"
    done

    if [ ! -f ${XBPS_SRCPKGDIR}/${pkg}/template ]; then
        msg_error "xbps-src: unexistent file: ${XBPS_SRCPKGDIR}/${pkg}/template\n"
    fi
    if [ -n "$cross" ]; then
        export CROSS_BUILD="$cross"
        source_file ${XBPS_SRCPKGDIR}/${pkg}/template
    else
        unset CROSS_BUILD
        source_file ${XBPS_SRCPKGDIR}/${pkg}/template
    fi

    # Check if required vars weren't set.
    _vars="pkgname version short_desc revision homepage license"
    for f in ${_vars}; do
        eval val="\$$f"
        if [ -z "$val" -o -z "$f" ]; then
            msg_error "\"$f\" not set on $pkgname template.\n"
        fi
    done

    . ${XBPS_SHUTILSDIR}/build_dependencies.sh

    # Check if base-chroot is already installed.
    if [ -z "$bootstrap" ]; then
        check_installed_pkg base-chroot-0.1_1
        if [ $? -ne 0 ]; then
            msg_red "${pkg} is not a bootstrap package and cannot be built without it.\n"
            msg_error "Please install bootstrap packages and try again.\n"
        fi
    fi

    sourcepkg="${pkgname}"
    if [ -z "$subpackages" ]; then
        subpackages="$(get_subpkgs)"
    fi

    if [ -h $XBPS_SRCPKGDIR/$pkg ]; then
        # Source all subpkg environment setup snippets.
        for f in ${XBPS_COMMONDIR}/environment/setup-subpkg/*.sh; do
            source_file "$f"
        done
        pkgname=$pkg
        if ! declare -f ${pkg}_package >/dev/null; then
            msg_error "$pkgname: missing ${pkg}_package() function!\n"
        fi
    fi

    pkgver="${pkg}-${version}_${revision}"

    # If build_style() unset, a do_install() function must be defined.
    if [ -z "$build_style" ]; then
        # Check that at least do_install() is defined.
        if ! declare -f do_install >/dev/null; then
            msg_error "$pkgver: missing do_install() function!\n"
        fi
    fi

    FILESDIR=$XBPS_SRCPKGDIR/$sourcepkg/files
    PATCHESDIR=$XBPS_SRCPKGDIR/$sourcepkg/patches
    DESTDIR=$XBPS_DESTDIR/$XBPS_CROSS_TRIPLET/${sourcepkg}-${version}
    PKGDESTDIR=$XBPS_DESTDIR/$XBPS_CROSS_TRIPLET/${pkg}-${version}

    if [ -n "$XBPS_MAKEJOBS" -a -z "$disable_parallel_build" ]; then
        makejobs="-j$XBPS_MAKEJOBS"
    fi

    # For nonfree/bootstrap pkgs there's no point in building -dbg pkgs, disable them.
    if [ -z "$XBPS_DEBUG_PKGS" -o -n "$nonfree" -o -n "$bootstrap" ]; then
        disable_debug=yes
    fi
    # If a package sets force_debug_pkgs, always build -dbg pkgs.
    if [ -n "$force_debug_pkgs" ]; then
        unset disable_debug
    fi
    # -g is required to build -dbg packages.
    if [ -z "$disable_debug" ]; then
        dbgflags="-g"
    fi

    export CFLAGS="$XBPS_CFLAGS $XBPS_CROSS_CFLAGS $CFLAGS $dbgflags"
    export CXXFLAGS="$XBPS_CXXFLAGS $XBPS_CROSS_CXXFLAGS $CXXFLAGS $dbgflags"
    export CPPFLAGS="$XBPS_CPPFLAGS $XBPS_CROSS_CPPFLAGS $CPPFLAGS"
    export LDFLAGS="$LDFLAGS $XBPS_LDFLAGS $XBPS_CROSS_LDFLAGS"

    export BUILD_CC="cc"
    export BUILD_CFLAGS="$XBPS_CFLAGS"

    if [ -n "$cross" ]; then
        export CC="${XBPS_CROSS_TRIPLET}-gcc"
        export CXX="${XBPS_CROSS_TRIPLET}-c++"
        export CPP="${XBPS_CROSS_TRIPLET}-cpp"
        export GCC="$CC"
        export LD="${XBPS_CROSS_TRIPLET}-ld"
        export AR="${XBPS_CROSS_TRIPLET}-ar"
        export AS="${XBPS_CROSS_TRIPLET}-as"
        export RANLIB="${XBPS_CROSS_TRIPLET}-ranlib"
        export STRIP="${XBPS_CROSS_TRIPLET}-strip"
        export OBJDUMP="${XBPS_CROSS_TRIPLET}-objdump"
        export OBJCOPY="${XBPS_CROSS_TRIPLET}-objcopy"
        export NM="${XBPS_CROSS_TRIPLET}-nm"
        export READELF="${XBPS_CROSS_TRIPLET}-readelf"
    else
        export CC="cc"
        export CXX="g++"
        export CPP="cpp"
        export GCC="$CC"
        export LD="ld"
        export AR="ar"
        export AS="as"
        export RANLIB="ranlib"
        export STRIP="strip"
        export OBJDUMP="objdump"
        export OBJCOPY="objcopy"
        export NM="nm"
        export READELF="readelf"
    fi

    set_build_options

    # Setup some specific package vars.
    if [ -z "$wrksrc" ]; then
        wrksrc="$XBPS_BUILDDIR/${sourcepkg}-${version}"
    else
        wrksrc="$XBPS_BUILDDIR/$wrksrc"
    fi

    if [ "$cross" -a "$nocross" ]; then
        msg_red "$pkgver: cannot be cross compiled, exiting...\n"
        exit 0
    elif [ "$broken" ]; then
        msg_red "$pkgver: cannot be built, it's currently broken; exiting...\n"
        exit 0
    fi
}

setup_pkg_depends() {
    local pkg="$1" j _pkgdepname _pkgdep _rpkgname _depname

    if [ -n "$pkg" ]; then
        # subpkg
        if declare -f ${pkg}_package >/dev/null; then
            ${pkg}_package
        fi
    fi

    for j in ${depends}; do
        _rpkgname="${j%\?*}"
        _depname="${j#*\?}"
        _pkgdepname="$($XBPS_UHELPER_CMD getpkgdepname ${_depname} 2>/dev/null)"
        if [ -z "${_pkgdepname}" ]; then
            _pkgdepname="$($XBPS_UHELPER_CMD getpkgname ${_depname} 2>/dev/null)"
        fi

        if [ -z "${_pkgdepname}" ]; then
            _pkgdep="${_depname}>=0"
        else
            _pkgdep="${_depname}"
        fi
        if [ "${_rpkgname}" = "virtual" ]; then
            run_depends+=" virtual?${_pkgdep}"
        else
            run_depends+=" ${_pkgdep}"
        fi
    done
    for j in ${hostmakedepends}; do
        _depname="${j%\?*}"
        _pkgdepname="$($XBPS_UHELPER_CMD getpkgdepname ${_depname} 2>/dev/null)"
        if [ -z "${_pkgdepname}" ]; then
            _pkgdepname="$($XBPS_UHELPER_CMD getpkgname ${_depname} 2>/dev/null)"
        fi
        if [ -z "${_pkgdepname}" ]; then
            _pkgdep="${_depname}>=0"
        else
            _pkgdep="${_depname}"
        fi
        host_build_depends+=" ${_pkgdep}"
    done
    for j in ${makedepends}; do
        _depname="${j%\?*}"
        _pkgdepname="$($XBPS_UHELPER_CMD getpkgdepname ${_depname} 2>/dev/null)"
        if [ -z "${_pkgdepname}" ]; then
            _pkgdepname="$($XBPS_UHELPER_CMD getpkgname ${_depname} 2>/dev/null)"
        fi
        if [ -z "${_pkgdepname}" ]; then
            _pkgdep="${_depname}>=0"
        else
            _pkgdep="${_depname}"
        fi
        build_depends+=" ${_pkgdep}"
    done
}

_remove_pkg_cross_deps() {
    local rval= tmplogf=
    [ -z "$XBPS_CROSS_BUILD" ] && return 0

    cd $XBPS_MASTERDIR || return 1
    msg_normal "${pkgver:-xbps-src}: removing autocrossdeps, please wait...\n"
    tmplogf=$(mktemp)

    if [ -z "$XBPS_REMOVE_XCMD" ]; then
        source_file $XBPS_CROSSPFDIR/${XBPS_CROSS_BUILD}.sh
        XBPS_REMOVE_XCMD="env XBPS_TARGET_ARCH=$XBPS_TARGET_ARCH xbps-remove -r /usr/$XBPS_CROSS_TRIPLET"
    fi

    $FAKEROOT_CMD $XBPS_REMOVE_XCMD -Ryo > $tmplogf 2>&1
    if [ $? -ne 0 ]; then
        msg_red "${pkgver:-xbps-src}: failed to remove autocrossdeps:\n"
        cat $tmplogf && rm -f $tmplogf
        msg_error "${pkgver:-xbps-src}: cannot continue!\n"
    fi
    rm -f $tmplogf
}

remove_pkg_autodeps() {
    local rval= tmplogf=

    [ -z "$CHROOT_READY" ] && return 0

    cd $XBPS_MASTERDIR || return 1
    msg_normal "${pkgver:-xbps-src}: removing autodeps, please wait...\n"
    tmplogf=$(mktemp)

    _remove_pkg_cross_deps

    $FAKEROOT_CMD xbps-reconfigure -a >> $tmplogf 2>&1
    $FAKEROOT_CMD xbps-remove -Ryo >> $tmplogf 2>&1

    if [ $? -ne 0 ]; then
        msg_red "${pkgver:-xbps-src}: failed to remove autodeps:\n"
        cat $tmplogf && rm -f $tmplogf
        msg_error "${pkgver:-xbps-src}: cannot continue!\n"
    fi
    rm -f $tmplogf
}

install_cross_pkg() {
    local cross="$1" rval errlog

    [ -z "$cross" -o "$cross" = "" ] && return 0

    source_file ${XBPS_CROSSPFDIR}/${cross}.sh

    if [ -z "$CHROOT_READY" ]; then
        echo "ERROR: chroot mode not activated (install a bootstrap)."
        exit 1
    elif [ -z "$IN_CHROOT" ]; then
        return 0
    fi

    # Install required pkgs for cross building.
    if [ "$XBPS_TARGET" != "remove-autodeps" ]; then
        errlog=$(mktemp)
        check_installed_pkg cross-${XBPS_CROSS_TRIPLET}-0.1_1
        if [ $? -ne 0 ]; then
            msg_normal "Installing cross pkg: cross-${XBPS_CROSS_TRIPLET} ...\n"
            $XBPS_INSTALL_CMD -Syd cross-${XBPS_CROSS_TRIPLET} &>$errlog
            rval=$?
            if [ $rval -ne 0 -a $rval -ne 17 ]; then
                msg_red "failed to install cross-${XBPS_CROSS_TRIPLET} (error $rval)\n"
                cat $errlog
                rm -f $errlog
                msg_error "cannot continue due to errors above\n"
            fi
        fi
        if [ ! -d ${XBPS_CROSS_BASE}/var/db/xbps/keys ]; then
            mkdir -p ${XBPS_CROSS_BASE}/var/db/xbps/keys
            cp ${XBPS_MASTERDIR}/var/db/xbps/keys/*.plist \
                ${XBPS_CROSS_BASE}/var/db/xbps/keys
        fi
        $XBPS_INSTALL_CMD -r ${XBPS_CROSS_BASE} -SAyd cross-vpkg-dummy &>$errlog
        rval=$?
        if [ $rval -ne 0 -a $rval -ne 17 ]; then
            msg_red "failed to install cross-vpkg-dummy (error $rval)\n"
            cat $errlog
            rm -f $errlog
            msg_error "cannot continue due to errors above\n"
        fi
    fi
}

remove_cross_pkg() {
    local cross="$1" rval

    [ -z "$cross" -o "$cross" = "" ] && return 0

    source_file ${XBPS_CROSSPFDIR}/${cross}.sh

    if [ -z "$CHROOT_READY" ]; then
        echo "ERROR: chroot mode not activated (install a bootstrap)."
        exit 1
    elif [ -z "$IN_CHROOT" ]; then
        return 0
    fi

    msg_normal "Removing cross pkg: cross-${XBPS_CROSS_TRIPLET} ...\n"
    $XBPS_REMOVE_CMD -Ry cross-${XBPS_CROSS_TRIPLET} &>/dev/null
    rval=$?
    if [ $rval -ne 0 ]; then
        msg_error "failed to remove cross-${XBPS_CROSS_TRIPLET} (error $rval)\n"
    fi
}
