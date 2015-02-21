hostmakedepends+=" go"
if [ "$CROSS_BUILD" ]; then
	hostmakedepends+=" go-cross-linux"
fi
nostrip=yes
