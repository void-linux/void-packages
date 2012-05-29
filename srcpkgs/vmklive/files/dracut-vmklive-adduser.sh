#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

USERNAME=$(getarg live.user)
[ -z "$USERNAME" ] && USERNAME=anon

# Create /etc/default/live.conf to store USER.
echo "USERNAME=$USERNAME" >> ${NEWROOT}/etc/default/live.conf
chmod 644 ${NEWROOT}/etc/default/live.conf

# Create new user and remove password. We'll use autologin by default.
chroot ${NEWROOT} useradd -c $USERNAME -m $USERNAME -G audio,video,wheel -s /bin/sh
chroot ${NEWROOT} passwd -d $USERNAME 2>&1 >/dev/null

# Enable sudo permission by default.
if [ -f ${NEWROOT}/etc/sudoers ]; then
	echo "${USERNAME}  ALL=(ALL) NOPASSWD: ALL" >> ${NEWROOT}/etc/sudoers
fi

# Enable autologin for getty(1).
if [ -f ${NEWROOT}/lib/systemd/system/getty@.service ]; then
        rm -f "${NEWROOT}/etc/systemd/system/getty.target.wants/getty@tty1.service"
	sed -e "s|/sbin/agetty|/sbin/live-getty|g" \
                "${NEWROOT}/lib/systemd/system/getty@.service" > \
                "${NEWROOT}/etc/systemd/system/getty.target.wants/getty@tty1.service"
fi

# Create /sbin/live-getty.
cat > ${NEWROOT}/sbin/live-getty <<_EOF
#!/bin/sh

if [ -x /sbin/agetty ]; then
	_getty=/sbin/agetty
elif [ -x /sbin/getty ]; then
	_getty=/sbin/getty
fi

exec \${_getty} -n -l /sbin/live-autologin \$*
_EOF
chmod 755 ${NEWROOT}/sbin/live-getty

# Create /sbin/live-autologin.
cat > ${NEWROOT}/sbin/live-autologin <<_EOF
#!/bin/sh

. /etc/default/live.conf
exec /bin/login -f \$USERNAME
_EOF
chmod 755 ${NEWROOT}/sbin/live-autologin
