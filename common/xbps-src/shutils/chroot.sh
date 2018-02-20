# vim: set ts=4 sw=4 et:

# FIXME: $XBPS_FFLAGS is not set when chroot_init() is run
# It is set in common/build-profiles/bootstrap.sh but lost somewhere?
chroot_init() {
    XBPSSRC_CF=$XBPS_MASTERDIR/etc/xbps/xbps-src.conf

    mkdir -p $XBPS_MASTERDIR/etc/xbps

    cat > $XBPSSRC_CF <<_EOF
# Generated configuration file by xbps-src, DO NOT EDIT!
_EOF
    if [ -e "$XBPS_CONFIG_FILE" ]; then
        grep -E '^XBPS_.*' $XBPS_CONFIG_FILE >> $XBPSSRC_CF
    fi
    cat >> $XBPSSRC_CF <<_EOF
XBPS_MASTERDIR=/
XBPS_CFLAGS="$XBPS_CFLAGS"
XBPS_CXXFLAGS="$XBPS_CXXFLAGS"
XBPS_FFLAGS="-fPIC -pipe"
XBPS_CPPFLAGS="$XBPS_CPPFLAGS"
XBPS_LDFLAGS="$XBPS_LDFLAGS"
XBPS_HOSTDIR=/host
_EOF

    echo "# End of configuration file." >> $XBPSSRC_CF

    # Create custom script to start the chroot bash shell.
    cat > $XBPS_MASTERDIR/bin/xbps-shell <<_EOF
#!/bin/sh

XBPS_SRC_VERSION="$XBPS_SRC_VERSION"

. /etc/xbps/xbps-src.conf

PATH=/void-packages:/usr/bin:/usr/sbin

exec env -i -- SHELL=/bin/sh PATH="\$PATH" DISTCC_HOSTS="\$XBPS_DISTCC_HOSTS" DISTCC_DIR="/host/distcc" @@XARCH@@ \
    @@CHECK@@ CCACHE_DIR="/host/ccache" IN_CHROOT=1 LC_COLLATE=C LANG=en_US.UTF-8 TERM=linux HOME="/tmp" \
    PS1="[\u@$XBPS_MASTERDIR \W]$ " /bin/bash +h
_EOF
    if [ -n "$XBPS_ARCH" ]; then
        sed -e "s,@@XARCH@@,XBPS_ARCH=${XBPS_ARCH},g" -i $XBPS_MASTERDIR/bin/xbps-shell
    else
        sed -e 's,@@XARCH@@,,g' -i $XBPS_MASTERDIR/bin/xbps-shell
    fi
    if [ -z "$XBPS_CHECK_PKGS" ]; then
        sed -e 's,@@CHECK@@,,g' -i $XBPS_MASTERDIR/bin/xbps-shell
    else
        sed -e "s,@@CHECK@@,XBPS_CHECK_PKGS=$XBPS_CHECK_PKGS,g" -i $XBPS_MASTERDIR/bin/xbps-shell
    fi
    chmod 755 $XBPS_MASTERDIR/bin/xbps-shell

    cp -f /etc/resolv.conf $XBPS_MASTERDIR/etc

    # Update xbps alternative repository if set.
    mkdir -p $XBPS_MASTERDIR/etc/xbps.d
    if [ -n "$XBPS_ALT_REPOSITORY" ]; then
        ( \
            echo "repository=/host/binpkgs/${XBPS_ALT_REPOSITORY}"; \
            echo "repository=/host/binpkgs/${XBPS_ALT_REPOSITORY}/nonfree"; \
            echo "repository=/host/binpkgs/${XBPS_ALT_REPOSITORY}/debug"; \
            ) > $XBPS_MASTERDIR/etc/xbps.d/00-repository-alternative.conf
        if [ "$XBPS_MACHINE" = "x86_64" ]; then
            ( \
                echo "repository=/host/binpkgs/${XBPS_ALT_REPOSITORY}/multilib"; \
                echo "repository=/host/binpkgs/${XBPS_ALT_REPOSITORY}/multilib/nonfree"; \
            ) >> $XBPS_MASTERDIR/etc/xbps.d/00-repository-alternative.conf
        fi
    else
        rm -f $XBPS_MASTERDIR/etc/xbps.d/00-repository-alternative.conf
    fi
}

chroot_prepare() {
    local f=

    if [ -f $XBPS_MASTERDIR/.xbps_chroot_init ]; then
        return 0
    elif [ ! -f $XBPS_MASTERDIR/bin/bash ]; then
        msg_error "Bootstrap not installed in $XBPS_MASTERDIR, can't continue.\n"
    fi

    # Create some required files.
    if [ -f /etc/localtime ]; then
        cp -f /etc/localtime $XBPS_MASTERDIR/etc
    elif [ -f /usr/share/zoneinfo/UTC ]; then
        cp -f /usr/share/zoneinfo/UTC $XBPS_MASTERDIR/etc/localtime
    fi

    for f in dev sys proc host boot; do
        [ ! -d $XBPS_MASTERDIR/$f ] && mkdir -p $XBPS_MASTERDIR/$f
    done

    # Copy /etc/passwd and /etc/group from base-files.
    cp -f $XBPS_SRCPKGDIR/base-files/files/passwd $XBPS_MASTERDIR/etc
    echo "$(whoami):x:$(id -u):$(id -g):$(whoami) user:/tmp:/bin/xbps-shell" \
        >> $XBPS_MASTERDIR/etc/passwd
    cp -f $XBPS_SRCPKGDIR/base-files/files/group $XBPS_MASTERDIR/etc
    echo "$(whoami):x:$(id -g):" >> $XBPS_MASTERDIR/etc/group

    # Copy /etc/hosts from base-files.
    cp -f $XBPS_SRCPKGDIR/base-files/files/hosts $XBPS_MASTERDIR/etc

    mkdir -p $XBPS_MASTERDIR/etc/xbps.d
    echo "syslog=false" >> $XBPS_MASTERDIR/etc/xbps.d/xbps.conf
    echo "cachedir=/host/repocache" >> $XBPS_MASTERDIR/etc/xbps.d/xbps.conf
    ln -sf /dev/null $XBPS_MASTERDIR/etc/xbps.d/00-repository-main.conf

    # Prepare default locale: en_US.UTF-8.
    if [ -s ${XBPS_MASTERDIR}/etc/default/libc-locales ]; then
        echo 'en_US.UTF-8 UTF-8' >> ${XBPS_MASTERDIR}/etc/default/libc-locales
    fi

    touch -f $XBPS_MASTERDIR/.xbps_chroot_init
    [ -n "$1" ] && echo $1 >> $XBPS_MASTERDIR/.xbps_chroot_init

    return 0
}

chroot_sync_repos() {
    local f=

    # Copy xbps configuration files to the masterdir.
    install -Dm644 ${XBPS_DISTDIR}/etc/xbps.conf \
        ${XBPS_MASTERDIR}/etc/xbps.d/00-xbps-src.conf
    install -Dm644 ${XBPS_DISTDIR}/etc/repos-local.conf \
        ${XBPS_MASTERDIR}/etc/xbps.d/10-repository-local.conf
    install -Dm644 ${XBPS_DISTDIR}/etc/repos-remote.conf \
        ${XBPS_MASTERDIR}/etc/xbps.d/20-repository-remote.conf

    if [ "$XBPS_MACHINE" = "x86_64" ]; then
        install -Dm644 ${XBPS_DISTDIR}/etc/repos-local-x86_64.conf \
            ${XBPS_MASTERDIR}/etc/xbps.d/12-repository-local-x86_64.conf
        install -Dm644 ${XBPS_DISTDIR}/etc/repos-remote-x86_64.conf \
            ${XBPS_MASTERDIR}/etc/xbps.d/22-repository-remote-x86_64.conf
    fi

    # if -N is set, comment out remote repositories from xbps.conf.
    if [ -n "$XBPS_SKIP_REMOTEREPOS" ]; then
        rm -f ${XBPS_MASTERDIR}/etc/xbps.d/20-repository-remote.conf
        rm -f ${XBPS_MASTERDIR}/etc/xbps.d/22-repository-remote-x86_64.conf
    fi

    # Copy host repos to the cross root.
    if [ -n "$XBPS_CROSS_BUILD" ]; then
        rm -rf $XBPS_MASTERDIR/$XBPS_CROSS_BASE/etc/xbps.d
        mkdir -p $XBPS_MASTERDIR/$XBPS_CROSS_BASE/etc/xbps.d
        cp ${XBPS_MASTERDIR}/etc/xbps.d/*.conf \
            $XBPS_MASTERDIR/$XBPS_CROSS_BASE/etc/xbps.d
        rm -f $XBPS_MASTERDIR/$XBPS_CROSS_BASE/etc/xbps.d/*-x86_64.conf
    fi

    if [ -z "$XBPS_SKIP_REMOTEREPOS" ]; then
        # Make sure to sync index for remote repositories.
        xbps-install -r $XBPS_MASTERDIR -S
    fi

    if [ -n "$XBPS_CROSS_BUILD" ]; then
        # Copy host keys to the target rootdir.
        mkdir -p $XBPS_MASTERDIR/$XBPS_CROSS_BASE/var/db/xbps/keys
        cp $XBPS_MASTERDIR/var/db/xbps/keys/*.plist \
            $XBPS_MASTERDIR/$XBPS_CROSS_BASE/var/db/xbps/keys
        # Make sure to sync index for remote repositories.
        if [ -z "$XBPS_SKIP_REMOTEREPOS" ]; then
            env -- XBPS_TARGET_ARCH=$XBPS_TARGET_MACHINE \
                xbps-install -r $XBPS_MASTERDIR/$XBPS_CROSS_BASE -S
        fi
    fi

    return 0
}

chroot_handler() {
    local action="$1" pkg="$2" rv=0 arg= _envargs=

    if [ -n "$IN_CHROOT" -o -z "$CHROOT_READY" ]; then
        return 0
    fi
    if [ ! -d $XBPS_MASTERDIR/void-packages ]; then
        mkdir -p $XBPS_MASTERDIR/void-packages
    fi

    [ -z "$action" -a -z "$pkg" ] && return 1

    case "$action" in
        fetch|extract|build|check|configure|install|install-destdir|pkg|build-pkg|bootstrap-update|chroot)
            chroot_prepare || return $?
            chroot_init || return $?
            chroot_sync_repos || return $?
            ;;
    esac

    if [ "$action" = "chroot" ]; then
        $XBPS_COMMONDIR/chroot-style/${XBPS_CHROOT_CMD:=uunshare}.sh \
            $XBPS_MASTERDIR $XBPS_DISTDIR "$XBPS_HOSTDIR" "$XBPS_CHROOT_CMD_ARGS" /bin/xbps-shell
        rv=$?
    else
        [ -n "$XBPS_CROSS_BUILD" ] && arg="$arg -a $XBPS_CROSS_BUILD"
        [ -n "$XBPS_KEEP_ALL" ] && arg="$arg -C"
        [ -n "$NOCOLORS" ] && arg="$arg -L"
        [ -n "$XBPS_BUILD_FORCEMODE" ] && arg="$arg -f"
        [ -n "$XBPS_MAKEJOBS" ] && arg="$arg -j$XBPS_MAKEJOBS"
        [ -n "$XBPS_DEBUG_PKGS" ] && arg="$arg -g"
        [ -n "$XBPS_CHECK_PKGS" ] && arg="$arg -Q"
        [ -n "$XBPS_BUILD_ONLY_ONE_PKG" ] && arg="$arg -1"
        [ -n "$XBPS_QUIET" ] && arg="$arg -q"
        [ -n "$XBPS_SKIP_DEPS" ] && arg="$arg -I"
        [ -n "$XBPS_ALT_REPOSITORY" ] && arg="$arg -r $XBPS_ALT_REPOSITORY"
        [ -n "$XBPS_USE_GIT_REVS" ] && arg="$arg -G"
        [ -n "$XBPS_PKG_OPTIONS" ] && arg="$arg -o $XBPS_PKG_OPTIONS"
        [ -n "$XBPS_TEMP_MASTERDIR" ] && arg="$arg -t -C"
        [ -n "$XBPS_BINPKG_EXISTS" ] && arg="$arg -E"

        action="$arg $action"
        env -i -- PATH="/usr/bin:/usr/sbin:$PATH" SHELL=/bin/sh \
            HOME=/tmp IN_CHROOT=1 LC_COLLATE=C LANG=en_US.UTF-8 \
            SOURCE_DATE_EPOCH="$SOURCE_DATE_EPOCH" \
            $XBPS_COMMONDIR/chroot-style/${XBPS_CHROOT_CMD:=uunshare}.sh \
            $XBPS_MASTERDIR $XBPS_DISTDIR "$XBPS_HOSTDIR" "$XBPS_CHROOT_CMD_ARGS" \
            /void-packages/xbps-src $action $pkg
        rv=$?
    fi

    return $rv
}
