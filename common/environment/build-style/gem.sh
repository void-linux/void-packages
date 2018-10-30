lib32disabled=yes
hostmakedepends+=" ruby"
depends+=" ruby"
noarch=yes

# default to rubygems
if [ -z "$distfiles" ]; then
	distfiles="https://rubygems.org/downloads/${pkgname#ruby-}-${version}.gem"
fi
