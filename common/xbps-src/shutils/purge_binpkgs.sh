# vim: set ts=4 sw=4 et:

purge_binpkgs() {
    purge_directory() {
        export XBPS_TARGET_ARCH="${XBPS_CROSS_BUILD:-${XBPS_MACHINE}}"
        for filepath in "${1}"/*."$XBPS_TARGET_ARCH".xbps; do
            ( # read_pkg exits is some cases. Use subshell to continue loop.
                filename=${filepath##*/}
                pkgname=${filename%-*.${XBPS_TARGET_ARCH}.xbps}
                if [ "${pkgname%-dbg}" != "${pkgname}" ] && ! [ -e "${XBPS_SRCPKGDIR}/${pkgname}/template" ] && [ -e "${XBPS_SRCPKGDIR}/${pkgname%-dbg}/template" ]; then
                    pkgname="${pkgname%-dbg}"
                fi
                export XBPS_TARGET_PKG="${pkgname}"
                read_pkg ignore-problems
                template_version="${version}_${revision}"
                binpkg_version=${filename%.${XBPS_TARGET_ARCH}.xbps}
                binpkg_version=${binpkg_version##*-}
                if [ "${template_version}" = "_" ]; then
                    :
                elif [ "${binpkg_version}" != "${template_version}" ]; then
                    rm -v "$filepath"
                fi
            )
        done
        xbps-rindex -c "${1}"
        for i in debug multilib nonfree; do
            if [ -d "${1}/${i}" ]; then
                purge_directory "${1}/${i}"
            fi
        done
    }

    purge_directory "$XBPS_REPOSITORY"
}

