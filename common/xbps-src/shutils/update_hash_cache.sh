# vim: set ts=4 sw=4 et:

update_hash_cache() {
    local cache="$XBPS_SRCDISTDIR/by_sha256"
    local distfile curfile
    mkdir -p "$cache"
    find "$XBPS_SRCDISTDIR" -type f | grep -v by_sha256 | while read -r distfile; do
        cksum=$($XBPS_DIGEST_CMD "$distfile")
        curfile="${distfile##*/}"
        ln -vf "$distfile" "${cache}/${cksum}_${curfile}"
    done
}
