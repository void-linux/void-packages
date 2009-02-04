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

#
# Applies to the build directory the patches specified by a template.
#
apply_tmpl_patches()
{
	local patch=
	local i=

	# Apply some build/install patches automatically.
	if [ -f $XBPS_TEMPLATESDIR/$pkgname/build.diff ]; then
		patch_files="build.diff $patch_files"
	fi
	if [ -f $XBPS_TEMPLATESDIR/$pkgname/install.diff ]; then
		patch_files="install.diff $patch_files"
	fi

	[ -z "$patch_args" ] && patch_args="-p0"
	[ -z "$patch_files" ] && return 0

	#
	# If package needs some patches applied before building,
	# apply them now.
	#
	for i in ${patch_files}; do
		patch="$XBPS_TEMPLATESDIR/$pkgname/$i"
		if [ ! -f "$patch" ]; then
			msg_warn "unexistent patch: $i."
			continue
		fi

		cp -f $patch $wrksrc

		# Try to guess if its a compressed patch.
		if $(echo $patch|grep -q '.diff.gz'); then
			gunzip $wrksrc/$i
			patch=${i%%.gz}
		elif $(echo $patch|grep -q '.diff.bz2'); then
			bunzip2 $wrksrc/$i
			patch=${i%%.bz2}
		elif $(echo $patch|grep -q '.diff'); then
			patch=$i
		else
			msg_warn "unknown patch type: $i."
			continue
		fi

		cd $wrksrc && patch -s ${patch_args} < \
			$patch 2>/dev/null
		if [ "$?" -eq 0 ]; then
			msg_normal "Patch applied: $i."
		else
			msg_error "couldn't apply patch: $i."
		fi
	done

	touch -f $XBPS_APPLYPATCHES_DONE
}
