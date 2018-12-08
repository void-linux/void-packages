# vim: set ts=4 sw=4 et:

update_check() {
    local i p url sfname lpname bbname githubname rx found_version consider
    local update_override=$XBPS_SRCPKGDIR/$XBPS_TARGET_PKG/update
    local original_pkgname=$pkgname

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
        printf '%s\n' "$homepage"
        for i in $distfiles; do
            printf '%s\n' "${i%/*}/"
        done
    else
        printf '%s\n' "$site"
    fi |
    while IFS= read -r url; do
        rx=
        if [ -z "$site" ]; then
            case "$url" in
            *sourceforge.net/sourceforge*)
                sfname="$(printf %s "$url" | cut -d/ -f5)"
                url="http://sourceforge.net/projects/$sfname/rss?limit=200";;
            *code.google.com*|*googlecode*)
                url="http://code.google.com/p/$pkgname/downloads/list";;
            *launchpad.net*)
                lpname="$(printf %s "$url" | cut -d/ -f4)"
                url="https://launchpad.net/$lpname/+download";;
            *cpan.*)
                pkgname=${pkgname#perl-};;
            *pythonhosted.org*)
                pkgname=${pkgname#python-}
                url="https://pypi.org/simple/$pkgname";;
            *github.com*)
                githubname="$(printf %s "$url" | cut -d/ -f4,5)"
                url="https://github.com/$githubname/tags"
                rx='/archive/(v?|\Q'"$pkgname"'\E-)?\K[\d\.]+(?=\.tar\.gz")';;
            *gitlab.com*|*gitlab.gnome.org*|*gitlab.freedesktop.org*)
                gitlaburl="$(printf %s "$url" | cut -d/ -f1-5)"
                url="$gitlaburl/tags"
                rx='/archive/[^/]+/\Q'"$pkgname"'\E-v?\K[\d\.]+(?=\.tar\.gz")';;
            *bitbucket.org*)
                bbname="$(printf %s "$url" | cut -d/ -f4,5)"
                url="https://bitbucket.org/$bbname/downloads"
                rx='/(get|downloads)/(v?|\Q'"$pkgname"'\E-)?\K[\d\.]+(?=\.tar)';;
            *ftp.gnome.org*)
                : ${pattern="\Q$pkgname\E-\K[0-9]+\.[0-9]*[02468]\.[0-9.]*[0-9](?=)"}
                url="http://ftp.gnome.org/pub/GNOME/sources/$pkgname/cache.json";;
            *kernel.org/pub/linux/kernel/*)
                rx=linux-'\K'${version%.*}'[\d.]+(?=\.tar\.xz)';;
            *cran.r-project.org/src/contrib*)
                rx='\b\Q'"${pkgname#R-cran-}"'\E_\K\d+(\.\d+)*(-\d+)?(?=\.tar)';;
            *download.kde.org/stable/applications*|*download.kde.org/stable/frameworks*|*download.kde.org/stable/plasma*)
                url="${url%%${version%.*}*}"
                rx='href="\K[\d\.]+(?=/")';;
            *rubygems.org*)
                url="https://rubygems.org/gems/${pkgname#ruby-}"
                rx='href="/gems/'${pkgname#ruby-}'/versions/\K[\d\.]*(?=")' ;;
            esac
        fi

        rx=${pattern:-$rx}
        rx=${rx:-'(?<!-)\b\Q'"$pkgname"'\E[-_]?((src|source)[-_])?\K([^-/_\s]*?\d[^-/_\s]*?)(?=(?:[-_.](?:src|source|orig))?\.(?:[jt]ar|shar|t[bglx]z|tbz2|zip))\b'}

        if [ -n "$XBPS_UPDATE_CHECK_VERBOSE" ]; then
            echo "fetching $url" 1>&2
        fi
        curl -H 'Accept: text/html,application/xhtml+xml,application/xml,text/plain,application/rss+xml' -A "xbps-src-update-check/$XBPS_SRC_VERSION" --max-time 10 -Lsk "$url" |
            grep -Po -i "$rx"
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
