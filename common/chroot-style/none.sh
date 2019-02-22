#!/bin/sh
#
# This chroot script uses symlinks to emulate being in a chroot,
# While the chroot is actually the host machine itself
# This is useful for privilege less environments as Docker containers
#

readonly MASTERDIR="$1"
readonly DISTDIR="$2"
readonly HOSTDIR="$3"
readonly EXTRA_ARGS="$4"
readonly CMD="$5"
shift 5

if [ -z "$MASTERDIR" -o -z "$DISTDIR" ]; then
  echo "$0 MASTERDIR/DISTDIR not set"
  exit 1
fi

msg_red() {
    # error messages in bold/red
    [ -n "$NOCOLORS" ] || printf >&2 "\033[1m\033[31m"
    printf >&2 "=> ERROR: $@"
    [ -n "$NOCOLORS" ] || printf >&2 "\033[m"
}

fake_mount() {
  #
  # Fake mount works by removing the dir, and replacing it with a symlink
  # This created the illusion of a bind.
  #

  local FROM="$1";
  local TO="$2"
  if [ -d "$TO" ]; then
    rmdir "$TO";
    if [ -d "$TO" ]; then
      msg_red "Can't mount $FROM to $TO because $TO is a non-empty dir\n";
      exit 1;
    fi
  fi
  ln -s "$FROM" "$TO";
}

fake_umount() {
  #
  # Remove the symlink and recreate the dir
  #

  rm "$1";
  mkdir "$1";
}

check_explicit_setting() {
  . etc/conf
  if [ -z "${XBPS_ALLOW_CHROOT_BREAKOUT}" -o "${XBPS_ALLOW_CHROOT_BREAKOUT}" != "yes" ]; then
    msg_red "You're trying to use chroot-style none, this chroot style however affects your host machine\n"
    msg_red "If you're sure about this run 'echo XBPS_ALLOW_CHROOT_BREAKOUT=yes >> etc/conf'\n"
    exit 1;
  fi
}

check_masterdir_is_root() {
  if [ "$(readlink "${MASTERDIR}")" != "/" ]; then
    msg_red "masterdir (${MASTERDIR}) should be symlinked to /, can't continue\n";
    exit 1;
  fi
}

run_chroot() {
  fake_mount $DISTDIR $MASTERDIR/void-packages;

  if [ ! -z "$HOSTDIR" ]; then
    fake_mount $HOSTDIR $MASTERDIR/host;
  fi

  local mounts=""
  local from=""
  local to=""
  # xbps-src may send some other binds, parse them here
  while getopts 'b:' c -- "$EXTRA_ARGS"; do
    # Skip everything that's not a bind
    [ "$c" = "b" ] || continue;

    from="$(cut -d: -f1 <<< "$OPTARG")";
    to="$(cut -d: -f2 <<< "$OPTARG")";
    fake_mount "${from}" "${to}";
    # Save created mounts so we can clean them up later
    mounts+="${to} "
  done

  local old_pwd="${PWD}";
  # To give the illusion we entered the chroot, cd to /
  cd /;
  # Tell xbps-src that we are "in the chroot"
  # Start with `env` so our environment var's stay the same
  env IN_CHROOT=1 $CMD $@;
  # Save exit code for after clean up
  local ret="$?";
  # cd back to the old pwd, so everything is the same again
  cd "${old_pwd}";

  if [ ! -z "$HOSTDIR" ]; then
    fake_umount $MASTERDIR/host;
  fi

  fake_umount $MASTERDIR/void-packages;

  # "umount" on demand created "mounts"
  for i in $mounts; do
    fake_umount "$i";
  done

  # Exit with the returned exit code
  exit "${ret}";
}

check_explicit_setting;
check_masterdir_is_root;
run_chroot "$@";
