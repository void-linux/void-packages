lib32disabled=yes
if [ -z "$nopyprovides" ] || [ -z "$noverifypydeps" ]; then
	hostmakedepends+=" python3-packaging-bootstrap"
fi
makedepends+=" python3"
build_helper+=" python3"
