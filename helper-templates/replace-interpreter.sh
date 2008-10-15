#
# This helper replaces shebang paths pointing to the correct ones
# as used by xbps. Multiple languages are supported:
#
#	- GNU Bash
#	- Perl
#	- Python
#

bash_regexp=".*sh"
perl_regexp=".*perl[^[:space:]]*"
python_regexp=".*python[^[:space:]]*"

replace_interpreter()
{
	local lang="$1"
	local file="$2"
	local trsb=
	local orsb=

	[ -z $lang -o -z $file ] && return 1

	case $lang in
	bash)
		orsb=$bash_regexp
		trpath="$XBPS_MASTERDIR/bin/bash"
		;;
	perl)
		orsb=$perl_regexp
		trpath="$XBPS_MASTERDIR/bin/perl"
		;;
	python)
		orsb=$python_regexp
		trpath="$XBPS_MASTERDIR/bin/python"
		;;
	*)
		;;
	esac

	if [ -f $wrksrc/$file ]; then
		$sed_cmd -e "1s|^#![[:space:]]*${orsb}|#!${trpath}|"	\
			$wrksrc/$file > $wrksrc/$file.in && 		\
			$mv_cmd $wrksrc/$file.in $wrksrc/$file &&	\
			$chmod_cmd a+x $wrksrc/$file &&			\
			echo "=> Transformed $lang script: ${file##$wrksrc}."
	else
		echo "=> Ignoring unexistent $lang script: ${file##$wrksrc}."
	fi
}
