#
# Replace hardcoded paths in perl scripts.
#

. $XBPS_TMPLHELPDIR/replace-interpreter.sh

replace_interpreter perl parser/gapi2xml.pl
replace_interpreter perl parser/gapi_pp.pl
