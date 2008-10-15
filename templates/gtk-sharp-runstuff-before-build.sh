#
# Replace hardcoded paths in perl scripts.
#

. $XBPS_TMPLHELPDIR/replace-interpreter.sh

replace_interpreter perl parser/gapi2xml.pl
replace_interpreter perl parser/gapi_pp.pl

#
# Fix up pkg-config files.
gtksharp_pc_files="gtk/gtk-sharp-2.0.pc.in gtkdotnet/gtk-dotnet-2.0.pc.in
 glib/glib-sharp-2.0.pc.in parser/gapi-2.0.pc.in glade/glade-sharp-2.0.pc.in"

for f in ${gtksharp_pc_files}; do
	$sed_cmd -e "s|\${pcfiledir}/../..|$XBPS_MASTERDIR|g"   \
		$wrksrc/$f > $wrksrc/$f.sed &&  \
		$mv_cmd $wrksrc/$f.sed $wrksrc/$f
done
