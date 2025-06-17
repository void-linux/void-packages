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

replace_interpreter() {
	local lang="$1" file="$2" trsb orsb

	[ -z $lang -o -z $file ] && return 1

	case $lang in
	bash)
		orsb=$bash_regexp
		trpath="/bin/bash"
		;;
	perl)
		orsb=$perl_regexp
		trpath="/usr/bin/perl"
		;;
	python)
		orsb=$python_regexp
		trpath="/usr/bin/python"
		;;
	*)
		;;
	esac

	if [ -f $file ]; then
		sed -i -e "1s|^#![[:space:]]*${orsb}|#!${trpath}|" $file
		msg_normal "Transformed $lang script: ${file##$wrksrc}.\n"
	else
		msg_warn "Ignoring nonexistent $lang script: ${file##$wrksrc}.\n"
	fi
}
