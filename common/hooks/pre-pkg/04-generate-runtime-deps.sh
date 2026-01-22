# vim: set ts=4 sw=4 et:
#
# This hook executes the following tasks:
#	- Generates rdeps file with run-time dependencies for xbps-create(1)
#	- Generates shlib-requires file for xbps-create(1)

add_rundep() {
    local dep="$1" i= rpkgdep= _depname= found=

    _depname="$($XBPS_UHELPER_CMD getpkgdepname ${dep} 2>/dev/null)"
    if [ -z "${_depname}" ]; then
        _depname="$($XBPS_UHELPER_CMD getpkgname ${dep} 2>/dev/null)"
    fi

    for i in ${run_depends}; do
        rpkgdep="$($XBPS_UHELPER_CMD getpkgdepname $i 2>/dev/null)"
        if [ -z "$rpkgdep" ]; then
            rpkgdep="$($XBPS_UHELPER_CMD getpkgname $i 2>/dev/null)"
        fi
        if [ "${rpkgdep}" != "${_depname}" ]; then
            continue
        fi
        $XBPS_UHELPER_CMD cmpver "$i" "$dep"
        rval=$?
        if [ $rval -eq 255 ]; then
            run_depends="${run_depends/${i}/${dep}}"
        fi
        found=1
    done
    if [ -z "$found" ]; then
        run_depends+=" ${dep}"
    fi
}

store_pkgdestdir_rundeps() {
        if [ -n "$run_depends" ]; then
            for f in ${run_depends}; do
                _curdep="$(echo "$f" | sed -e 's,\(.*\)?.*,\1,')"
                if [ -z "$($XBPS_UHELPER_CMD getpkgdepname ${_curdep} 2>/dev/null)" -a \
                     -z "$($XBPS_UHELPER_CMD getpkgname ${_curdep} 2>/dev/null)" ]; then
                    _curdep="${_curdep}>=0"
                fi
                printf "%s " "${_curdep}"
            done > "${XBPS_STATEDIR}/${pkgname}-rdeps"
        fi
}

parse_shlib_needed() {
    while read -r f; do
        lf=${f#${PKGDESTDIR}}
	    if [ "${skiprdeps/${lf}/}" != "${skiprdeps}" ]; then
		    msg_normal "Skipping dependency scan for ${lf}\n" >&3
		    continue
	    fi
        read -n4 elfmagic < "$f"
        if [ "$elfmagic" = $'\177ELF' ]; then
            $OBJDUMP -p "$f" |
            awk '
                /NEEDED/{print $2;}
                /Qt_5_PRIVATE_API/{next;}
                /Qt_[0-9]*_PRIVATE_API/{print $NF;}
            '
        fi
    done
}

hook() {
    local depsftmp f lf j mapshlibs sorequires _curdep elfmagic broken_shlibs verify_deps
    local _shlib_dir="${XBPS_STATEDIR}/shlib-provides"
    local _shlibtmp

    local Qt_6_PRIVATE_API=6.10.0

    # Disable trap on ERR, xbps-uhelper cmd might return error... but not something
    # to be worried about because if there are broken shlibs this hook returns
    # error via msg_error().
    trap - ERR

    mapshlibs=$XBPS_COMMONDIR/shlibs

    if [ -n "$noverifyrdeps" ]; then
        store_pkgdestdir_rundeps
        return 0
    fi

    depsftmp=$(mktemp) || exit 1
    find ${PKGDESTDIR} -type f -perm -u+w > $depsftmp 2>/dev/null

    for f in ${shlib_requires}; do
        verify_deps+=" ${f}"
    done

    _shlibtmp=$(mktemp) || exit 1
    parse_shlib_needed 3>&1 >"$_shlibtmp" <"$depsftmp"
    rm -f "$depsftmp"
    verify_deps=$(sort <"$_shlibtmp" | uniq)
    rm -f "$_shlibtmp"

    #
    # Add required run time packages by using required shlibs resolved
    # above, the mapping is done thru the common/shlibs file.
    #
    for f in ${verify_deps}; do
        unset _rdep _pkgname _rdepver

        case "$f" in
        Qt_*_PRIVATE_API)
            eval "f=lib${f}.\${$f}"
            ;;
        esac

        local _findargs="-name"
        # if SONAME is a path, find should use -wholename
        if [[ "$f" = */* ]]; then
            _findargs="-wholename"
        fi
        case " $shlib_provides " in
        *" $f "*)
            echo "   SONAME: $f <-> $pkgname (ignored)"
            continue
            ;;
        esac
        if [ "$(find "${PKGDESTDIR}" $_findargs "$f")" ]; then
            # Ignore libs by current pkg
            echo "   SONAME: $f <-> $pkgname (ignored)"
            continue
        # If this library is provided by a subpkg of sourcepkg, use that subpkg
        elif _pkgname="$(cd "$_shlib_dir" && grep -F -l -x "$f" *.soname 2>/dev/null)"; then
            # If that library has SONAME, add it to shlibs-requires, too.
            _pkgname=${_pkgname%.soname}
            _sdep="${_pkgname}>=${version}_${revision}"
            sorequires+="${f} "
        elif _pkgname="$(cd "$_shlib_dir" && grep -F -l -x "$f" *.nosoname 2>/dev/null)"; then
            _pkgname=${_pkgname%.nosoname}
            _sdep="${_pkgname}>=${version}_${revision}"
        else
            _rdep="$(awk -v sl="$f" -v arch="$XBPS_TARGET_MACHINE" '$1 == sl && ($3 == "" || $3 == "ignore" || $3 == arch) { print $2; exit; }' "$mapshlibs")"

            if [ -z "$_rdep" ]; then
                msg_red_nochroot "   SONAME: $f <-> UNKNOWN PKG PLEASE FIX!\n"
                broken_shlibs=1
                continue
            fi
            _pkgname=$($XBPS_UHELPER_CMD getpkgname "${_rdep}" 2>/dev/null)
            _rdepver=$($XBPS_UHELPER_CMD getpkgversion "${_rdep}" 2>/dev/null)
            if [ -z "${_pkgname}" -o -z "${_rdepver}" ]; then
                msg_red_nochroot "   SONAME: $f <-> UNKNOWN PKG PLEASE FIX!\n"
                broken_shlibs=1
                continue
            fi
            _sdep="${_pkgname}>=${_rdepver}"

            # By this point, SONAME can't be found in current pkg
            sorequires+="${f} "
        fi
        echo "   SONAME: $f <-> ${_sdep}"
        add_rundep "${_sdep}"
    done
    #
    # If pkg uses any unknown SONAME error out.
    #
    if [ -n "$broken_shlibs" -a -z "$allow_unknown_shlibs" ]; then
        msg_error "$pkgver: cannot guess required shlibs, aborting!\n"
    fi

    store_pkgdestdir_rundeps

    if [ -n "${sorequires}" ]; then
        echo "${sorequires}" | xargs -n1 | sort | xargs > ${XBPS_STATEDIR}/${pkgname}-shlib-requires
    fi
}
