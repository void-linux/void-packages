Some optional packages must be installed for additional functionality:

 - mtools: mkdiskimage and syslinux support
 - gptfdisk: GPT support
 - efibootmgr: EFI support
 - dosfstools: EFI support

Kernel.d scripts update the current and fallback kernel using these keywords:

 - LABEL void
 - LABEL voidfallback
 - LINUX (or KERNEL)
 - INITRD (or initrd)

Avoid using these keywords for the MENU LABEL entry.

For more information on how to setup syslinux.cfg, see:

https://www.syslinux.org/wiki/?title=SYSLINUX#How_do_I_Configure_SYSLINUX.3F
