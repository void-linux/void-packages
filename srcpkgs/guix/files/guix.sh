# Explicitly initialize XDG base directory variables to ease compatibility
# with Guix System: see <https://issues.guix.gnu.org/56050#3>.
export XCURSOR_PATH="${XCURSOR_PATH:-$HOME/.local/share/icons:$HOME/.icons:/usr/local/share/icons:/usr/share/icons}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_DATA_DIRS="${XDG_DATA_DIRS:-/usr/local/share/:/usr/share/}"
export XDG_CONFIG_DIRS="${XDG_CONFIG_DIRS:-/etc/xdg}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
# no default for XDG_RUNTIME_DIR (depends on foreign distro for semantics)

# `guix pull` profile
GUIX_PROFILE="$HOME/.config/guix/current"
export PATH="$GUIX_PROFILE/bin${PATH:+:}$PATH"
# Add to INFOPATH and MANPATH so the latest Guix documentation is available to
# info and man readers.  When INFOPATH is unset, add a trailing colon so Emacs
# searches 'Info-default-directory-list'.  When MANPATH is unset, add a
# trailing colon so the system default search path is used.
export INFOPATH="$GUIX_PROFILE/share/info:$INFOPATH"
export MANPATH="$GUIX_PROFILE/share/man:$MANPATH"

# User's default profile, if it exists
GUIX_PROFILE="$HOME/.guix-profile"
if [ -f "$GUIX_PROFILE/etc/profile" ]; then
  . "$GUIX_PROFILE/etc/profile"

  # see info '(guix) Application Setup'
  export GUIX_LOCPATH="$GUIX_PROFILE/lib/locale${GUIX_LOCPATH:+:}$GUIX_LOCPATH"

  # Documentation search paths may be handled by $GUIX_PROFILE/etc/profile if
  # the user installs info and man readers via Guix.  If the user doesn’t,
  # explicitly add to them so documentation for software from ‘guix install’
  # is available to the system info and man readers.
  case $INFOPATH in
    *$GUIX_PROFILE/share/info*) ;;
    *) export INFOPATH="$GUIX_PROFILE/share/info:$INFOPATH" ;;
  esac
  case $MANPATH in
    *$GUIX_PROFILE/share/man*) ;;
    *) export MANPATH="$GUIX_PROFILE/share/man:$MANPATH"
  esac

  case $XDG_DATA_DIRS in
    *$GUIX_PROFILE/share*) ;;
    *) export XDG_DATA_DIRS="$GUIX_PROFILE/share:$XDG_DATA_DIRS"
  esac
fi

# NOTE: Guix Home handles its own profile initialization in ~/.profile. See
# info '(guix) Configuring the Shell'.

# Clean up after ourselves.
unset GUIX_PROFILE
