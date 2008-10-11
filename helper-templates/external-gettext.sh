#
# This helper overrides some GNU autoconf variables to be able to
# use the external GNU gettext tools provided by a package.
#

local GMSGFMT_CMD="$PKGFS_MASTERDIR/bin/msgfmt"
local MSGFMT_CMD="$PKGFS_MASTERDIR/bin/msgfmt"
local MSGMERGE_CMD="$PKGFS_MASTERDIR/bin/msgmerge"
local XGETTEXT_CMD="$PKGFS_MASTERDIR/bin/xgettext"

configure_env="ac_cv_path_GMSGFMT=$GMSGFMT_CMD $configure_env"
configure_env="ac_cv_path_MSGFMT=$MSGFMT_CMD $configure_env"
configure_env="ac_cv_path_MSGMERGE=$MSGMERGE_CMD $configure_env"
configure_env="ac_cv_path_XGETTEXT=$XGETTEXT_CMD $configure_env"
