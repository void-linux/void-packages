# This shell snippet unsets all variables/functions that can be used in
# a package template and can also be used in subpkgs.

## VARIABLES
unset -v conf_files mutable_files preserve triggers alternatives
unset -v depends run_depends replaces provides conflicts tags metapackage

# hooks/post-install/03-strip-and-debug-pkgs
unset -v nostrip nostrip_files

# hooks/post-install/14-fix-permissions
unset -v nocheckperms nofixperms

# hooks/pre-pkg/04-generate-provides
unset -v nopyprovides

# hooks/pre-pkg/04-generate-runtime-deps
unset -v noverifyrdeps skiprdeps allow_unknown_shlibs shlib_requires

# hooks/pre-pkg/06-prepare-32bit
unset -v lib32depends lib32disabled lib32files lib32mode lib32symlinks

# hooks/pre-pkg/06-shlib-provides
unset -v noshlibprovides shlib_provides

# hooks/pre-pkg/06-verify-python-deps
unset -v noverifypydeps python_extras

# xbps-triggers: system-accounts
unset -v system_accounts system_groups

# xbps-triggers: font-dirs
unset -v font_dirs

# xbps-triggers: xml-catalog
unset -v xml_entries sgml_entries xml_catalogs sgml_catalogs

# xbps-triggers: pycompile
unset -v pycompile_dirs pycompile_module

# xbps-triggers: dkms
unset -v dkms_modules

# xbps-triggers: kernel-hooks
unset -v kernel_hooks_version

# xbps-triggers: mkdirs
unset -v make_dirs

# xbps-triggers: binfmts
unset -v binfmts

# xbps-triggers: register-shell
unset -v register_shell
