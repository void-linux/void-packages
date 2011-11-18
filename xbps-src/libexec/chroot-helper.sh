#!/bin/sh
#-
# Copyright (c) 2010-2011 Juan Romero Pardines.
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

HANDLER="$1"

REQFS="sys proc dev xbps host"

mount_chroot_fs()
{
	local cnt f blah dowrite

	for f in ${REQFS}; do
		if [ ! -f ${MASTERDIR}/.${f}_mount_bind_done ]; then
			unset dowrite
			echo -n "=> Mounting /${f} in chroot... "
			if [ ! -d ${MASTERDIR}/${f} ]; then
				mkdir -p ${MASTERDIR}/${f}
			fi
			case ${f} in
				xbps)
					blah=${DISTRIBUTIONDIR}
					dowrite="-w"
					;;
				host)
					blah=${HOSTDIR}
					dowrite="-w"
					;;
				*) blah=/${f};;
			esac
			if [ -z "$HOSTDIR" -a "$f" = "host" ]; then
				echo "unset, ignoring."
				continue
			fi
			[ ! -d ${blah} ] && echo "failed." && continue
			${XBPS_LIBEXECDIR}/capmount \
				${dowrite} ${blah} ${MASTERDIR}/${f} \
				2>/dev/null
			if [ $? -eq 0 ]; then
				echo 1 > ${MASTERDIR}/.${f}_mount_bind_done
				echo "done."
			else
				echo "FAILED!"
				exit 1
			fi
		else
			cnt=$(cat ${MASTERDIR}/.${f}_mount_bind_done)
			cnt=$((${cnt} + 1))
			echo ${cnt} > ${MASTERDIR}/.${f}_mount_bind_done
		fi
	done
}

umount_chroot_fs()
{
	local fs dir cnt

	for fs in ${REQFS}; do
		[ ! -f ${MASTERDIR}/.${fs}_mount_bind_done ] && continue
		cnt=$(cat ${MASTERDIR}/.${fs}_mount_bind_done)
		if [ ${cnt} -gt 1 ]; then
			cnt=$((${cnt} - 1))
			echo ${cnt} > ${MASTERDIR}/.${fs}_mount_bind_done
		else
			echo -n "=> Unmounting ${fs} from chroot... "
			${XBPS_LIBEXECDIR}/capumount \
				${MASTERDIR} ${fs} 2>/dev/null
			if [ $? -eq 0 ]; then
				rm -f ${MASTERDIR}/.${fs}_mount_bind_done
				echo "done."
			else
				echo "FAILED!!!"
			fi
		fi
		unset fs
	done
}

if [ $# -ne 1 ]; then
	echo "$0: mount || umount"
	exit 1
fi

if [ -z "$MASTERDIR" -o -z "$DISTRIBUTIONDIR" ]; then
	echo "$0: MASTERDIR or DISTRIBUTIONDIR unset, can't continue."
	exit 1
fi

case "${HANDLER}" in
	mount) mount_chroot_fs;;
	umount) umount_chroot_fs;;
	*) echo "$0: invalid target." && exit 1;;
esac

exit 0
