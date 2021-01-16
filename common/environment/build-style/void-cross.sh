lib32disabled=yes
nopie=yes
create_wrksrc=yes

nostrip_files+=" libcaf_single.a libgcc.a libgcov.a libgcc_eh.a
 libgnarl_pic.a libgnarl.a libgnat_pic.a libgnat.a libgmem.a"

# glibc crosstoolchains not available on musl hosts yet
if [ -z "$archs" -a "${cross_triplet/-musl}" = "${cross_triplet}" ]; then
	if [ "$XBPS_TARGET_LIBC" != "glibc" ]; then
		archs="~*-musl"
	fi
fi
