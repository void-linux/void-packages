# vim: set ts=4 sw=4 et:
#
# This hook executes the following tasks:
#	- Warns if the main package is in subpackages=
#	- Warns if a subpackage is unreachable (never appears in subpackages=)

hook() {
    local subpkgs matches

    # Run this only against the main package
    if [ "$pkgname" != "$sourcepkg" ]; then
        return 0
    fi

    if [ -z "$subpackages" ]; then
        return 0
    fi

    subpkgs=$(get_subpkgs)

    subpackages="${subpackages// /$'\n'}"

    # Sort the strings so they can be compare for equality
    subpkgs="$(printf "%s\\n" "$subpkgs" | sort)"
    subpackages="$(printf "%s\\n" "$subpackages" | sort)"

    if [ "$subpackages" = "$subpkgs" ]; then
        return 0
    fi

    # XXX: Make the sed call work when subpackages has multiple lines
    # this can be done with grep with perl regexp (-P) but chroot-grep
    # is compiled without it
    matches="$(sed -n 's/subpackages.*"\(.*\)"[^"]*$/\1/p' $XBPS_SRCPKGDIR/$pkgname/template \
        | tr " " "\n" | sort)"

    for s in $subpkgs; do
        grep -q "^$s$" <<< "$matches" ||
            msg_warn "${s}_package() defined but will never be built.\n"
    done

    grep -q "^$pkgname$" <<< "$matches" &&
        msg_warn "$pkgname is sourcepkg but is in subpackages=.\n" || :
}
