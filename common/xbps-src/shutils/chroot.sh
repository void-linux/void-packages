# vim: set ts=4 sw=4 et:

install_base_chroot() {
    local _bootstrap_arch _target_arch="$1"
    [ "$CHROOT_READY" ] && return
    if [ "$_target_arch" = "bootstrap" ]; then
        _target_arch=""
        unset XBPS_INSTALL_ARGS
    fi
    # binary bootstrap
    msg_normal "xbps-src: installing base-chroot...\n"
    if [ -n "$_target_arch" ]; then
        _bootstrap_arch="env XBPS_TARGET_ARCH=$_target_arch"
    fi
    (export XBPS_MACHINE="$_target_arch" XBPS_ARCH="$_target_arch"; chroot_sync_repodata)
    ${_bootstrap_arch} $XBPS_INSTALL_CMD ${XBPS_INSTALL_ARGS} -y base-chroot
    if [ $? -ne 0 ]; then
        msg_error "xbps-src: failed to install base-chroot!\n"
    fi
    # Reconfigure base-files to create dirs/symlinks.
    if xbps-query -r $XBPS_MASTERDIR base-files &>/dev/null; then
        XBPS_ARCH="$_target_arch" xbps-reconfigure -r $XBPS_MASTERDIR -f base-files &>/dev/null
    fi

    msg_normal "xbps-src: installed base-chroot successfully!\n"
    chroot_prepare "$_target_arch" || msg_error "xbps-src: failed to initialize chroot!\n"
    chroot_check
    chroot_handler clean
}

reconfigure_base_chroot() {
    local statefile="$XBPS_MASTERDIR/.xbps_chroot_configured"
    local pkgs="glibc-locales ca-certificates"
    [ -z "$IN_CHROOT" -o -e $statefile ] && return 0
    # Reconfigure ca-certificates.
    msg_normal "xbps-src: reconfiguring base-chroot...\n"
    for f in ${pkgs}; do
        if xbps-query -r $XBPS_MASTERDIR $f &>/dev/null; then
            xbps-reconfigure -r $XBPS_MASTERDIR -f $f
        fi
    done
    touch -f $statefile
}

update_base_chroot() {
    local keep_all_force=$1
    [ -z "$CHROOT_READY" ] && return
    msg_normal "xbps-src: updating software in $XBPS_MASTERDIR masterdir...\n"
    # no need to sync repodata, chroot_sync_repodata() does it for us.
    if $(${XBPS_INSTALL_CMD} ${XBPS_INSTALL_ARGS} -nu|grep -q xbps); then
        ${XBPS_INSTALL_CMD} ${XBPS_INSTALL_ARGS} -yu xbps || msg_error "xbps-src: failed to update xbps!\n"
    fi
    ${XBPS_INSTALL_CMD} ${XBPS_INSTALL_ARGS} -yu || msg_error "xbps-src: failed to update base-chroot!\n"
    msg_normal "xbps-src: cleaning up $XBPS_MASTERDIR masterdir...\n"
    [ -z "$XBPS_KEEP_ALL" -a -z "$XBPS_SKIP_DEPS" ] && remove_pkg_autodeps
    [ -z "$XBPS_KEEP_ALL" -a -z "$keep_all_force" ] && rm -rf $XBPS_MASTERDIR/builddir $XBPS_MASTERDIR/destdir
}

# FIXME: $XBPS_FFLAGS is not set when chroot_init() is run
# It is set in common/build-profiles/bootstrap.sh but lost somewhere?
chroot_init() {
    mkdir -p $XBPS_MASTERDIR/etc/xbps

    : ${XBPS_CONFIG_FILE:=/dev/null}
    cat > $XBPS_MASTERDIR/etc/xbps/xbps-src.conf <<_EOF
# Generated configuration file by xbps-src, DO NOT EDIT!
$(grep -E '^XBPS_.*' "$XBPS_CONFIG_FILE")
XBPS_MASTERDIR=/
XBPS_CFLAGS="$XBPS_CFLAGS"
XBPS_CXXFLAGS="$XBPS_CXXFLAGS"
XBPS_FFLAGS="$XBPS_FFLAGS"
XBPS_CPPFLAGS="$XBPS_CPPFLAGS"
XBPS_LDFLAGS="$XBPS_LDFLAGS"
XBPS_HOSTDIR=/host
# End of configuration file.
_EOF

    # Create custom script to start the chroot bash shell.
    cat > $XBPS_MASTERDIR/bin/xbps-shell <<_EOF
#!/bin/sh

XBPS_SRC_VERSION="$XBPS_SRC_VERSION"

. /etc/xbps/xbps-src.conf

PATH=/void-packages:/usr/bin

exec env -i -- SHELL=/bin/sh PATH="\$PATH" DISTCC_HOSTS="\$XBPS_DISTCC_HOSTS" DISTCC_DIR="/host/distcc" \
    ${XBPS_ARCH+XBPS_ARCH=$XBPS_ARCH} ${XBPS_CHECK_PKGS+XBPS_CHECK_PKGS=$XBPS_CHECK_PKGS} \
    CCACHE_DIR="/host/ccache" IN_CHROOT=1 LC_COLLATE=C LANG=en_US.UTF-8 TERM=linux HOME="/tmp" \
    PS1="[\u@$XBPS_MASTERDIR \W]$ " /bin/bash +h "\$@"
_EOF

    chmod 755 $XBPS_MASTERDIR/bin/xbps-shell
    cp -f /etc/resolv.conf $XBPS_MASTERDIR/etc
    return 0
}

chroot_prepare() {
    local f=

    if [ -f $XBPS_MASTERDIR/.xbps_chroot_init ]; then
        return 0
    elif [ ! -f $XBPS_MASTERDIR/bin/bash ]; then
        msg_error "Bootstrap not installed in $XBPS_MASTERDIR, can't continue.\n"
    fi

    # Some software expects /etc/localtime to be a symbolic link it can read to
    # determine the name of the time zone, so set up the expected link
    # structure.
    ln -sf ../usr/share/zoneinfo/UTC $XBPS_MASTERDIR/etc/localtime

    for f in dev sys tmp proc host boot; do
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

    # Prepare default locale: en_US.UTF-8.
    if [ -s ${XBPS_MASTERDIR}/etc/default/libc-locales ]; then
        printf '%s\n' \
            'C.UTF-8 UTF-8' \
            'en_US.UTF-8 UTF-8' \
            >> ${XBPS_MASTERDIR}/etc/default/libc-locales
    fi

    touch -f $XBPS_MASTERDIR/.xbps_chroot_init
    [ -n "$1" ] && echo $1 >> $XBPS_MASTERDIR/.xbps_chroot_init

    return 0
}

chroot_handler() {
    local action="$1" pkg="$2" rv=0 arg= _envargs=

    [ -z "$action" -a -z "$pkg" ] && return 1

    if [ -n "$IN_CHROOT" -o -z "$CHROOT_READY" ]; then
        return 0
    fi
    if [ ! -d $XBPS_MASTERDIR/void-packages ]; then
        mkdir -p $XBPS_MASTERDIR/void-packages
    fi

    case "$action" in
        fetch|extract|patch|configure|build|check|install|pkg|bootstrap-update|chroot|clean)
            chroot_prepare || return $?
            chroot_init || return $?
            ;;
    esac

    if [ "$action" = "chroot" ]; then
        $XBPS_COMMONDIR/chroot-style/${XBPS_CHROOT_CMD:=uunshare}.sh \
            $XBPS_MASTERDIR $XBPS_DISTDIR "$XBPS_HOSTDIR" "$XBPS_CHROOT_CMD_ARGS" /bin/xbps-shell
        rv=$?
    else
        env -i -- PATH="/usr/bin:$PATH" SHELL=/bin/sh \
            HOME=/tmp IN_CHROOT=1 LC_COLLATE=C LANG=en_US.UTF-8 \
            ${http_proxy:+http_proxy="${http_proxy}"} \
            ${https_proxy:+https_proxy="${https_proxy}"} \
            ${ftp_proxy:+ftp_proxy="${ftp_proxy}"} \
            ${all_proxy:+all_proxy="${all_proxy}"} \
            ${no_proxy:+no_proxy="${no_proxy}"} \
            ${HTTP_PROXY:+HTTP_PROXY="${HTTP_PROXY}"} \
            ${HTTPS_PROXY:+HTTPS_PROXY="${HTTPS_PROXY}"} \
            ${FTP_PROXY:+FTP_PROXY="${FTP_PROXY}"} \
            ${SOCKS_PROXY:+SOCKS_PROXY="${SOCKS_PROXY}"} \
            ${NO_PROXY:+NO_PROXY="${NO_PROXY}"} \
            ${HTTP_PROXY_AUTH:+HTTP_PROXY_AUTH="${HTTP_PROXY_AUTH}"} \
            ${FTP_RETRIES:+FTP_RETRIES="${FTP_RETRIES}"} \
            SOURCE_DATE_EPOCH="$SOURCE_DATE_EPOCH" \
            XBPS_GIT_REVS="$XBPS_GIT_REVS" \
            XBPS_ALLOW_CHROOT_BREAKOUT="$XBPS_ALLOW_CHROOT_BREAKOUT" \
            XBPS_TEMP_MASTERDIR="$XBPS_TEMP_MASTERDIR" \
            ${XBPS_ALT_REPOSITORY:+XBPS_ALT_REPOSITORY=$XBPS_ALT_REPOSITORY} \
            $XBPS_COMMONDIR/chroot-style/${XBPS_CHROOT_CMD:=uunshare}.sh \
            $XBPS_MASTERDIR $XBPS_DISTDIR "$XBPS_HOSTDIR" "$XBPS_CHROOT_CMD_ARGS" \
            /void-packages/xbps-src $XBPS_OPTIONS $action $pkg
        rv=$?
    fi

    return $rv
}

chroot_sync_repodata() {
    local f= hostdir= confdir= crossconfdir=

    # always start with an empty xbps.d
    confdir=$XBPS_MASTERDIR/etc/xbps.d
    crossconfdir=$XBPS_MASTERDIR/$XBPS_CROSS_BASE/etc/xbps.d

    [ -d $confdir ] && rm -rf $confdir
    [ -d $crossconfdir ] && rm -rf $crossconfdir

    if [ -d $XBPS_DISTDIR/etc/xbps.d/custom ]; then
        mkdir -p $confdir $crossconfdir
        cp -f $XBPS_DISTDIR/etc/xbps.d/custom/*.conf $confdir
        cp -f $XBPS_DISTDIR/etc/xbps.d/custom/*.conf $crossconfdir
    fi
    if [ "$CHROOT_READY" ]; then
        hostdir=/host
    else
        hostdir=$XBPS_HOSTDIR
    fi

    # Update xbps alternative repository if set.
    mkdir -p $confdir
    if [ -n "$XBPS_ALT_REPOSITORY" ]; then
        cat <<- ! > $confdir/00-repository-alt-local.conf
		repository=$hostdir/binpkgs/${XBPS_ALT_REPOSITORY}/bootstrap
		repository=$hostdir/binpkgs/${XBPS_ALT_REPOSITORY}
		repository=$hostdir/binpkgs/${XBPS_ALT_REPOSITORY}/nonfree
		repository=$hostdir/binpkgs/${XBPS_ALT_REPOSITORY}/debug
		!
        if [ "$XBPS_MACHINE" = "x86_64" ]; then
            cat <<- ! >> $confdir/00-repository-alt-local.conf
			repository=$hostdir/binpkgs/${XBPS_ALT_REPOSITORY}/multilib/bootstrap
			repository=$hostdir/binpkgs/${XBPS_ALT_REPOSITORY}/multilib
			repository=$hostdir/binpkgs/${XBPS_ALT_REPOSITORY}/multilib/nonfree
			!
        fi
    else
        rm -f $confdir/00-repository-alt-local.conf
    fi

    # Disable 00-repository-main.conf from share/xbps.d (part of xbps)
    ln -s /dev/null $confdir/00-repository-main.conf

    # Generate xbps.d(5) configuration files for repositories
    sed -e "s,/host,$hostdir,g" ${XBPS_DISTDIR}/etc/xbps.d/repos-local.conf \
        > $confdir/10-repository-local.conf

    # Install multilib conf for local repos if it exists for the architecture
    if [ -s "${XBPS_DISTDIR}/etc/xbps.d/repos-local-${XBPS_MACHINE}-multilib.conf" ]; then
        install -Dm644 ${XBPS_DISTDIR}/etc/xbps.d/repos-local-${XBPS_MACHINE}-multilib.conf \
            $confdir/12-repository-local-multilib.conf
    fi

    # mirror_sed is a sed script: nop by default
    local mirror_sed
    if [ -n "$XBPS_MIRROR" ]; then
        # when XBPS_MIRROR is set, mirror_sed rewrites remote repos
        mirror_sed="s|^repository=http.*/current|repository=${XBPS_MIRROR}|"
    fi

    if [ "$XBPS_SKIP_REMOTEREPOS" ]; then
        rm -f $confdir/*remote*
    else
        if [ -s "${XBPS_DISTDIR}/etc/xbps.d/repos-remote-${XBPS_MACHINE}.conf" ]; then
            # If per-architecture base remote repo config exists, use that
            sed -e "$mirror_sed" ${XBPS_DISTDIR}/etc/xbps.d/repos-remote-${XBPS_MACHINE}.conf \
                > $confdir/20-repository-remote.conf
        else
            # Otherwise use generic base for musl or glibc
            local suffix=
            case "$XBPS_MACHINE" in
                *-musl) suffix="-musl";;
            esac
            sed -e "$mirror_sed" ${XBPS_DISTDIR}/etc/xbps.d/repos-remote${suffix}.conf \
                > $confdir/20-repository-remote.conf
        fi
        # Install multilib conf for remote repos if it exists for the architecture
        if [ -s "${XBPS_DISTDIR}/etc/xbps.d/repos-remote-${XBPS_MACHINE}-multilib.conf" ]; then
            sed -e "$mirror_sed" ${XBPS_DISTDIR}/etc/xbps.d/repos-remote-${XBPS_MACHINE}-multilib.conf \
                > $confdir/22-repository-remote-multilib.conf
        fi
    fi

    echo "syslog=false" > $confdir/00-xbps-src.conf
    echo "staging=true" >> $confdir/00-xbps-src.conf

    # Copy host repos to the cross root.
    if [ -n "$XBPS_CROSS_BUILD" ]; then
        rm -rf $XBPS_MASTERDIR/$XBPS_CROSS_BASE/etc/xbps.d
        mkdir -p $XBPS_MASTERDIR/$XBPS_CROSS_BASE/etc/xbps.d
        # Disable 00-repository-main.conf from share/xbps.d (part of xbps)
        ln -s /dev/null $XBPS_MASTERDIR/$XBPS_CROSS_BASE/etc/xbps.d/00-repository-main.conf
        # copy xbps.d files from host for local repos
        cp ${XBPS_MASTERDIR}/etc/xbps.d/*local*.conf \
            $XBPS_MASTERDIR/$XBPS_CROSS_BASE/etc/xbps.d
        if [ "$XBPS_SKIP_REMOTEREPOS" ]; then
            rm -f $crossconfdir/*remote*
        else
            # Same general logic as above, just into cross root, and no multilib
            if [ -s "${XBPS_DISTDIR}/etc/xbps.d/repos-remote-${XBPS_TARGET_MACHINE}.conf" ]; then
                sed -e "$mirror_sed" ${XBPS_DISTDIR}/etc/xbps.d/repos-remote-${XBPS_TARGET_MACHINE}.conf \
                    > $crossconfdir/20-repository-remote.conf
            else
                local suffix=
                case "$XBPS_TARGET_MACHINE" in
                    *-musl) suffix="-musl"
                esac
                sed -e "$mirror_sed" ${XBPS_DISTDIR}/etc/xbps.d/repos-remote${suffix}.conf \
                    > $crossconfdir/20-repository-remote.conf
            fi
        fi

        echo "syslog=false" > $crossconfdir/00-xbps-src.conf
        echo "staging=true" >> $crossconfdir/00-xbps-src.conf
    fi


    # Copy xbps repository keys to the masterdir.
    mkdir -p $XBPS_MASTERDIR/var/db/xbps/keys
    cp -f $XBPS_COMMONDIR/repo-keys/*.plist $XBPS_MASTERDIR/var/db/xbps/keys
    if [ -n "$(shopt -s nullglob; echo "$XBPS_DISTDIR"/etc/repo-keys/*.plist)" ]; then
        cp -f "$XBPS_DISTDIR"/etc/repo-keys/*.plist "$XBPS_MASTERDIR"/var/db/xbps/keys
    fi

    # Make sure to sync index for remote repositories.
    if [ -z "$XBPS_SKIP_REMOTEREPOS" ]; then
        msg_normal "xbps-src: updating repositories for host ($XBPS_MACHINE)...\n"
        $XBPS_INSTALL_CMD $XBPS_INSTALL_ARGS -S
    fi

    if [ -n "$XBPS_CROSS_BUILD" ]; then
        # Copy host keys to the target rootdir.
        mkdir -p $XBPS_MASTERDIR/$XBPS_CROSS_BASE/var/db/xbps/keys
        cp $XBPS_MASTERDIR/var/db/xbps/keys/*.plist \
            $XBPS_MASTERDIR/$XBPS_CROSS_BASE/var/db/xbps/keys
        # Make sure to sync index for remote repositories.
        if [ -z "$XBPS_SKIP_REMOTEREPOS" ]; then
            msg_normal "xbps-src: updating repositories for target ($XBPS_TARGET_MACHINE)...\n"
            env -- XBPS_TARGET_ARCH=$XBPS_TARGET_MACHINE \
                $XBPS_INSTALL_CMD $XBPS_INSTALL_ARGS -r $XBPS_MASTERDIR/$XBPS_CROSS_BASE -S
        fi
    fi

    return 0
}
