lib32disabled=yes
hostmakedepends+=" ruby"
depends+=" ruby"

# default to rubygems
if [ -z "$distfiles" ]; then
	distfiles="https://rubygems.org/downloads/${pkgname#ruby-}-${version}.gem"
fi
