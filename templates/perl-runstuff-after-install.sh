# Fixup Config.pm to look at XBPS_MASTERDIR, this helps modules
# to use correct dirs while building/installing them.

perl_arch=$(uname -m)
perl_libdir=$XBPS_DESTDIR/$pkgname-$version/lib/perl5
config_pm=$perl_libdir/$version/$perl_arch-netbsd-thread-multi/Config.pm

$sed_cmd -e "s|$XBPS_DESTDIR\/$pkgname-$version|$XBPS_MASTERDIR|g" \
	$config_pm > $config_pm.in
$chmod_cmd 444 $config_pm.in
$mv_cmd -f $config_pm.in $config_pm
