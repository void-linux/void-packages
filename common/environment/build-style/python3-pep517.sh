lib32disabled=yes
hostmakedepends+=" python3-build python3-installer-bootstrap"
if [ -z "$nopyprovides" ] || [ -z "$noverifypydeps" ]; then
	hostmakedepends+=" python3-packaging-bootstrap"
fi
build_helper+=" python3"
export PYTHONPATH="${PYTHONPATH}:/${py3_sitelib}-bootstrap"
