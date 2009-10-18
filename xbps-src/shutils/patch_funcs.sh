#-
# Copyright (c) 2008-2009 Juan Romero Pardines.
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
# Applies to the build directory all patches found in PATCHESDIR
# (templates/$pkgname/patches).
#
apply_tmpl_patches()
{
	local patch_files args patch i

	[ ! -d $PATCHESDIR ] && return 0

	for f in $(echo $PATCHESDIR/*); do
		if $(echo $f|grep -q '.args'); then
			continue
		fi
		patch_files="$patch_files $f"
	done

	for i in ${patch_files}; do
		args="-Np0"
		patch=$(basename $i)
		if [ -f $PATCHESDIR/$patch.args ]; then
			args=$(cat $PATCHESDIR/$patch.args)
		fi
		cp -f $i $wrksrc

		# Try to guess if its a compressed patch.
		if $(echo $i|grep -q '.diff.gz'); then
			gunzip $wrksrc/$patch
			patch=${patch%%.gz}
		elif $(echo $i|grep -q '.patch.gz'); then
			gunzip $wrksrc/$patch
			patch=${patch%%.gz}
		elif $(echo $i|grep -q '.diff.bz2'); then
			bunzip2 $wrksrc/$patch
			patch=${patch%%.bz2}
		elif $(echo $i|grep -q '.patch.bz2'); then
			bunzip2 $wrksrc/$patch
			patch=${patch%%.bz2}
		elif $(echo $i|grep -q '.diff'); then
			:
		elif $(echo $i|grep -q '.patch'); then
			:
		else
			msg_warn "unknown patch type: $i."
			continue
		fi

		cd $wrksrc && patch -s ${args} < $patch 2>/dev/null
		if [ $? -eq 0 ]; then
			msg_normal "Patch applied: $patch."
		else
			msg_error "couldn't apply patch: $patch."
		fi
	done

	touch -f $XBPS_APPLYPATCHES_DONE
}
