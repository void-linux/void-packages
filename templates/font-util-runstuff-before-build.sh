#
# Replace perl path in bdftrunace.pl before installing.
#

. $PKGFS_TMPLHELPDIR/perl-replace-path.sh
perl_transform_file $wrksrc/bdftruncate.pl
