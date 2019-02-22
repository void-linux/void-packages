# This dockerfile may be ran from a zap'ed void-package git clone
# You can mount .void-packages/hostdir from your host so build packages are available from host
# from there on it's just running ./xbps-src pkg [your package]
# If desired you may also mount your own srcpkgs over .void-packages/srcpkgs to build your own packages
# Don't forget to also mount .git on .void-packages/.git then
FROM d.xr.to/base
COPY .git .void-packages/.git
COPY srcpkgs .void-packages/srcpkgs
COPY etc .void-packages/etc
COPY common .void-packages/common
COPY xbps-src .void-packages/xbps-src
WORKDIR /.void-packages
RUN xbps-install -Sy coreutils git chroot-util-linux chroot-gawk \
      && echo XBPS_ALLOW_CHROOT_BREAKOUT=yes >> etc/conf \
      && echo XBPS_CHROOT_CMD=none >> etc/conf
RUN ./xbps-src binary-bootstrap-host
