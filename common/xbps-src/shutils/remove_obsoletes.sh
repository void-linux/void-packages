remove_obsoletes () {
    for repo in $XBPS_HOSTDIR/binpkgs $XBPS_HOSTDIR/binpkgs/debug $XBPS_HOSTDIR/binpkgs/nonfree $XBPS_HOSTDIR/binpkgs/multilib/  $XBPS_HOSTDIR/binpkgs/multilib/nonfree ; do
        msg_normal "Cleaning $repo\n"
        XBPS_ARCH=${XBPS_CROSS_BUILD:-$XBPS_MACHINE} $XBPS_RINDEX_CMD -r $repo
    done
}
