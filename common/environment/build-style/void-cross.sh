# Snapshot tarballs get removed after over a year, we can archive the ones we need in distfiles.
case "$XBPS_DISTFILES_FALLBACK" in
	*"repo-default.voidlinux.org/distfiles"*) ;;
	*) XBPS_DISTFILES_FALLBACK+=" https://repo-default.voidlinux.org/distfiles" ;;
esac

lib32disabled=yes
nopie=yes

nostrip_files+=" libcaf_single.a libgcc.a libgcov.a libgcc_eh.a
 libgnarl_pic.a libgnarl.a libgnat_pic.a libgnat.a libgmem.a"
