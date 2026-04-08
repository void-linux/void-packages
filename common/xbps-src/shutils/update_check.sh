# vim: set ts=4 sw=4 et ft=bash :

update_check() {
    local i p url pkgurlname rx found_version consider
    local update_override=$XBPS_SRCPKGDIR/$XBPS_TARGET_PKG/update
    local original_pkgname=$pkgname
    local pkgname=$sourcepkg
    local urlpfx urlsfx
    local -A fetchedurls

    local curlargs=(
        -A "xbps-src-update-check/$XBPS_SRC_VERSION"
        --max-time 10 --compressed -Lsk
    )

    pkgname=${pkgname#kf6-}

    # XBPS_UPDATE_CHECK_VERBOSE is the old way to show verbose messages
    [ "$XBPS_UPDATE_CHECK_VERBOSE" ] && XBPS_VERBOSE="$XBPS_UPDATE_CHECK_VERBOSE"

    if [ -r $update_override ]; then
        . $update_override
        msg_verbose "using $XBPS_TARGET_PKG/update overrides\n"
        if [ -n "$disabled" ]; then
            msg_verbose "update-check DISABLED for $original_pkgname: $disabled\n"
            return 0
        fi
    elif [ -z "$distfiles" ]; then
        msg_verbose "NO DISTFILES found for $original_pkgname\n"
        return 0
    fi

    if ! type curl >/dev/null 2>&1; then
        echo "ERROR: cannot find \`curl' executable!"
        return 1
    fi

    export LC_ALL=C

    if [ -z "$site" ]; then
        case "$distfiles" in
            # special case those sites provide better source elsewhere
            *ftp.gnome.org*|*download.gnome.org*) ;;
            *archive.xfce.org*) ;;
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
              *pythonhosted.org*|*pypi.org/project/*|\
              *github.com*|\
              *//gitlab.*|\
              *bitbucket.org*|\
              *ftp.gnome.org*|*download.gnome.org*|\
              *archive.xfce.org*|\
              *kernel.org/pub/linux/kernel/*|\
              *cran.r-project.org/src/contrib*|\
              *rubygems.org*|\
              *crates.io*|\
              *codeberg.org*|\
              *hg.sr.ht*|\
              *software.sil.org*|\
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
                    case "$urlpfx" in
                        *download.qt.io*) urlpfx="${urlpfx%/*/}/" ;;
                    esac
                    rx="href=[\"']?(\\Q$urlpfx\\E)?\\.?/?\\K\\Q$dirpfx\\E[-_.0-9]*[0-9]($vdsfx)[\"'/]"
                fi
                ;;
        esac
        if [ "$rx" ]; then
            # substitute url if needed
            msg_verbose "(folder) fetching $urlpfx and scanning with $rx\n"
            skipdirs=
            curl "${curlargs[@]}" "$urlpfx" |
            grep -Po -i "$rx" |
            # sort -V places 1.1/ before 1/, but 1A/ before 1.1A/
            sed -e 's:$:A:' -e 's:/A$:A/:' | sort -Vru |
            sed -e 's:A/$:/A:' -e 's:A$::' |
            case "$urlpfx" in
            *download.qt.io*)
                while IFS= read -r newver; do
                    printf '%s\n' "${urlpfx}${newver}"
                done
                ;;
            *)
                while IFS= read -r newver; do
                    newurl="${urlpfx}${newver}${urlsfx}"
                    if [ "$newurl" = "$url" ]; then
                        skipdirs=yes
                    fi
                    if [ -z "$skipdirs" ]; then
                        printf '%s\n' "$newurl"
                    fi
                done
                ;;
            esac
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
                url="https://code.google.com/p/$pkgname/downloads/list";;
            *launchpad.net*)
                pkgurlname="$(printf %s "$url" | cut -d/ -f4)"
                url="https://launchpad.net/$pkgurlname/+download";;
            *cpan.*)
                pkgname=${pkgname#perl-};;
            *pythonhosted.org*|*pypi.org/project/*)
                pkgname=${pkgname#python-}
                pkgname=${pkgname#python3-}
                rx="(?<=${pkgname//-/[-_]}-)[0-9.]+(post[0-9]*)?(?=(([.]tar|-cp|-py)))"
                url="https://pypi.org/simple/$pkgname";;
            *github.com*)
                pkgurlname="$(printf %s "$url" | cut -d/ -f4,5)"
                url="https://github.com/$pkgurlname/tags"
                rx='/archive/refs/tags/(\Q'"$pkgname"'\E|[-_v])*\K[\d.]+(?=\.tar\.gz")';;
            *//gitlab.*|*code.videolan.org*)
                case "$url" in
                    */-/*) pkgurlname="$(printf %s "$url" | sed -e 's%/-/.*%%g; s%/$%%')";;
                    *) pkgurlname="$(printf %s "$url" | cut -d / -f 1-5)";;
                esac
                url="$pkgurlname/-/tags"
                rx='/archive/[^/]+/\Q'"$pkgname"'\E-v?\K[\d.]+(?=\.tar\.gz)';;
            *bitbucket.org*)
                pkgurlname="$(printf %s "$url" | cut -d/ -f4,5)"
                url="https://bitbucket.org/$pkgurlname/downloads"
                rx='/(get|downloads)/(v?|\Q'"$pkgname"'\E-)?\K[\d.]+(?=\.tar)';;
            *ftp.gnome.org*|*download.gnome.org*)
                rx='(?<=LATEST-IS-)([0-24-9]|3\.[0-9]*[02468]|[4-9][0-9]+)\.[0-9.]*[0-9](?=\")'
                url="https://download.gnome.org/sources/$pkgname/cache.json";;
            *archive.xfce.org*)
                rx='\Q'"$pkgname"'\E-\K((([4-9]|([1-9][0-9]+))\.[0-9]*[02468]\.[0-9.]*[0-9])|([0-3]\.[0-9.]*))(?=.tar)'
                url="https://archive.xfce.org/feeds/project/$pkgname" ;;
            *kernel.org/pub/linux/kernel/*)
                rx=linux-'\K'${version%.*}'\.[\d.]+(?=\.tar\.xz)';;
            *cran.r-project.org/src/contrib*)
                url="https://cran.r-project.org/package=${pkgname#R-cran-}"
                # rx='\b\Q'"${pkgname#R-cran-}"'\E_\K\d+(\.\d+)*(-\d+)?(?=\.tar)';;
                rx="(?<=${pkgname#R-cran-}_)[0-9.]+(-[0-9]*)?(?=\\.tar)" ;;
            *rubygems.org*)
                url="https://rubygems.org/gems/${pkgname#ruby-}"
                rx='href="/gems/'${pkgname#ruby-}'/versions/\K[\d.]*(?=")' ;;
            *crates.io*)
                url="https://crates.io/api/v1/crates/${pkgname#rust-}"
                rx='/crates/'${pkgname#rust-}'/\K[0-9.]*(?=/download)' ;;
            *codeberg.org*)
                pkgurlname="$(printf %s "$url" | cut -d/ -f4,5)"
                url="https://codeberg.org/$pkgurlname/tags"
                rx='/archive/(v-?|\Q'"$pkgname"'\E-)?\K[\d.]+(?=\.tar\.gz)' ;;
            *hg.sr.ht*)
                pkgurlname="$(printf %s "$url" | cut -d/ -f4,5)"
                url="https://hg.sr.ht/$pkgurlname/tags"
                rx='/archive/(v?|\Q'"$pkgname"'\E-)?\K[\d.]+(?=\.tar\.gz")';;
            *git.sr.ht*)
                pkgurlname="$(printf %s "$url" | cut -d/ -f4,5)"
                url="https://git.sr.ht/$pkgurlname/refs/rss.xml"
                rx='<guid>\Q'"${url%/*}"'\E/(v-?|\Q'"$pkgname"'\E-)?\K[\d.]+(?=</guid>)' ;;
            *pkgs.fedoraproject.org*)
                url="https://pkgs.fedoraproject.org/repo/pkgs/$pkgname" ;;
            *software.sil.org/downloads/*)
                pkgurlname=$(printf '%s\n' "$url" | cut -d/ -f6)
                url="https://software.sil.org/$pkgurlname/download/"
                pkgname="${pkgname#font-}"
                pkgname="${pkgname#sil-}"
                _pkgname="${pkgname//-/}"
                rx="($_pkgname|${_pkgname}SIL)[_-]\K[0-9.]+(?=\.tar|\.zip)" ;;
            *software.sil.org/*)
                pkgname="${pkgname#font-}"
                pkgname="${pkgname#sil-}"
                _pkgname="${pkgname//-/}"
                rx="($_pkgname|${_pkgname}SIL)[_-]\K[0-9.]+(?=\.tar|\.zip)" ;;
            *download.qt.io*)
                rx="((?<=href=\")[0-9.]+(?=/\">[0-9.]+/)|(?<=$pkgname-)[0-9.]+(?=\.tar))";;
            esac
        fi

        rx=${pattern:-$rx}
        rx=${rx:-'(?<!-)\b\Q'"$pkgname"'\E[-_]?((src|source)[-_])?v?\K([^-/_\s]*?\d[^-/_\s]*?)(?=(?:[-_.](?:src|source|orig))?\.(?:[jt]ar|shar|t[bglx]z|tbz2|zip))\b'}

        if [ "${fetchedurls[$url]}" ]; then
            msg_verbose "already fetched $url\n"
            continue
        fi

        msg_verbose "fetching $url and scanning with $rx\n"
        curl "${curlargs[@]}" -H 'Accept: text/html,application/xhtml+xml,application/xml,text/plain,application/rss+xml,application/json' "$url" |
            grep -Po -i "$rx"
        fetchedurls[$url]=yes
    done |
    tr _ . |
    sort -Vu |
    {
        grep . || echo "NO VERSION found for $original_pkgname" 1>&2
    } |
    while IFS= read -r found_version; do
        msg_verbose "found version $found_version\n"
        consider=true
        p="$ignore "
        while [ -n "$p" ]; do
            i=${p%% *}
            p=${p#* }
            case "$found_version" in
            $i)
                consider=false
                msg_verbose "ignored $found_version due to $i\n"
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
