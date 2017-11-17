# vim: set ts=4 sw=4 et:

run_func() {
    local func="$1" desc="$2" funcname="$3" restoretrap= logpipe= logfile= teepid=

    : ${funcname:=$func}

    logpipe=$(mktemp -u --tmpdir=${XBPS_STATEDIR} ${pkgname}_${XBPS_CROSS_BUILD}_XXXXXXXX.logpipe)
    logfile=${XBPS_STATEDIR}/${pkgname}_${XBPS_CROSS_BUILD}_${funcname}.log

    msg_normal "${pkgver:-xbps-src}: running ${desc:-${func}} ...\n"

    set -E
    restoretrap=$(trap -p ERR)
    trap 'error_func $funcname $LINENO' ERR

    mkfifo "$logpipe"
    tee "$logfile" < "$logpipe" &
    teepid=$!

    $func &>"$logpipe"

    wait $teepid
    rm "$logpipe"

    eval "$restoretrap"
    set +E
}

ch_wrksrc() {
  cd "$wrksrc" || msg_error "$pkgver: cannot access wrksrc directory [$wrksrc]\n"
  if [ -n "$build_wrksrc" ]; then
    cd $build_wrksrc || \
        msg_error "$pkgver: cannot access build_wrksrc directory [$build_wrksrc]\n"
  fi
}

# runs {pre,do,post}_X tripplets
run_step() {
  local step_name="$1" optional_step="$2" skip_post_hook="$3"

  run_pkg_hooks "pre-$step_name"

  ch_wrksrc
  # Run pre_* Phase
  if declare -f "pre_$step_name" >/dev/null; then
    run_func "pre_$step_name"
  fi

  # Run do_* Phase
  if declare -f "do_$step_name" >/dev/null; then
    run_func "do_$step_name"
  elif [ -n "$build_style" ]; then
    if [ -r $XBPS_BUILDSTYLEDIR/${build_style}.sh ]; then
      . $XBPS_BUILDSTYLEDIR/${build_style}.sh
      if declare -f "do_$step_name" >/dev/null; then
        run_func "do_$step_name"
      elif [ ! "$optional_step" ]; then
        msg_error "$pkgver: cannot find do_$step_name() in $XBPS_BUILDSTYLEDIR/${build_style}.sh!\n"
      fi
    else
      msg_error "$pkgver: cannot find build helper $XBPS_BUILDSTYLEDIR/${build_style}.sh!\n"
    fi
  elif [ ! "$optional_step" ]; then
    msg_error "$pkgver: cannot find do_$step_name()!\n"
  fi

  # Run post_* Phase
  if declare -f "post_$step_name" >/dev/null; then
    run_func "post_$step_name"
  fi

  if ! [ "$skip_post_hook" ]; then
    run_pkg_hooks "post-$step_name"
  fi
}

error_func() {
    if [ -n "$1" -a -n "$2" ]; then
        msg_red "$pkgver: failed to run $1() at line $2.\n"
    fi
    exit 1
}

exit_and_cleanup() {
    local rval=$1

    if [ -n "$XBPS_TEMP_MASTERDIR" -a "$XBPS_TEMP_MASTERDIR" != "1" ]; then
        rm -rf "$XBPS_TEMP_MASTERDIR"
    fi
    exit ${rval:=0}
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
    [ -n "$XBPS_INFORMATIVE_RUN" ] || exit 1
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
    if [ -z "$XBPS_QUIET" ]; then
	    # normal messages in bold
	    [ -n "$NOCOLORS" ] || printf "\033[1m"
	    printf "=> $@"
	    [ -n "$NOCOLORS" ] || printf "\033[m"
    fi
}

msg_normal_append() {
    [ -n "$NOCOLORS" ] || printf "\033[1m"
    printf "$@"
    [ -n "$NOCOLORS" ] || printf "\033[m"
}

set_build_options() {
    local f j opt optval _optsset pkgopts _pkgname
    local -A options

    if [ -z "$build_options" ]; then
        return 0
    fi

    for f in ${build_options}; do
        _pkgname=${pkgname//\-/\_}
        _pkgname=${_pkgname//\+/\_}
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
            eval export build_option_${f}=1
        else
            eval unset build_option_${f}
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
    local phase="$1" hookn f

    eval unset -f hook
    for f in ${XBPS_COMMONDIR}/hooks/${phase}/*.sh; do
        [ ! -r $f ] && continue
        hookn=${f##*/}
        hookn=${hookn%.sh}
        . $f
        run_func hook "$phase hook: $hookn" ${phase}_${hookn}
    done
}

unset_package_funcs() {
    local f

    for f in $(typeset -F|grep -E '_package$'); do
        eval unset -f $f
    done
}

get_subpkgs() {
    local args list

    args="$(typeset -F|grep -E '_package$')"
    set -- ${args}
    while [ $# -gt 0 ]; do
        list+=" ${3%_package}"; shift 3
    done
    for f in ${list}; do
        echo "$f"
    done
}

setup_pkg() {
    local pkg="$1" cross="$2" show_problems="$3"
    local basepkg val _vars f dbgflags arch

    [ -z "$pkg" ] && return 1
    basepkg=${pkg%-32bit}

    # Start with a sane environment
    unset -v PKG_BUILD_OPTIONS XBPS_CROSS_CFLAGS XBPS_CROSS_CXXFLAGS XBPS_CROSS_FFLAGS XBPS_CROSS_CPPFLAGS XBPS_CROSS_LDFLAGS
    unset -v subpackages run_depends build_depends host_build_depends

    unset_package_funcs

    ( . $XBPS_CONFIG_FILE 2>/dev/null )

    if [ -n "$cross" ]; then
        source_file $XBPS_CROSSPFDIR/${cross}.sh

        _vars="TARGET_MACHINE CROSS_TRIPLET CROSS_CFLAGS CROSS_CXXFLAGS"
        for f in ${_vars}; do
            eval val="\$XBPS_$f"
            if [ -z "$val" ]; then
                echo "ERROR: XBPS_$f is not defined!"
                exit 1
            fi
        done

        export XBPS_CROSS_BASE=/usr/$XBPS_CROSS_TRIPLET

        XBPS_INSTALL_XCMD="env XBPS_TARGET_ARCH=$XBPS_TARGET_MACHINE $XBPS_INSTALL_CMD -c /host/repocache -r $XBPS_CROSS_BASE"
        XBPS_QUERY_XCMD="env XBPS_TARGET_ARCH=$XBPS_TARGET_MACHINE $XBPS_QUERY_CMD -c /host/repocache -r $XBPS_CROSS_BASE"
        XBPS_RECONFIGURE_XCMD="env XBPS_TARGET_ARCH=$XBPS_TARGET_MACHINE $XBPS_RECONFIGURE_CMD -r $XBPS_CROSS_BASE"
        XBPS_REMOVE_XCMD="env XBPS_TARGET_ARCH=$XBPS_TARGET_MACHINE $XBPS_REMOVE_CMD -r $XBPS_CROSS_BASE"
        XBPS_RINDEX_XCMD="env XBPS_TARGET_ARCH=$XBPS_TARGET_MACHINE $XBPS_RINDEX_CMD"
        XBPS_UHELPER_XCMD="env XBPS_TARGET_ARCH=$XBPS_TARGET_MACHINE xbps-uhelper -r $XBPS_CROSS_BASE"

    else
        export XBPS_TARGET_MACHINE=${XBPS_ARCH:-$XBPS_MACHINE}
        unset XBPS_CROSS_BASE XBPS_CROSS_LDFLAGS XBPS_CROSS_FFLAGS
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

    export XBPS_GCC_VERSION_MAJOR XBPS_GCC_VERSION_MINOR XBPS_GCC_VERSION_BUILD \
        XBPS_GCC_VERSION

    # Source all sourcepkg environment setup snippets.
    # Source all subpkg environment setup snippets.
    for f in ${XBPS_COMMONDIR}/environment/setup-subpkg/*.sh; do
        source_file "$f"
    done
    for f in ${XBPS_COMMONDIR}/environment/setup/*.sh; do
        source_file "$f"
    done

    if [ ! -f ${XBPS_SRCPKGDIR}/${basepkg}/template ]; then
        msg_error "xbps-src: unexistent file: ${XBPS_SRCPKGDIR}/${basepkg}/template\n"
    fi
    if [ -n "$cross" ]; then
        export CROSS_BUILD="$cross"
        source_file ${XBPS_SRCPKGDIR}/${basepkg}/template
    else
        unset CROSS_BUILD
        source_file ${XBPS_SRCPKGDIR}/${basepkg}/template
    fi

    # Check if required vars weren't set.
    _vars="pkgname version short_desc revision homepage license"
    for f in ${_vars}; do
        eval val="\$$f"
        if [ -z "$val" -o -z "$f" ]; then
            msg_error "\"$f\" not set on $pkgname template.\n"
        fi
    done

    # Check if version is valid.
    case "$version" in
        *-*) msg_error "version contains invalid character: -\n";;
        *_*) msg_error "version contains invalid character: _\n";;
    esac
    case "$version" in
        *[0-9]*) : good ;;
        *) msg_error "version must contain at least one digit.\n";;
    esac

    # Check if base-chroot is already installed.
    if [ -z "$bootstrap" -a "z$show_problems" != "zignore-problems" ]; then
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

    if [ -h $XBPS_SRCPKGDIR/$basepkg ]; then
        # Source all subpkg environment setup snippets.
        for f in ${XBPS_COMMONDIR}/environment/setup-subpkg/*.sh; do
            source_file "$f"
        done
        pkgname=$pkg
        if ! declare -f ${basepkg}_package >/dev/null; then
            msg_error "$pkgname: missing ${basepkg}_package() function!\n"
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

    if [ -n "$disable_parallel_build" -o -z "$XBPS_MAKEJOBS" ]; then
        XBPS_MAKEJOBS=1
    fi
    makejobs="-j$XBPS_MAKEJOBS"

    if [ -n "$noarch" ]; then
        arch="noarch"
    else
        arch="$XBPS_TARGET_MACHINE"
    fi
    if [ -n "$XBPS_BINPKG_EXISTS" ]; then
        if [ "$($XBPS_QUERY_XCMD -R -ppkgver $pkgver 2>/dev/null)" = "$pkgver" ]; then
            exit_and_cleanup
        fi
    fi

    if [ -z "$XBPS_DEBUG_PKGS" -o "$repository" = "nonfree" ]; then
        nodebug=yes
    fi
    # -g is required to build -dbg packages.
    if [ -z "$nodebug" ]; then
        dbgflags="-g"
    fi

    if [ -z "$cross" ]; then
        if [ -z "$CHROOT_READY" ]; then
            source_file ${XBPS_COMMONDIR}/build-profiles/bootstrap.sh
        else
            source_file ${XBPS_COMMONDIR}/build-profiles/${XBPS_MACHINE}.sh
        fi
    fi

    export CFLAGS="$XBPS_TARGET_CFLAGS $XBPS_CFLAGS $XBPS_CROSS_CFLAGS $CFLAGS $dbgflags"
    export CXXFLAGS="$XBPS_TARGET_CXXFLAGS $XBPS_CXXFLAGS $XBPS_CROSS_CXXFLAGS $CXXFLAGS $dbgflags"
    export FFLAGS="$XBPS_TARGET_FFLAGS $XBPS_FFLAGS $XBPS_CROSS_FFLAGS $FFLAGS"
    export CPPFLAGS="$XBPS_TARGET_CPPFLAGS $XBPS_CPPFLAGS $XBPS_CROSS_CPPFLAGS $CPPFLAGS"
    export LDFLAGS="$XBPS_TARGET_LDFLAGS $XBPS_LDFLAGS $XBPS_CROSS_LDFLAGS $LDFLAGS"

    export BUILD_CC="cc"
    export BUILD_CFLAGS="$XBPS_CFLAGS"
    export BUILD_CXXFLAGS="$XBPS_CXXFLAGS"
    export BUILD_CPPFLAGS="$XBPS_CPPFLAGS"
    export BUILD_LDFLAGS="$XBPS_LDFLAGS"
    export BUILD_FFLAGS="$XBPS_FFLAGS"

    export CC_FOR_BUILD="cc"
    export CXX_FOR_BUILD="g++"
    export CPP_FOR_BUILD="cpp"
    export FC_FOR_BUILD="gfortran"
    export LD_FOR_BUILD="ld"
    export CFLAGS_FOR_BUILD="$XBPS_CFLAGS"
    export CXXFLAGS_FOR_BUILD="$XBPS_CXXFLAGS"
    export CPPFLAGS_FOR_BUILD="$XBPS_CPPFLAGS"
    export LDFLAGS_FOR_BUILD="$XBPS_LDFLAGS"
    export FFLAGS_FOR_BUILD="$XBPS_FFLAGS"

    if [ -n "$cross" ]; then
        # Regular tools names
        export CC="${XBPS_CROSS_TRIPLET}-gcc"
        export CXX="${XBPS_CROSS_TRIPLET}-c++"
        export CPP="${XBPS_CROSS_TRIPLET}-cpp"
        export FC="${XBPS_CROSS_TRIPLET}-gfortran"
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
        # Target tools
        export CC_target="$CC"
        export CXX_target="$CXX"
        export CPP_target="$CPP"
        export GCC_target="$GCC"
        export FC_target="$FC"
        export LD_target="$LD"
        export AR_target="$AR"
        export AS_target="$AS"
        export RANLIB_target="$RANLIB"
        export STRIP_target="$STRIP"
        export OBJDUMP_target="$OBJDUMP"
        export OBJCOPY_target="$OBJCOPY"
        export NM_target="$NM"
        export READELF_target="$READELF"
        # Target flags
        export CFLAGS_target="$CFLAGS"
        export CXXFLAGS_target="$CXXFLAGS"
        export CPPFLAGS_target="$CPPFLAGS"
        export LDFLAGS_target="$LDFLAGS"
        # Host tools
        export CC_host="cc"
        export CXX_host="g++"
        export CPP_host="cpp"
        export GCC_host="$CC_host"
        export FC_host="gfortran"
        export LD_host="ld"
        export AR_host="ar"
        export AS_host="as"
        export RANLIB_host="ranlib"
        export STRIP_host="strip"
        export OBJDUMP_host="objdump"
        export OBJCOPY_host="objcopy"
        export NM_host="nm"
        export READELF_host="readelf"
        # Host flags
        export CFLAGS_host="$XBPS_CFLAGS"
        export CXXFLAGS_host="$XBPS_CXXFLAGS"
        export CPPFLAGS_host="$XBPS_CPPFLAGS"
        export LDFLAGS_host="$XBPS_LDFLAGS"
    else
        export CC="cc"
        export CXX="g++"
        export CPP="cpp"
        export GCC="$CC"
        export FC="gfortran"
        export LD="ld"
        export AR="ar"
        export AS="as"
        export RANLIB="ranlib"
        export STRIP="strip"
        export OBJDUMP="objdump"
        export OBJCOPY="objcopy"
        export NM="nm"
        export READELF="readelf"
        # Unse cross evironment variables
        unset CC_target CXX_target CPP_target GCC_target FC_target LD_target AR_target AS_target
        unset RANLIB_target STRIP_target OBJDUMP_target OBJCOPY_target NM_target READELF_target
        unset CFLAGS_target CXXFLAGS_target CPPFLAGS_target LDFLAGS_target
        unset CC_host CXX_host CPP_host GCC_host FC_host LD_host AR_host AS_host
        unset RANLIB_host STRIP_host OBJDUMP_host OBJCOPY_host NM_host READELF_host
        unset CFLAGS_host CXXFLAGS_host CPPFLAGS_host LDFLAGS_host
    fi

    set_build_options

    # Setup some specific package vars.
    if [ -z "$wrksrc" ]; then
        wrksrc="$XBPS_BUILDDIR/${sourcepkg}-${version}"
    else
        wrksrc="$XBPS_BUILDDIR/$wrksrc"
    fi

    if [ "$cross" -a "$nocross" -a "z$show_problems" != "zignore-problems" ]; then
        msg_red "$pkgver: cannot be cross compiled, exiting...\n"
        exit 2
    elif [ "$broken" -a "z$show_problems" != "zignore-problems" ]; then
        msg_red "$pkgver: cannot be built, it's currently broken; see the build log:\n"
        msg_red "$pkgver: $broken\n"
        exit 2
    fi

    if [ -n "$restricted" -a -z "$XBPS_ALLOW_RESTRICTED" -a "z$show_problems" != "zignore-problems" ]; then
        msg_red "$pkgver: does not allow redistribution of sources/binaries (restricted license).\n"
        msg_red "If you really need this software, run 'echo XBPS_ALLOW_RESTRICTED=yes >> etc/conf'\n"
        exit 2
    fi

    export XBPS_STATEDIR="${XBPS_BUILDDIR}/.xbps-${sourcepkg}"
    export XBPS_WRAPPERDIR="${XBPS_STATEDIR}/wrappers"

    if [ -n "$bootstrap" -a -z "$CHROOT_READY" -o -n "$IN_CHROOT" ]; then
        mkdir -p $XBPS_WRAPPERDIR
    fi

    source_file $XBPS_COMMONDIR/environment/build-style/${build_style}.sh
}
