#-
# Copyright (c) 2009 Juan Romero Pardines.
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

xbps_write_metadata_scripts_pkg()
{
	local action="$1"
	local metadir="${DESTDIR}/var/db/xbps/metadata/$pkgname"
	local tmpf=$(mktemp -t xbps-install.XXXXXXXXXX) || exit 1
	local fpattern="s|${DESTDIR}||g;s|^\./$||g;/^$/d"
	local targets found info_files

	case "$action" in
		install) ;;
		remove) ;;
		*) return 1;;
	esac

	cd ${DESTDIR}
	cat >> $tmpf <<_EOF
#!/bin/sh -e
#
# Generic INSTALL/REMOVE script.
#
# \$1 = action
# \$2 = pkgname
# \$3 = version
#
# Note that paths must be relative to CWD, to avoid calling
# host commands if /bin/sh (dash) is not installed and it's
# not possible to chroot(3).
#

export PATH="./bin:./sbin:./usr/bin:./usr/sbin"

TRIGGERSDIR="./var/db/xbps/triggers"
ACTION="\$1"
PKGNAME="\$2"
VERSION="\$3"

_EOF

	#
	# Handle GNU Info files.
	#
	if [ -d "${DESTDIR}/usr/share/info" ]; then
		unset info_files
		for f in $(find ${DESTDIR}/usr/share/info -type f); do
			j=$(echo $f|sed -e "$fpattern")
                        [ "$j" = "" ] && continue
			[ "$j" = "/usr/share/info/dir" ] && continue
			if [ -z "$info_files" ]; then
				info_files="$j"
			else
				info_files="$info_files $j"
			fi
		done
		if [ -n "${info_files}" ]; then
			for f in ${triggers}; do
				[ "$f" = "info-files" ] && found=1
			done
			[ -z "$found" ] && triggers="$triggers info-files"
			unset found
			echo "export info_files=\"${info_files}\"" >> $tmpf
			echo >> $tmpf
		fi
        fi

	#
	# Handle OpenRC services.
	#
	if [ -n "${openrc_services}" ]; then
		echo "export openrc_services=\"${openrc_services}\"" >> $tmpf
		echo >> $tmpf
	fi

	#
	# (Un)Register a shell in /etc/shells.
	#
	if [ -n "${register_shell}" ]; then
		for f in ${triggers}; do
			[ "$f" = "register-shell" ] && found=1
		done
		[ -z "$found" ] && triggers="$triggers register-shell"
		unset found
		echo "export register_shell=\"${register_shell}\"" >> $tmpf
		echo >> $tmpf
	fi

	#
	# Handle SGML/XML catalog entries via xmlcatmgr.
	#
	if [ -n "${sgml_catalogs}" ]; then
		for catalog in ${sgml_catalogs}; do
			sgml_entries="${sgml_entries} CATALOG ${catalog} --"
		done
	fi
	if [ -n "${sgml_entries}" ]; then
		echo "export sgml_entries=\"${sgml_entries}\"" >> $tmpf
		echo >> $tmpf
	fi
	if [ -n "${xml_catalogs}" ]; then
		for catalog in ${xml_catalogs}; do
			xml_entries="${xml_entries} nextCatalog ${catalog} --"
		done
	fi
	if [ -n "${xml_entries}" ]; then
		echo "export xml_entries=\"${xml_entries}\"" >> $tmpf
		echo >> $tmpf
	fi

	#
	# Handle X11 font updates via mkfontdir/mkfontscale.
	#
	if [ -n "${font_dirs}" ]; then
		echo "export font_dirs=\"${font_dirs}\"" >> $tmpf
		echo >> $tmpf
	fi

	#
	# Handle GTK+ Icon cache directories.
	#
	if [ -n "${gtk_iconcache_dirs}" ]; then
		echo "export gtk_iconcache_dirs=\"${gtk_iconcache_dirs}\"" \
			>> $tmpf
		echo >> $tmpf
	fi

	if [ -n "$triggers" ]; then
		found=1
		echo "case \"\${ACTION}\" in" >> $tmpf
		echo "pre)" >> $tmpf
		for f in ${triggers}; do
			if [ ! -f $XBPS_TRIGGERSDIR/$f ]; then
				rm -f $tmpf
				msg_error "$pkgname: unknown trigger $f, aborting!"
			fi
		done
		for f in ${triggers}; do
			targets=$($XBPS_TRIGGERSDIR/$f targets)
			for j in ${targets}; do
				if ! $(echo $j|grep -q pre-${action}); then
					continue
				fi
				printf "\t\${TRIGGERSDIR}/$f run $j \${PKGNAME} \${VERSION}\n" >> $tmpf
				printf "\t[ \$? -ne 0 ] && exit \$?\n" >> $tmpf
			done
		done
		printf "\t;;\n" >> $tmpf
		echo "post)" >> $tmpf
		for f in ${triggers}; do
			targets=$($XBPS_TRIGGERSDIR/$f targets)
			for j in ${targets}; do
				if ! $(echo $j|grep -q post-${action}); then
					continue
				fi
				printf "\t\${TRIGGERSDIR}/$f run $j \${PKGNAME} \${VERSION}\n" >> $tmpf
				printf "\t[ \$? -ne 0 ] && exit \$?\n" >> $tmpf
			done
		done
		printf "\t;;\n" >> $tmpf
		echo "esac" >> $tmpf
		echo >> $tmpf
	fi

	case "$action" in
	install)
		if [ -n "${sourcepkg}" -a "${sourcepkg}" != "${pkgname}" ]; then
			install_file=${XBPS_TEMPLATESDIR}/${pkgname}/${pkgname}.INSTALL
		else
			install_file=${XBPS_TEMPLATESDIR}/${pkgname}/INSTALL
		fi
		if [ -f ${install_file} ]; then
			found=1
			cat ${install_file} >> $tmpf
		fi
		echo "exit 0" >> $tmpf
		if [ -z "$found" ]; then
			rm -f $tmpf
			return 0
		fi
		mv $tmpf ${DESTDIR}/INSTALL && chmod 755 ${DESTDIR}/INSTALL
		;;
	remove)
		if [ -n "${sourcepkg}" -a "${sourcepkg}" != "${pkgname}" ]; then
			remove_file=${XBPS_TEMPLATESDIR}/${pkgname}/${pkgname}.REMOVE
		else
			remove_file=${XBPS_TEMPLATESDIR}/${pkgname}/REMOVE
		fi
		if [ -f ${remove_file} ]; then
			found=1
			cat ${remove_file} >> $tmpf
		fi
		echo "exit 0" >> $tmpf
		if [ -z "$found" ]; then
			rm -f $tmpf
			return 0
		fi
		mv $tmpf ${metadir}/REMOVE && chmod 755 ${metadir}/REMOVE
		;;
	esac
}
