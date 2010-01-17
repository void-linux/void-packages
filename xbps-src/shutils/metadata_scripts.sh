#-
# Copyright (c) 2009-2010 Juan Romero Pardines.
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

_add_trigger()
{
	local f found name="$1"

	for f in ${triggers}; do
		[ "$f" = "$name" ] && found=1
	done
	[ -z "$found" ] && triggers="$triggers $name"
}

xbps_write_metadata_scripts_pkg()
{
	local action="$1"
	local tmpf=$(mktemp -t xbps-install.XXXXXXXXXX) || exit 1
	local fpattern="s|${DESTDIR}||g;s|^\./$||g;/^$/d"
	local targets f info_files home shell descr groups
	local found triggers_found

	case "$action" in
		install) ;;
		remove) ;;
		*) return 1;;
	esac

	cd ${DESTDIR}
	cat >> $tmpf <<_EOF
#!/bin/sh -e
#
# Generic INSTALL/REMOVE script. Arguments passed to this script:
#
# \$1 = ACTION	[pre/post]
# \$2 = PKGNAME
# \$3 = VERSION
# \$4 = UPDATE	[yes/no]
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
UPDATE="\$4"

#
# The following code will run the triggers.
#
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
			_add_trigger info-files
			echo "export info_files=\"${info_files}\"" >> $tmpf
			echo >> $tmpf
		fi
        fi

	#
	# Handle system accounts.
	#
	if [ -n "${system_accounts}" ]; then
		_add_trigger system-accounts
		echo "export system_accounts=\"${system_accounts}\"" >> $tmpf
		for f in ${system_accounts}; do
			eval homedir="\$${f}_homedir"
			eval shell="\$${f}_shell"
			eval descr="\$${f}_descr"
			eval groups="\$${f}_groups"
			if [ -n "$homedir" ]; then
				echo "export ${f}_homedir=\"$homedir\"" >> $tmpf
			fi
			if [ -n "$shell" ]; then
				echo "export ${f}_shell=\"$shell\"" >> $tmpf
			fi
			if [ -n "$descr" ]; then
				echo "export ${f}_descr=\"$descr\"" >> $tmpf
			fi
			if [ -n "$groups" ]; then
				echo "export ${f}_groups=\"${groups}\"" >> $tmpf
			fi
			unset homedir shell descr groups
		done
		echo >> $tmpf
	fi

	#
	# Handle OpenRC services.
	#
	if [ -n "${openrc_services}" ]; then
		_add_trigger openrc-service
		echo "export openrc_services=\"${openrc_services}\"" >> $tmpf
		echo >> $tmpf
	fi

	#
	# (Un)Register a shell in /etc/shells.
	#
	if [ -n "${register_shell}" ]; then
		_add_trigger register-shell
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
	if [ -n "${sgml_entries}" -o -n "${xml_entries}" ]; then
		_add_trigger xml-catalog
	fi

	#
	# Handle X11 font updates via mkfontdir/mkfontscale.
	#
	if [ -n "${font_dirs}" ]; then
		_add_trigger x11-fonts
		echo "export font_dirs=\"${font_dirs}\"" >> $tmpf
		echo >> $tmpf
	fi

	#
	# Handle GTK+ Icon cache directories.
	#
	if [ -n "${gtk_iconcache_dirs}" ]; then
		_add_trigger gtk-icon-cache
		echo "export gtk_iconcache_dirs=\"${gtk_iconcache_dirs}\"" \
			>> $tmpf
		echo >> $tmpf
	fi

        #
	# Handle .desktop files in /usr/share/applications with
	# desktop-file-utils.
	#
	if [ -d ${DESTDIR}/usr/share/applications ]; then
		if find . -type f -name \*.desktop 2>&1 >/dev/null; then
			_add_trigger update-desktopdb
		fi
	fi

	#
	# Write the INSTALL/REMOVE package scripts.
	#
	if [ -n "$triggers" ]; then
		triggers_found=1
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
				printf "\t\${TRIGGERSDIR}/$f run $j \${PKGNAME} \${VERSION} \${UPDATE}\n" >> $tmpf
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
				printf "\t\${TRIGGERSDIR}/$f run $j \${PKGNAME} \${VERSION} \${UPDATE}\n" >> $tmpf
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
			install_file=$XBPS_SRCPKGDIR/$pkgname/$pkgname.INSTALL
		else
			install_file=$XBPS_SRCPKGDIR/$pkgname/INSTALL
		fi
		if [ -f ${install_file} ]; then
			found=1
			cat ${install_file} >> $tmpf
		fi
		echo "exit 0" >> $tmpf
		if [ -z "$triggers_found" -a -z "$found" ]; then
			rm -f $tmpf
			return 0
		fi
		mv $tmpf ${DESTDIR}/INSTALL && chmod 755 ${DESTDIR}/INSTALL
		;;
	remove)
		unset found
		if [ -n "${sourcepkg}" -a "${sourcepkg}" != "${pkgname}" ]; then
			remove_file=$XBPS_SRCPKGDIR/$pkgname/$pkgname.REMOVE
		else
			remove_file=$XBPS_SRCPKGDIR/$pkgname/REMOVE
		fi
		if [ -f ${remove_file} ]; then
			found=1
			cat ${remove_file} >> $tmpf
		fi
		echo "exit 0" >> $tmpf
		if [ -z "$triggers_found" -a -z "$found" ]; then
			rm -f $tmpf
			return 0
		fi
		mv $tmpf ${DESTDIR}/REMOVE && chmod 755 ${DESTDIR}/REMOVE
		;;
	esac
}
