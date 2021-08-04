do_configure() {
	local target defconfig

	# Use upstream's default configuration, no need to maintain ours.
	target=$kernel_target

	defconfig="arch/${_arch}/configs/${target}"
	echo "CONFIG_CONNECTOR=y" >> "$defconfig"
	echo "CONFIG_PROC_EVENTS=y" >> "$defconfig"
	echo "CONFIG_F2FS_FS_SECURITY=y" >> "$defconfig"
	echo "CONFIG_CGROUP_PIDS=y" >> "$defconfig"

	# IR Remote Support
	echo "CONFIG_RC_CORE=y" >> "$defconfig"
	echo "CONFIG_LIRC=y" >> "$defconfig"
	echo "CONFIG_RC_DECODERS=y" >> "$defconfig"
	echo "CONFIG_RC_DEVICES=y" >> "$defconfig"
	echo "CONFIG_IR_RC6_DECODER=m" >> "$defconfig"
	echo "CONFIG_IR_MCEUSB=m" >> "$defconfig"

	# HID Controllers
	echo "CONFIG_HID_STEAM=y" >> "$defconfig"

	# LXD 4.2+ support
	echo "CONFIG_BRIDGE_VLAN_FILTERING=y" >> "$defconfig"

	make ${makejobs} ${_cross} ARCH=${_arch} ${target}

	# Always use our revision to CONFIG_LOCALVERSION to match our pkg version.
	vsed -i -e "s|^\(CONFIG_LOCALVERSION=\).*|\1\"_${revision}\"|" .config
}
do_build() {
	local target

	case "$XBPS_TARGET_MACHINE" in
		arm*)
			target="zImage modules dtbs"
			;;
		aarch64*)
			target="Image modules dtbs"
			;;
	esac

	make ${makejobs} ${_cross} ARCH=${_arch} prepare
	make ${makejobs} ${_cross} ARCH=${_arch} ${target}
}
do_install() {
	local hdrdest

	# Run depmod after compressing modules.
	sed -i '2iexit 0' scripts/depmod.sh

	# Install kernel, firmware and modules
	make ${makejobs} ARCH=${_arch} INSTALL_MOD_PATH=${DESTDIR} modules_install

	# Install device tree blobs
	make ${makejobs} ARCH=${_arch} INSTALL_DTBS_PATH=${DESTDIR}/boot dtbs_install

	# Generate kernel.img and install it to destdir.
	vmkdir boot
	cp arch/arm/boot/zImage ${DESTDIR}/boot/kernel.img

	hdrdest=${DESTDIR}/usr/src/${sourcepkg}-headers-${_kernver}

	# Switch to /usr.
	vmkdir usr
	mv ${DESTDIR}/lib ${DESTDIR}/usr

	cd ${DESTDIR}/usr/lib/modules/${_kernver}
	rm -f source build
	ln -sf ../../../src/${sourcepkg}-headers-${_kernver} build

	cd ${wrksrc}
	# Install required headers to build external modules
	install -Dm644 Makefile ${hdrdest}/Makefile
	install -Dm644 kernel/Makefile ${hdrdest}/kernel/Makefile
	install -Dm644 .config ${hdrdest}/.config
	for file in $(find . -name Kconfig\*); do
		mkdir -p ${hdrdest}/$(dirname $file)
		install -Dm644 $file ${hdrdest}/${file}
	done
	for file in $(find arch/${_arch} scripts -name module.lds -o -name Kbuild.platforms -o -name Platform); do
		mkdir -p ${hdrdest}/$(dirname $file)
		install -Dm644 $file ${hdrdest}/${file}
	done
	mkdir -p ${hdrdest}/include

	# Remove firmware stuff provided by the "linux-firmware" pkg.
	rm -rf ${DESTDIR}/usr/lib/firmware

	for i in acpi asm-generic clocksource config crypto drm generated linux \
		math-emu media net pcmcia scsi sound trace uapi vdso video xen; do
		[ -d include/$i ] && cp -a include/$i ${hdrdest}/include
	done

	cd ${wrksrc}
	# Remove helper binaries built for host,
	# if generated files from the scripts/ directory need to be included,
	# they need to be copied to ${hdrdest} before this step
	if [ "$CROSS_BUILD" ]; then
		make ${makejobs} ARCH=${_arch} _mrproper_scripts
		# remove host specific objects as well
		find scripts -name '*.o' -delete
	fi

	# Copy files necessary for later builds.
	cp Module.symvers ${hdrdest}
	cp -a scripts ${hdrdest}
	mkdir -p ${hdrdest}/security/selinux
	cp -a security/selinux/include ${hdrdest}/security/selinux
	mkdir -p ${hdrdest}/tools/include
	cp -a tools/include/tools ${hdrdest}/tools/include
	if [ -d "arch/${_arch}/tools" ]; then
		cp -a arch/${_arch}/tools ${hdrdest}/arch/${_arch}
	fi

	# copy arch includes for external modules
	mkdir -p ${hdrdest}/arch/${_arch}
	cp -a arch/${_arch}/include ${hdrdest}/arch/${_arch}

	mkdir -p ${hdrdest}/arch/${_arch}/kernel
	cp arch/${_arch}/Makefile ${hdrdest}/arch/${_arch}
	cp arch/${_arch}/kernel/asm-offsets.s ${hdrdest}/arch/${_arch}/kernel
	if [ "$_arch" = "arm64" ] ; then
		cp -a arch/${_arch}/kernel/vdso ${hdrdest}/arch/${_arch}/kernel/
	fi

	# Add md headers
	mkdir -p ${hdrdest}/drivers/md
	cp drivers/md/*.h ${hdrdest}/drivers/md

	# Add inotify.h
	mkdir -p ${hdrdest}/include/linux
	cp include/linux/inotify.h ${hdrdest}/include/linux

	# Add wireless headers
	mkdir -p ${hdrdest}/net/mac80211/
	cp net/mac80211/*.h ${hdrdest}/net/mac80211

	# add dvb headers for external modules
	mkdir -p ${hdrdest}/include/config/dvb/
	cp include/config/dvb/*.h ${hdrdest}/include/config/dvb/

	# Remove unneeded architectures
	# (save the correct one + Kconfig and delete all others)
	mkdir -p arch-backup
	cp -r ${hdrdest}/arch/${_arch} ${hdrdest}/arch/Kconfig arch-backup/
	rm -rf ${hdrdest}/arch
	mv arch-backup ${hdrdest}/arch
	# Keep arch/x86/ras/Kconfig as it is needed by drivers/ras/Kconfig
	mkdir -p ${hdrdest}/arch/x86/ras
	cp -a arch/x86/ras/Kconfig ${hdrdest}/arch/x86/ras/Kconfig

	# Compress all modules with xz to save a few MBs.
	msg_normal "$pkgver: compressing kernel modules with gzip, please wait...\n"
	find ${DESTDIR} -name '*.ko' | xargs -n1 -P0 gzip -9

	# ... and run depmod again.
	depmod -b ${DESTDIR}/usr -F System.map ${_kernver}
}
