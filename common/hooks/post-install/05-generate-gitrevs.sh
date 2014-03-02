# This hook generates a file in ${wrksrc}/.xbps_git_revs with the last
# commit sha1 (in short mode) for all files of a source pkg.

hook() {
	local GITREVS_FILE=${wrksrc}/.xbps_${sourcepkg}_git_revs
	local _revs= _out= f= _filerev= _files=

	# If XBPS_USE_GIT_REVS is disabled in conf file don't continue.
	if [ -z $XBPS_USE_GIT_REVS ]; then
		return
	fi
	# If the file exists don't regenerate it again.
	if [ -s ${GITREVS_FILE} ]; then
		return
	fi
	# Get the git revisions from this source pkg.
	cd ${XBPS_SRCPKGDIR}
	_files=$(git ls-files ${sourcepkg})
	[ -z "${_files}" ] && return

	for f in ${_files}; do
		_filerev=$(git rev-list --abbrev-commit HEAD $f | head -n1)
		[ -z "${_filerev}" ] && continue
		_out="${f} ${_filerev}"
		if [ -z "${_revs}" ]; then
			_revs="${_out}"
		else
			_revs="${_revs} ${_out}"
		fi
	done

	set -- ${_revs}
	while [ $# -gt 0 ]; do
		local _file=$1; local _rev=$2
		echo "${_file}: ${_rev}"
		echo "${_file}: ${_rev}" >> ${GITREVS_FILE}
		shift 2
	done
}
