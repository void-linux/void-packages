# Fixup Config.pm to look at PKGFS_MASTERDIR, this helps modules
# to use correct dirs while building/installing them.

perl_version=5.10.0
perl_arch=$(uname -m)
perl_libdir=$PKGFS_DESTDIR/$pkgname/lib/perl5
config_pm=$perl_libdir/$perl_version/$perl_arch-netbsd-thread-multi/Config.pm

$sed_cmd -e "s|$PKGFS_DESTDIR\/$pkgname|$PKGFS_MASTERDIR|g" \
	$config_pm > $config_pm.in
$chmod_cmd 444 $config_pm.in
$mv_cmd -f $config_pm.in $config_pm
