# vim: set ts=4 sw=4 et:

update_check() {
    local i p url pkgurlname rx found_version consider
    local update_override=$XBPS_SRCPKGDIR/$XBPS_TARGET_PKG/update
    local original_pkgname=$pkgname
    local urlpfx urlsfx
    local -A fetchedurls

    if [ -r $update_override ]; then
        . $update_override
        if [ "$XBPS_UPDATE_CHECK_VERBOSE" ]; then
            echo "using $XBPS_TARGET_PKG/update overrides" 1>&2
        fi
    fi

    if ! type curl >/dev/null 2>&1; then
        echo "ERROR: cannot find \`curl' executable!"
        return 1
    fi

    export LC_ALL=C

    if [ -z "$site" ]; then
        case "$distfiles" in
            # only consider versions those exist in ftp.gnome.org
            *ftp.gnome.org*) ;;
            *)
                printf '%s\n' "$homepage" ;;
        esac
        for i in $distfiles; do
            printf '%s\n' "${i%/*}/"
        done
    else
        printf '%s\n' "$site"
    fi |
    # filter loop: if version are "folder" name based,
    # substitute original url by every folder based ones (expand)
    while IFS= read -r url; do
        # default case: don't rewrite url
        printf '%s\n' "$url"
        if [ "$single_directory" ]; then
            continue
        fi
        rx=
        urlpfx="${url}"
        urlsfx=
        dirpfx=
        case "$url" in
            *.voidlinux.*|\
              *sourceforge.net/sourceforge*|\
              *code.google.com*|*googlecode*|\
              *launchpad.net*|\
              *cpan.*|\
              *pythonhosted.org*|\
              *github.com*|\
              *//gitlab.*|\
              *bitbucket.org*|\
              *ftp.gnome.org*|\
              *kernel.org/pub/linux/kernel/*|\
              *cran.r-project.org/src/contrib*|\
              *rubygems.org*|\
              *crates.io*|\
              *codeberg.org*|\
              *hg.sr.ht*|\
              *git.sr.ht*)
                continue
                ;;
            *)
                vdpfx=${vdprefix:-"|v|\\Q$pkgname\\E"}
                vdsfx=${vdsuffix:-"|\\.x"}
                match=$(grep -Po "^[^/]+//[^/]+(/.+)?/($vdpfx)(?=[-_.0-9]*[0-9](?<!\\Q$pkgname\\E)($vdsfx)/)" <<< "$url")
                if [ "$?" = 0 ]; then
                    urlpfx="${match%/*}/"
                    dirpfx="${match##*/}"
                    urlsfx="${url#$urlpfx}"
                    urlsfx="${urlsfx#*/}"
                    rx="href=[\"']?(\\Q$urlpfx\\E)?\\.?/?\\K\\Q$dirpfx\\E[-_.0-9]*[0-9]($vdsfx)[\"'/]"
                fi
                ;;
        esac
        if [ "$rx" ]; then
            # substitute url if needed
            if [ -n "$XBPS_UPDATE_CHECK_VERBOSE" ]; then
                echo "(folder) fetching $urlpfx and scanning with $rx" 1>&2
            fi
            skipdirs=
            curl -A "xbps-src-update-check/$XBPS_SRC_VERSION" --max-time 10 -Lsk "$urlpfx" |
                grep -Po -i "$rx" |
                # sort -V places 1.1/ before 1/, but 1A/ before 1.1A/
                sed -e 's:$:A:' -e 's:/A$:A/:' | sort -Vru | sed -e 's:A/$:/A:' -e 's:A$::' |
                while IFS= read -r newver; do
                    newurl="${urlpfx}${newver}${urlsfx}"
                    if [ "$newurl" = "$url" ]; then
                        skipdirs=yes
                    fi
                    if [ -z "$skipdirs" ]; then
                        printf '%s\n' "$newurl"
                    fi
                done
        fi
    done |
    while IFS= read -r url; do
        rx=
        if [ -z "$site" ]; then
            case "$url" in
            *sourceforge.net/sourceforge*)
                pkgurlname="$(printf %s "$url" | cut -d/ -f5)"
                url="https://sourceforge.net/projects/$pkgurlname/rss?limit=200";;
            *code.google.com*|*googlecode*)
                url="http://code.google.com/p/$pkgname/downloads/list";;
            *launchpad.net*)
                pkgurlname="$(printf %s "$url" | cut -d/ -f4)"
                url="https://launchpad.net/$pkgurlname/+download";;
            *cpan.*)
                pkgname=${pkgname#perl-};;
            *pythonhosted.org*)
                pkgname=${pkgname#python-}
                pkgname=${pkgname#python3-}
                url="https://pypi.org/simple/$pkgname";;
            *github.com*)
                pkgurlname="$(printf %s "$url" | cut -d/ -f4,5)"
                url="https://github.com/$pkgurlname/tags"
                rx='/archive/refs/tags/(v?|\Q'"$pkgname"'\E-)?\K[\d.]+(?=\.tar\.gz")';;
            *//gitlab.*)
                pkgurlname="$(printf %s "$url" | cut -d/ -f1-5)"
                url="$pkgurlname/tags"
                rx='/archive/[^/]+/\Q'"$pkgname"'\E-v?\K[\d.]+(?=\.tar\.gz")';;
            *bitbucket.org*)
                pkgurlname="$(printf %s "$url" | cut -d/ -f4,5)"
                url="https://bitbucket.org/$pkgurlname/downloads"
                rx='/(get|downloads)/(v?|\Q'"$pkgname"'\E-)?\K[\d.]+(?=\.tar)';;
            *ftp.gnome.org*|*download.gnome.org*)
                : ${pattern="\Q$pkgname\E-\K(0|[13]\.[0-9]*[02468]|[4-9][0-9]+)\.[0-9.]*[0-9](?=)"}
                url="https://download.gnome.org/sources/$pkgname/cache.json";;
            *kernel.org/pub/linux/kernel/*)
                rx=linux-'\K'${version%.*}'[\d.]+(?=\.tar\.xz)';;
            *cran.r-project.org/src/contrib*)
                rx='\b\Q'"${pkgname#R-cran-}"'\E_\K\d+(\.\d+)*(-\d+)?(?=\.tar)';;
            *rubygems.org*)
                url="https://rubygems.org/gems/${pkgname#ruby-}"
                rx='href="/gems/'${pkgname#ruby-}'/versions/\K[\d.]*(?=")' ;;
            *crates.io*)
                url="https://crates.io/api/v1/crates/${pkgname#rust-}"
                rx='/crates/'${pkgname#rust-}'/\K[0-9.]*(?=/download)' ;;
            *codeberg.org*)
                pkgurlname="$(printf %s "$url" | cut -d/ -f4,5)"
                url="https://codeberg.org/$pkgurlname/releases"
                rx='/archive/\K[\d.]+(?=\.tar\.gz)' ;;
            *hg.sr.ht*)
                pkgurlname="$(printf %s "$url" | cut -d/ -f4,5)"
                url="https://hg.sr.ht/$pkgurlname/tags"
                rx='/archive/(v?|\Q'"$pkgname"'\E-)?\K[\d.]+(?=\.tar\.gz")';;
            *git.sr.ht*)
                pkgurlname="$(printf %s "$url" | cut -d/ -f4,5)"
                url="https://git.sr.ht/$pkgurlname/refs"
                rx='/archive/(v?|\Q'"$pkgname"'\E-)?\K[\d.]+(?=\.tar\.gz")';;
            esac
        fi

        rx=${pattern:-$rx}
        rx=${rx:-'(?<!-)\b\Q'"$pkgname"'\E[-_]?((src|source)[-_])?v?\K([^-/_\s]*?\d[^-/_\s]*?)(?=(?:[-_.](?:src|source|orig))?\.(?:[jt]ar|shar|t[bglx]z|tbz2|zip))\b'}

        if [ "${fetchedurls[$url]}" ]; then
            if [ -n "$XBPS_UPDATE_CHECK_VERBOSE" ]; then
                echo "already fetched $url" 1>&2
            fi
            continue
        fi

        if [ -n "$XBPS_UPDATE_CHECK_VERBOSE" ]; then
            echo "fetching $url and scanning with $rx" 1>&2
        fi
        curl -H 'Accept: text/html,application/xhtml+xml,application/xml,text/plain,application/rss+xml' -A "xbps-src-update-check/$XBPS_SRC_VERSION" --max-time 10 -Lsk "$url" |
            grep -Po -i "$rx"
        fetchedurls[$url]=yes
    done |
    tr _ . |
    sort -Vu |
    {
        grep . || echo "NO VERSION found for $original_pkgname" 1>&2
    } |
    while IFS= read -r found_version; do
        if [ -n "$XBPS_UPDATE_CHECK_VERBOSE" ]; then
            echo "found version $found_version"
        fi
        consider=true
        p="$ignore "
        while [ -n "$p" ]; do
            i=${p%% *}
            p=${p#* }
            case "$found_version" in
            $i)
                consider=false
                if [ -n "$XBPS_UPDATE_CHECK_VERBOSE" ]; then
                    echo "ignored $found_version due to $i"
                fi
            esac
        done
        if $consider; then
            xbps-uhelper cmpver "$original_pkgname-${version}_1" \
                "$original_pkgname-$(printf %s "$found_version" | tr - .)_1"
            if [ $? = 255 ]; then
                echo "${original_pkgname}-${version} -> ${original_pkgname}-${found_version}"
            fi
        fi
    done
}
