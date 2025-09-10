lib32disabled=yes
hostmakedepends+=" python3-build python3-installer"
if [ -z "$nopyprovides" ] || [ -z "$noverifypydeps" ]; then
	hostmakedepends+=" python3-packaging-bootstrap"
fi
build_helper+=" python3"
