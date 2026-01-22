#!/bin/sh

. /etc/default/growpart

if [ -n "$ENABLE_ROOT_GROWPART" ]; then
	msg "Growing root partition"

	rpart="$(findmnt -r -o SOURCE -v -n /)"
	rnum="$(cat /sys/class/block/"${rpart##*/}"/partition)"
	rdisk="${rpart%%"$rnum"}"
	rdisk="${rdisk%p}"
	rtype="$(blkid -o value -s TYPE "${rpart}")"

	/usr/bin/growpart "$rdisk" "$rnum"

	case "$rtype" in
		ext*) resize2fs "$rpart" ;;
		f2fs) resize.f2fs "$rpart" ;;
		xfs) xfs_growfs -d "$rpart" ;;
		*) msg_warn "Couldn't resize partition, partition type $rtype not supported" ;;
	esac
fi
