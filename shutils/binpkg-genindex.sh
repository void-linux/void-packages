#-
# Copyright (c) 2008 Juan Romero Pardines.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#-

XBPS_PKGINDEX_VERSION="1.0" # Current version for pkgindex plist

#
# These functions write a package index for a repository, with details about
# all available binary packages.
#
write_repo_pkgindex()
{
	local repodir="$1"
	local propsf=
	local pkgname=
	local pkgnbase=
	local pkgsum=
	local pkgindexf=
	local tmppkgdir=
	local i=
	local found=

	[ -z "$repodir" ] && repodir=$XBPS_PACKAGESDIR
	[ ! -d $repodir ] && exit 1

	found="$(echo $repodir/$xbps_machine/*)"
	if $(echo $found|grep -vq .xbps); then
		msg_error "couldn't find binary packages on $repodir."
	fi

	pkgindexf=$(mktemp -t xbps-pkgidx.XXXXXXXXXX) || exit 1
	tmppkgdir=$(mktemp -d -t xbps-pkgdir.XXXXXXXX) || exit 1

	# Write the header.
	msg_normal "Creating package index for $repodir..."
	write_repo_pkgindex_header $pkgindexf $repodir

	#
	# Write pkg dictionaries for all packages currently available at
	# XBPS_PACKAGESDIR, both for your cpu arch and non arch dependent.
	#
	for i in $(find $repodir/$xbps_machine -type f -name \*.xbps); do
		pkgnbase="$(basename ${i})"
		pkgname=$(xbps-pkgdb getpkgname ${pkgnbase})
		propsf="./var/db/xbps/metadata/$pkgname/props.plist"
		cd $tmppkgdir && tar xfjp $i $propsf
		if [ $? -ne 0 ]; then
			msg_warn "Couldn't extract $(basename $i) metadata!"
			continue
		fi
		write_repo_pkgindex_dict $propsf $pkgindexf $(basename $i) \
			$xbps_machine
		if [ $? -ne 0 ]; then
			msg_warn "Couldn't write $i metadata to index file!"
			continue
		fi
		echo "$(basename $i) added."
		pkgsum=$(($pkgsum + 1))
	done

	for i in $(find $repodir/noarch -type f -name \*.xbps); do
		pkgnbase="$(basename ${i})"
		pkgname=$(xbps-pkgdb getpkgname ${pkgnbase})
		propsf="./var/db/xbps/metadata/$pkgname/props.plist"
		cd $tmppkgdir && tar xfjp $i $propsf
		if [ $? -ne 0 ]; then
			msg_warn "Couldn't extract $(basename $i) metadata!"
			continue
		fi
		write_repo_pkgindex_dict $propsf $pkgindexf $(basename $i) \
			noarch
		if [ $? -ne 0 ]; then
			msg_warn "Couldn't write $i metadata to index file!"
			continue
		fi
		echo "$(basename $i) added."
		pkgsum=$(($pkgsum + 1))
	done

	write_repo_pkgindex_footer $pkgindexf $pkgsum
	if [ $? -eq 0 ]; then
		$XBPS_REGPKGDB_CMD sanitize-plist $pkgindexf
		if [ $? -ne 0 ]; then
			rm -f $pkgindexf
			rm -rf $tmppkgdir
			exit 1
		fi
		msg_normal "Package index created (total pkgs: $pkgsum)."
		cp -f $pkgindexf $repodir/$xbps_machine/pkg-index.plist
	fi
	rm -f $pkgindexf
	rm -rf $tmppkgdir
}

#
# No indentation is done here, because xbps-pkgdb does it for us.
#
write_repo_pkgindex_header()
{
	local file="$1"
	local repo="$2"

	[ -z "$file" -o -z "$repo" ] && return 1

	cat > $file <<_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
<key>pkgindex-version</key>
<string>$XBPS_PKGINDEX_VERSION</string>
<key>location-local</key>
<string>$repodir</string>
<key>packages</key>
<array>
_EOF
}

write_repo_pkgindex_footer()
{
	local file="$1"
	local totalpkgs="$2"

	[ -z "$file" -o -z "$totalpkgs" ] && return 1

	cat >> $file <<_EOF
</array>
<key>total-pkgs</key>
<integer>$totalpkgs</integer>
</dict>
</plist>
_EOF
}

#
# Function that writes the package's metadata dictionary into the
# package index file for a repository.
#
write_repo_pkgindex_dict()
{
	local pkgf="$1"
	local indexf="$2"
	local binpkgf="$3"
	local arch="$4"
	local first_dict=
	local tmpdictf=
	local binpkg="$XBPS_PACKAGESDIR/$arch/$binpkgf"
	local getsize=$(du -b $binpkg|awk '{print $1}')

	[ -z "$pkgf" -o -z "$indexf" -o -z "$binpkgf" ] && return 1

	tmpdictf=$(mktemp -t xbps-pkgdict.XXXXXXXXXX) || exit 1

	cat $pkgf | while read line; do
		# Find the first dictionary.
		if $(echo $line|grep -q "<dict>"); then
			first_dict=yes
			echo "$line" >> $tmpdictf
			# Write binpkg props.
			echo "<key>filename</key>" >> $tmpdictf
			echo "<string>$binpkgf</string>" >> $tmpdictf
			echo "<key>filename-sha256</key>" >> $tmpdictf
			echo "<string>$(xbps-digest $binpkg)</string>" \
			    >> $tmpdictf
			echo "<key>filename-size</key>" >> $tmpdictf
			echo "<integer>$getsize</integer>" >> $tmpdictf
			continue
		# Continue until found.
		elif [ -z "$first_dict" ]; then
			continue
		# Is this line the end of dictionary?
		elif $(echo $line|grep -q "</dict>"); then
			# It is.
			echo "$line" >> $tmpdictf
			break
		else
			echo "$line" >> $tmpdictf
		fi
	done

	cat $tmpdictf >> $indexf
	rm -f $tmpdictf
}
