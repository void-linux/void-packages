# This hook generates XBPS pkg metadata INSTALL/REMOVE scripts.

_add_trigger() {
	local f= found= name="$1"

	for f in ${triggers}; do
		[ "$f" = "$name" ] && found=1
	done
	[ -z "$found" ] && triggers="$triggers $name"
}

process_metadata_scripts() {
	local action="$1"
	local action_file="$2"
	local tmpf=$(mktemp) || exit 1
	local fpattern="s|${PKGDESTDIR}||g;s|^\./$||g;/^$/d"
	local targets= f= _f= info_files= home= shell= descr= groups=
	local found= triggers_found= _icondirs= _schemas= _mods= _tmpfiles=

	case "$action" in
		install) ;;
		remove) ;;
		*) return 1;;
	esac

	cd ${PKGDESTDIR}
	cat >> $tmpf <<_EOF
#!/bin/sh
#
# Generic INSTALL/REMOVE script. Arguments passed to this script:
#
# \$1 = ACTION	[pre/post]
# \$2 = PKGNAME
# \$3 = VERSION
# \$4 = UPDATE	[yes/no]
# \$5 = CONF_FILE (path to xbps.conf)
# \$6 = ARCH (uname -m)
#
# Note that paths must be relative to CWD, to avoid calling
# host commands if /bin/sh (dash) is not installed and it's
# not possible to chroot(2).
#

export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

TRIGGERSDIR="./usr/libexec/xbps-triggers"
ACTION="\$1"
PKGNAME="\$2"
VERSION="\$3"
UPDATE="\$4"
CONF_FILE="\$5"
ARCH="\$6"

#
# The following code will run the triggers.
#
_EOF
	#
	# Handle kernel hooks.
	#
	if [ -n "${kernel_hooks_version}" ]; then
		_add_trigger kernel-hooks
		echo "export kernel_hooks_version=\"${kernel_hooks_version}\"" >> $tmpf
	fi
	#
	# Handle DKMS modules.
	#
	if [ -n "${dkms_modules}" ]; then
		_add_trigger dkms
		echo "export dkms_modules=\"${dkms_modules}\"" >> $tmpf
	fi
	#
	# Handle system groups.
	#
	if [ -n "${system_groups}" ]; then
		_add_trigger system-accounts
		echo "export system_groups=\"${system_groups}\"" >> $tmpf
	fi
	#
	# Handle system accounts.
	#
	if [ -n "${system_accounts}" ]; then
		_add_trigger system-accounts
		echo "export system_accounts=\"${system_accounts}\"" >> $tmpf
		for f in ${system_accounts}; do
			local _uname="${f%:*}"
			local _uid="${f#*:}"

			eval homedir="\$${_uname}_homedir"
			eval shell="\$${_uname}_shell"
			eval descr="\$${_uname}_descr"
			eval groups="\$${_uname}_groups"
			eval pgroup="\$${_uname}_pgroup"
			if [ -n "$homedir" ]; then
				echo "export ${_uname}_homedir=\"$homedir\"" >> $tmpf
			fi
			if [ -n "$shell" ]; then
				echo "export ${_uname}_shell=\"$shell\"" >> $tmpf
			fi
			if [ -n "$descr" ]; then
				echo "export ${_uname}_descr=\"$descr\"" >> $tmpf
			fi
			if [ -n "$groups" ]; then
				echo "export ${_uname}_groups=\"${groups}\"" >> $tmpf
			fi
			if [ -n "$pgroup" ]; then
				echo "export ${_uname}_pgroup=\"${pgroup}\"" >> $tmpf
			fi
			unset homedir shell descr groups pgroup
		done
	fi
	#
	# Handle mkdirs trigger.
	#
	if [ -n "${make_dirs}" ]; then
		_add_trigger mkdirs
		echo "export make_dirs=\"${make_dirs}\"" >> $tmpf
	fi
	#
	# Handle binfmts trigger
	#
	if [ -n "${binfmts}" ]; then
		_add_trigger binfmts
		echo "export binfmts=\"${binfmts}\"" >> $tmpf
	fi
	#
	# Handle GNU Info files.
	#
	if [ -d "${PKGDESTDIR}/usr/share/info" ]; then
		unset info_files
		for f in $(find ${PKGDESTDIR}/usr/share/info -type f); do
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
		fi
	fi
	#
	# Handle files in hwdb directory
	#
	if [ -d "${PKGDESTDIR}/usr/lib/udev/hwdb.d" ]; then
		_add_trigger hwdb.d-dir
	fi
	#
	# Handle texmf database changes
	#
	if [ -d "${PKGDESTDIR}/usr/share/texmf-dist" ] ; then
		_add_trigger texmf-dist
	fi
	#
	# (Un)Register a shell in /etc/shells.
	#
	if [ -n "${register_shell}" ]; then
		_add_trigger register-shell
		echo "export register_shell=\"${register_shell}\"" >> $tmpf
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
	fi
	if [ -n "${xml_catalogs}" ]; then
		for catalog in ${xml_catalogs}; do
			xml_entries="${xml_entries} nextCatalog ${catalog} --"
		done
	fi
	if [ -n "${xml_entries}" ]; then
		echo "export xml_entries=\"${xml_entries}\"" >> $tmpf
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
	fi
	#
	# Handle GTK+ Icon cache directories.
	#
	if [ -d ${PKGDESTDIR}/usr/share/icons ]; then
		for f in ${PKGDESTDIR}/usr/share/icons/*; do
			[ ! -d "${f}" ] && continue
			_icondirs="${_icondirs} ${f#${PKGDESTDIR}}"
		done
		if [ -n "${_icondirs}" ]; then
			echo "export gtk_iconcache_dirs=\"${_icondirs}\"" >> $tmpf
			_add_trigger gtk-icon-cache
		fi
	fi
	#
	# Handle .desktop files in /usr/share/applications with
	# desktop-file-utils.
	#
	if [ -d ${PKGDESTDIR}/usr/share/applications ]; then
		_add_trigger update-desktopdb
	fi
	#
	# Handle GConf schemas/entries files with gconf-schemas.
	#
	if [ -d ${PKGDESTDIR}/usr/share/gconf/schemas ]; then
		_add_trigger gconf-schemas
		for f in ${PKGDESTDIR}/usr/share/gconf/schemas/*.schemas; do
			_schemas="${_schemas} ${f##*/}"
		done
		echo "export gconf_schemas=\"${_schemas}\"" >> $tmpf
	fi
	#
	# Handle gio-modules trigger.
	#
	if [ -d ${PKGDESTDIR}/usr/lib/gio/modules ]; then
		_add_trigger gio-modules
	fi
	#
	# Handle gtk immodules in /usr/lib/gtk-2.0/2.10.0/immodules with
	# gtk-immodules
	#
	if [ -d ${PKGDESTDIR}/usr/lib/gtk-2.0/2.10.0/immodules ]; then
		_add_trigger gtk-immodules
	fi
	#
	# Handle gtk3 immodules in /usr/lib/gtk-3.0/3.0.0/immodules with
	# gtk3-immodules
	#
	if [ -d ${PKGDESTDIR}/usr/lib/gtk-3.0/3.0.0/immodules ]; then
		_add_trigger gtk3-immodules
	fi
	#
	# Handle gsettings schemas in /usr/share/glib-2.0/schemas with
	# gsettings-schemas.
	#
	if [ -d ${PKGDESTDIR}/usr/share/glib-2.0/schemas ]; then
		_add_trigger gsettings-schemas
	fi
	#
	# Handle gdk-pixbuf loadable modules in /usr/lib/gdk-pixbuf-2.0/2.10.0/loaders
	# with gdk-pixbuf-loaders
	#
	if [ -d ${PKGDESTDIR}/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders ]; then
		_add_trigger gdk-pixbuf-loaders
	fi
	#
	# Handle mime database in /usr/share/mime with update-mime-database.
	#
	if [ -d ${PKGDESTDIR}/usr/share/mime ]; then
		_add_trigger mimedb
	fi
	#
	# Handle python bytecode archives with pycompile trigger.
	#
	local pycompile_version
	if [ -d ${PKGDESTDIR}/usr/lib/python* ]; then
		pycompile_version="$(find ${PKGDESTDIR}/usr/lib/python* -prune -type d | grep -o '[[:digit:]]\.[[:digit:]]\+$')"
		if [ -z "${pycompile_module}" ]; then
			pycompile_module="$(find ${PKGDESTDIR}/usr/lib/python*/site-packages -mindepth 1 -maxdepth 1 '!' -name '*.egg-info' '!' -name '*.dist-info' '!' -name '*.so' '!' -name '*.pth' -printf '%f ')"
		fi
	fi

	if [ -n "$python_version" ] && [ "$python_version" != ignore ]; then
		pycompile_version=${python_version}
	fi

	if [ "$pycompile_version" = 3 ]; then
		pycompile_version=${py3_ver}
	elif [ "$pycompile_version" = 2 ]; then
		pycompile_version=${py2_ver}
	fi

	if [ -n "${pycompile_dirs}" -o -n "${pycompile_module}" ]; then
		[ -n "$pycompile_version" ] || msg_error "$pkgver: byte-compilation is required, but python_version is not set\n"
		echo "export pycompile_version=\"${pycompile_version}\"" >>$tmpf
		if [ -n "${pycompile_dirs}" ]; then
			echo "export pycompile_dirs=\"${pycompile_dirs}\"" >>$tmpf
		fi
		if [ -n "${pycompile_module}" ]; then
			echo "export pycompile_module=\"${pycompile_module}\"" >>$tmpf
		fi
		_add_trigger pycompile
	fi
	#
	# Handle appdata metadata with AppStream
	#
	for f in ${PKGDESTDIR}/usr/share/appdata/*.xml ${PKGDESTDIR}/usr/share/app-info/*.xml ${PKGDESTDIR}/var/lib/app-info/*.xml ${PKGDESTDIR}/var/cache/app-info/*.xml; do
		if [ -f "${f}" ]; then
			_add_trigger appstream-cache
			break
		fi
	done

	# End of trigger var exports.
	echo >> $tmpf

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
				msg_error "$pkgname: unknown trigger $f, aborting!\n"
			fi
			echo "   Added trigger '$f' for the '${action^^}' script."
		done
		for f in ${triggers}; do
			targets=$($XBPS_TRIGGERSDIR/$f targets)
			for j in ${targets}; do
				if ! [[ $j =~ pre-${action} ]]; then
					continue
				fi
				printf "\t\${TRIGGERSDIR}/$f run $j \${PKGNAME} \${VERSION} \${UPDATE} \${CONF_FILE}\n" >> $tmpf
				printf "\t[ \$? -ne 0 ] && exit \$?\n" >> $tmpf
			done
		done
		printf "\t;;\n" >> $tmpf
		echo "post)" >> $tmpf
		for f in ${triggers}; do
			targets=$($XBPS_TRIGGERSDIR/$f targets)
			for j in ${targets}; do
				if ! [[ $j =~ post-${action} ]]; then
					continue
				fi
				printf "\t\${TRIGGERSDIR}/$f run $j \${PKGNAME} \${VERSION} \${UPDATE} \${CONF_FILE}\n" >> $tmpf
				printf "\t[ \$? -ne 0 ] && exit \$?\n" >> $tmpf
			done
		done
		printf "\t;;\n" >> $tmpf
		echo "esac" >> $tmpf
		echo >> $tmpf
	fi

	if [ -z "$triggers" -a ! -f "$action_file" ]; then
		rm -f $tmpf
		return 0
	fi

	case "$action" in
	install)
		if [ -f ${action_file} ]; then
			found=1
			cat ${action_file} >> $tmpf
		fi
		echo >> $tmpf
		echo "exit 0" >> $tmpf
		mv $tmpf ${PKGDESTDIR}/INSTALL && chmod 755 ${PKGDESTDIR}/INSTALL
		;;
	remove)
		unset found
		if [ -f ${action_file} ]; then
			found=1
			cat ${action_file} >> $tmpf
		fi
		echo >> $tmpf
		echo "exit 0" >> $tmpf
		mv $tmpf ${PKGDESTDIR}/REMOVE && chmod 755 ${PKGDESTDIR}/REMOVE
		;;
	esac
}

hook() {
	local meta_install meta_remove

	if [ -n "${sourcepkg}" -a "${sourcepkg}" != "${pkgname}" ]; then
		# subpkg
		meta_install=${XBPS_SRCPKGDIR}/${pkgname}/${pkgname}.INSTALL
		msg_install=${XBPS_SRCPKGDIR}/${pkgname}/${pkgname}.INSTALL.msg
		meta_remove=${XBPS_SRCPKGDIR}/${pkgname}/${pkgname}.REMOVE
		msg_remove=${XBPS_SRCPKGDIR}/${pkgname}/${pkgname}.REMOVE.msg
	else
		# sourcepkg
		meta_install=${XBPS_SRCPKGDIR}/${pkgname}/INSTALL
		msg_install=${XBPS_SRCPKGDIR}/${pkgname}/INSTALL.msg
		meta_remove=${XBPS_SRCPKGDIR}/${pkgname}/REMOVE
		msg_remove=${XBPS_SRCPKGDIR}/${pkgname}/REMOVE.msg
	fi
	process_metadata_scripts install ${meta_install} || \
		msg_error "$pkgver: failed to write INSTALL metadata file!\n"

	process_metadata_scripts remove ${meta_remove} || \
		msg_error "$pkgver: failed to write REMOVE metadata file!\n"

	if [ -s ${msg_install} ]; then
		install -m644 ${msg_install} ${PKGDESTDIR}/INSTALL.msg
	fi
	if [ -s ${msg_remove} ]; then
		install -m644 ${msg_remove} ${PKGDESTDIR}/REMOVE.msg
	fi
}
