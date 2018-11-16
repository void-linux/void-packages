# vim: set ts=4 sw=4 et:
#
# This hook executes the following tasks:
#	- Generates rdeps file with run-time dependencies for xbps-create(1)
#	- Generates shlib-requires file for xbps-create(1)

add_rundep() {
    local dep="$1" i= rpkgdep= _depname= _rdeps= found=

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
            : > ${PKGDESTDIR}/rdeps
            for f in ${run_depends}; do
                _curdep="$(echo "$f" | sed -e 's,\(.*\)?.*,\1,')"
                if [ -z "$($XBPS_UHELPER_CMD getpkgdepname ${_curdep} 2>/dev/null)" -a \
                     -z "$($XBPS_UHELPER_CMD getpkgname ${_curdep} 2>/dev/null)" ]; then
                    _curdep="${_curdep}>=0"
                fi
                printf -- "${_curdep} " >> ${PKGDESTDIR}/rdeps
            done
        fi
}

hook() {
    local depsftmp f lf j mapshlibs sorequires _curdep

    # Disable trap on ERR, xbps-uhelper cmd might return error... but not something
    # to be worried about because if there are broken shlibs this hook returns
    # error via msg_error().
    trap - ERR

    mapshlibs=$XBPS_COMMONDIR/shlibs

    if [ -n "$noarch" -o -n "$noverifyrdeps" ]; then
        store_pkgdestdir_rundeps
        return 0
    fi

    depsftmp=$(mktemp -t xbps_src_depstmp.XXXXXXXXXX) || return 1
    find ${PKGDESTDIR} -type f -perm -u+w > $depsftmp 2>/dev/null

    exec 3<&0 # save stdin
    exec < $depsftmp
    while read f; do
        lf=${f#${DESTDIR}}
	if [ "${skiprdeps/${lf}/}" != "${skiprdeps}" ]; then
		msg_normal "Skipping dependency scan for ${lf}\n"
		continue
	fi
        case "$(file -bi "$f")" in
            application/x-*executable*|application/x-sharedlib*)
                for nlib in $($OBJDUMP -p "$f"|grep NEEDED|awk '{print $2}'); do
                    if [ -z "$verify_deps" ]; then
                        verify_deps="$nlib"
                        continue
                    fi
                    for j in ${verify_deps}; do
                        [ "$j" != "$nlib" ] && continue
                        found_dup=1
                        break
                    done
                    if [ -z "$found_dup" ]; then
                        verify_deps="$verify_deps $nlib"
                    fi
                    unset found_dup
                done
                ;;
        esac
    done
    exec 0<&3 # restore stdin
    rm -f $depsftmp

    #
    # Add required run time packages by using required shlibs resolved
    # above, the mapping is done thru the mapping_shlib_binpkg.txt file.
    #
    for f in ${verify_deps}; do
        unset _f j rdep _rdep rdepcnt soname _pkgname _rdepver found
        _f=$(echo "$f"|sed -E 's|\+|\\+|g')
        rdep="$(grep -E "^${_f}[[:blank:]]+.*$" $mapshlibs|awk '{print $2}')"
        rdepcnt="$(grep -E "^${_f}[[:blank:]]+.*$" $mapshlibs|awk '{print $2}'|wc -l)"
        if [ -z "$rdep" ]; then
            # Ignore libs by current pkg
            soname=$(find ${PKGDESTDIR} -name "$f")
            if [ -z "$soname" ]; then
                msg_red_nochroot "   SONAME: $f <-> UNKNOWN PKG PLEASE FIX!\n"
                broken=1
            else
                echo "   SONAME: $f <-> $pkgname (ignored)"
            fi
            continue
        elif [ "$rdepcnt" -gt 1 ]; then
            unset j found
            # Check if shlib is provided by multiple pkgs.
            for j in ${rdep}; do
                _pkgname=$($XBPS_UHELPER_CMD getpkgname "$j")
                # if there's a SONAME matching pkgname, use it.
                for x in ${pkgname} ${subpackages}; do
                    if [ "${_pkgname}" = "${x}" ]; then
                        found=1
                        break
                    fi
                done
                if [ -n "$found" ]; then
                    _rdep=$j
                    break
                fi
            done
            if [ -z "${_rdep}" ]; then
                # otherwise pick up the first one.
                for j in ${rdep}; do
                    [ -z "${_rdep}" ] && _rdep=$j
                done
            fi
        else
            _rdep=$rdep
        fi
        _pkgname=$($XBPS_UHELPER_CMD getpkgname "${_rdep}" 2>/dev/null)
        _rdepver=$($XBPS_UHELPER_CMD getpkgversion "${_rdep}" 2>/dev/null)
        if [ -z "${_pkgname}" -o -z "${_rdepver}" ]; then
            msg_red_nochroot "   SONAME: $f <-> UNKNOWN PKG PLEASE FIX!\n"
            broken=1
            continue
        fi
        # Check if pkg is a subpkg of sourcepkg; if true, ignore version
        # in common/shlibs.
        _sdep="${_pkgname}>=${_rdepver}"
        for _subpkg in ${subpackages}; do
            if [ "${_subpkg}" = "${_pkgname}" ]; then
                _sdep="${_pkgname}-${version}_${revision}"
                break
            fi
        done

        if [ "${_pkgname}" != "${pkgname}" ]; then
            echo "   SONAME: $f <-> ${_sdep}"
            sorequires+="${f} "
        else
            # Ignore libs by current pkg
            echo "   SONAME: $f <-> ${_rdep} (ignored)"
            continue
        fi
        add_rundep "${_sdep}"
    done
    #
    # If pkg uses any unknown SONAME error out.
    #
    if [ -n "$broken" -a -z "$allow_unknown_shlibs" ]; then
        msg_error "$pkgver: cannot guess required shlibs, aborting!\n"
    fi

    store_pkgdestdir_rundeps

    for f in ${shlib_requires}; do
        sorequires+="${f} "
    done
    if [ -n "${sorequires}" ]; then
        echo "${sorequires}" > ${PKGDESTDIR}/shlib-requires
    fi
}
