if [ -e /proc/vmcore ] && ! grep -q nokdump /proc/cmdline ; then
	DIR="/var/crash/$(date +%Y%m%d-%H%M%S)"
	msg "Found kernel crash dump, saving vmcore to $DIR...\n"
	mkdir -p "$DIR"
	makedumpfile -l --message-level 1 -d 31 /proc/vmcore "$DIR"/vmcore.incomplete &&
		mv "$DIR"/vmcore.incomplete "$DIR"/vmcore
	msg "Found kernel crash dump, saving dmesg to $DIR...\n"
	vmcore-dmesg /proc/vmcore >"$DIR"/vmcore-dmesg.txt.incomplete &&
		mv "$DIR"/vmcore-dmesg.txt.incomplete "$DIR"/vmcore-dmesg.txt
	sync
	touch /run/runit/reboot
	msg "Crash dump done, triggering reboot.\n"
	exit 100  # force reboot
fi

if [ $(cat /sys/kernel/kexec_crash_size) = 0 ]; then
	msg_warn "Loading crash kernel skipped, booted without crashkernel=NNN.\n"
else
	KVER="$(uname -r)"
	if [ -f /boot/initramfs-${KVER}kdump.img ]; then
		INITRD=/boot/initramfs-${KVER}kdump.img
	else
		INITRD=/boot/initramfs-${KVER}.img
	fi

	APPEND="irqpoll nr_cpus=1 maxcpus=1 reset_devices udev.children-max=2 panic=10 cgroup_disable=memory mce=off numa=off"

	msg "Loading crash kernel..."
	kexec --load-panic /boot/vmlinuz-${KVER} \
		--initrd="$INITRD" --reuse-cmdline --append="$APPEND" &&
		msg_ok
fi
