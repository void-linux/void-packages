# This shell snippet unsets all variables/functions that can be used in
# a package template and can also be used in subpkgs.

## VARIABLES
unset -v noarch conf_files mutable_files preserve triggers
unset -v depends run_depends replaces provides conflicts tags

# hooks/post-install/03-strip-and-debug-pkgs
unset -v nostrip nostrip_files shlib_requires

# hooks/post-install/04-generate-runtime-deps
unset -v noverifyrdeps allow_unknown_shlibs shlib_provides

# hooks/post-install/06-prepare-32bit
unset -v lib32depends lib32disabled lib32files lib32mode lib32symlinks

# xbps-triggers: system-accounts
unset -v system_accounts system_groups

# xbps-triggers: font-dirs
unset -v font_dirs

# xbps-triggers: xml-catalog
unset -v xml_entries sgml_entries xml_catalogs sgml_catalogs

# xbps-triggers: pycompile
unset -v pycompile_version pycompile_dirs pycompile_module

# xbps-triggers: dkms
unset -v dkms_modules

# xbps-triggers: kernel-hooks
unset -v kernel_hooks_version

# xbps-triggers: systemd-service
unset -v systemd_services

# xbps-triggers: mkdirs
unset -v make_dirs
