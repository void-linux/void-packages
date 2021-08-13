# -*-* shell *-*-

# enable aliases
shopt -s expand_aliases

# clear all aliases
unalias -a

# disable wildcards helper
_noglob_helper() {
       set +f
       "$@"
}

# Apply _noglob to v* commands
for cmd in vinstall vcopy vcompletion vmove vmkdir vbin vman vdoc vconf vsconf vlicense vsv; do
       alias ${cmd}="set -f; _noglob_helper _${cmd}"
done

_vsv() {
	local service="$1"
	local LN_OPTS="-s"

	if [ $# -lt 1 ]; then
		msg_red "$pkgver: vsv: 1 argument expected: <service>\n"
		return 1
	fi

	if [ -n "$XBPS_BUILD_FORCEMODE" ]; then
		LN_OPTS+="f"
	fi

	vmkdir etc/sv
	vcopy "${FILESDIR}/$service" etc/sv
	chmod 755 ${PKGDESTDIR}/etc/sv/${service}/run
	if [ -r ${PKGDESTDIR}/etc/sv/${service}/finish ]; then
		chmod 755 ${PKGDESTDIR}/etc/sv/${service}/finish
	fi
	ln ${LN_OPTS} /run/runit/supervise.${service} ${PKGDESTDIR}/etc/sv/${service}/supervise
	if [ -r ${PKGDESTDIR}/etc/sv/${service}/log/run ]; then
		chmod 755 ${PKGDESTDIR}/etc/sv/${service}/log/run
		ln ${LN_OPTS} /run/runit/supervise.${service}-log ${PKGDESTDIR}/etc/sv/${service}/log/supervise
	fi
}

_vbin() {
	local file="$1" targetfile="$2"

	if [ $# -lt 1 ]; then
		msg_red "$pkgver: vbin: 1 argument expected: <file>\n"
		return 1
	fi

	vinstall "$file" 755 usr/bin "$targetfile"
}

_vman() {
	local file="$1" target="${2:-${1##*/}}"

	if [ $# -lt 1 ]; then
		msg_red "$pkgver: vman: 1 argument expected: <file>\n"
		return 1
	fi

	suffix=${target##*.}

	if [[ $suffix == gz ]]
	then
		gunzip "$file"
		file="${file:0:-3}"
		target="${target:0:-3}"
		suffix=${target##*.}
	fi

	if [[ $suffix == bz2 ]]
	then
		bunzip2 "$file"
		file="${file:0:-4}"
		target="${target:0:-4}"
		suffix=${target##*.}
	fi

	if  [[ $target =~ (.*)\.([a-z][a-z](_[A-Z][A-Z])?)\.(.*) ]]
	then
		name=${BASH_REMATCH[1]}.${BASH_REMATCH[4]}
		mandir=${BASH_REMATCH[2]}/man${suffix:0:1}
	else
		name=$target
		mandir=man${suffix:0:1}
	fi

	if [[ ${mandir} == *man[0-9n] ]] ; then
		vinstall "$file" 644 "usr/share/man/${mandir}" "$name"
		return 0
	fi

	msg_red "$pkgver: vman: Filename '${target}' does not look like a man page\n"
	return 1
}

_vdoc() {
	local file="$1" targetfile="$2"

	if [ $# -lt 1 ]; then
		msg_red "$pkgver: vdoc: 1 argument expected: <file>\n"
		return 1
	fi

	vinstall "$file" 644 "usr/share/doc/${pkgname}" "$targetfile"
}

_vconf() {
	local file="$1" targetfile="$2"

	if [ $# -lt 1 ]; then
		msg_red "$pkgver: vconf: 1 argument expected: <file>\n"
		return 1
	fi

	vinstall "$file" 644 etc "$targetfile"
}

_vsconf() {
	local file="$1" targetfile="$2"

	if [ $# -lt 1 ]; then
		msg_red "$pkgver: vsconf: 1 argument expected: <file>\n"
		return 1
	fi

	vinstall "$file" 644 "usr/share/examples/${pkgname}" "$targetfile"
}

_vlicense() {
	local file="$1" targetfile="$2"

	if [ $# -lt 1 ]; then
		msg_red "$pkgver: vlicense: 1 argument expected: <file>\n"
		return 1
	fi

	vinstall "$file" 644 "usr/share/licenses/${pkgname}" "$targetfile"
}

_vinstall() {
	local file="$1" mode="$2" targetdir="$3" targetfile="$4"

	if [ -z "$PKGDESTDIR" ]; then
		msg_red "$pkgver: vinstall: PKGDESTDIR unset, can't continue...\n"
		return 1
	fi

	if [ $# -lt 3 ]; then
		msg_red "$pkgver: vinstall: 3 arguments expected: <file> <mode> <target-directory>\n"
		return 1
	fi

	if [ ! -r "${file}" ]; then
		msg_red "$pkgver: vinstall: cannot find '$file'...\n"
		return 1
	fi

	if [ -z "$targetfile" ]; then
		install -Dm${mode} "${file}" "${PKGDESTDIR}/${targetdir}/${file##*/}"
	else
		install -Dm${mode} "${file}" "${PKGDESTDIR}/${targetdir}/${targetfile##*/}"
	fi
}

_vcopy() {
	local files="$1" targetdir="$2"

	if [ -z "$PKGDESTDIR" ]; then
		msg_red "$pkgver: vcopy: PKGDESTDIR unset, can't continue...\n"
		return 1
	fi
	if [ $# -ne 2 ]; then
		msg_red "$pkgver: vcopy: 2 arguments expected: <files> <target-directory>\n"
		return 1
	fi

	cp -a $files ${PKGDESTDIR}/${targetdir}
}

_vmove() {
	local f files="$1" _targetdir

	if [ -z "$DESTDIR" ]; then
		msg_red "$pkgver: vmove: DESTDIR unset, can't continue...\n"
		return 1
	elif [ -z "$PKGDESTDIR" ]; then
		msg_red "$pkgver: vmove: PKGDESTDIR unset, can't continue...\n"
		return 1
	elif [ "$DESTDIR" = "$PKGDESTDIR" ]; then
		msg_red "$pkgver: vmove is intended to be used in pkg_install\n"
		return 1
	fi
	if [ $# -ne 1 ]; then
		msg_red "$pkgver: vmove: 1 argument expected: <files>\n"
		return 1
	fi
	for f in ${files}; do
		_targetdir=${f%/*}/
		break
	done

	if [ -z "${_targetdir}" ]; then
		[ ! -d ${PKGDESTDIR} ] && install -d ${PKGDESTDIR}
		mv ${DESTDIR}/$files ${PKGDESTDIR}
	else
		if [ ! -d ${PKGDESTDIR}/${_targetdir} ]; then
			install -d ${PKGDESTDIR}/${_targetdir}
		fi
		mv ${DESTDIR}/$files ${PKGDESTDIR}/${_targetdir}
	fi
}

_vmkdir() {
	local dir="$1" mode="$2"

	if [ -z "$PKGDESTDIR" ]; then
		msg_red "$pkgver: vmkdir: PKGDESTDIR unset, can't continue...\n"
		return 1
	fi

	if [ -z "$dir" ]; then
		msg_red "vmkdir: directory argument unset.\n"
		return 1
	fi

	if [ -z "$mode" ]; then
		install -d ${PKGDESTDIR}/${dir}
	else
		install -dm${mode} ${PKGDESTDIR}/${dir}
	fi
}

_vcompletion() {
	local file="$1" shell="$2" cmd="${3:-${pkgname}}"
	local _bash_completion_dir=usr/share/bash-completion/completions/
	local _fish_completion_dir=usr/share/fish/vendor_completions.d/
	local _zsh_completion_dir=usr/share/zsh/site-functions/

	if [ $# -lt 2 ]; then
		msg_red "$pkgver: vcompletion: 2 arguments expected: <file> <shell>\n"
		return 1
	fi

	if ! [ -f "$file" ]; then
		msg_red "$pkgver: vcompletion: file $file doesn't exist\n"
	fi

	case "$shell" in
		bash) vinstall "$file" 0644 $_bash_completion_dir "${cmd}" ;;
		fish) vinstall "$file" 0644 $_fish_completion_dir "${cmd}.fish" ;;
		zsh) vinstall "$file" 0644 $_zsh_completion_dir "_${cmd}" ;;
		*)
			msg_red "$pkgver: vcompletion: unknown shell ${shell}"
			return 1
			;;
	esac
}
