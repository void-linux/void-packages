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

    # Sort the strings so they can be compare for equality
    subpkgs="$(printf '%s\n' $subpkgs | sort)"
    subpackages="$(printf '%s\n' $subpackages | sort)"

    if [ "$subpackages" = "$subpkgs" ]; then
        return 0
    fi

    # sed supports comment but let's put them here
    # 1: print everything between pairs of <""> in subpackages[+]?="..."
    # 2: multiline subpackages="...\n..."
    # 2.1: For any line in the middle, i.e. no <"> exists, print it
    # 2.2: For the first line, print everything after <">
    # 2.3: For last line, print everything before <">
    matches="$(sed -n -e 's/subpackages.*"\(.*\)"[^"]*$/\1/p' \
            -e '/subpackages[^"]*"[^"]*$/,/"/{
                /"/!p
                /subpackages/s/.*"//p
                s/".*//p
            }' $XBPS_SRCPKGDIR/$pkgname/template |
        tr '\v\t\r\n' '    ')"

    for s in $subpkgs; do
        case " $matches " in
            *" $s "*) ;;
            *) msg_warn "${s}_package() defined but will never be built.\n" ;;
        esac
    done

    case " $matches " in
        *" $pkgname "*)
            msg_warn "$pkgname is sourcepkg but is in subpackages=.\n" ;;
    esac
}
