# The XBPS source packages manual

This article contains an exhaustive manual of how to create new source
packages for XBPS, the `Void Linux` native packaging system.

*Table of Contents*

* [Introduction](#Introduction)
	* [Package build phases](#buildphase)
	* [Package naming conventions](#namingconventions)
		* [Libraries](#libs)
		* [Language Modules](#language_modules)
		* [Language Bindings](#language_bindings)
		* [Programs](#programs)
	* [Global functions](#global_funcs)
	* [Global variables](#global_vars)
	* [Available variables](#available_vars)
		* [Mandatory variables](#mandatory_vars)
		* [Optional variables](#optional_vars)
		* [About the depends variables](#explain_depends)
	* [Repositories](#repositories)
		* [Repositories defined by Branch](#repo_by_branch)
		* [Package defined repositories](#pkg_defined_repo)
	* [Checking for new upstream releases](#updates)
	* [Handling patches](#patches)
	* [Build style scripts](#build_scripts)
	* [Build helper scripts](#build_helper)
	* [Functions](#functions)
	* [Build options](#build_options)
		* [Runtime dependencies](#deps_runtime)
	* [INSTALL and REMOVE files](#install_remove_files)
	* [INSTALL.msg and REMOVE.msg files](#install_remove_files_msg)
	* [Creating system accounts/groups at runtime](#runtime_account_creation)
	* [Writing runit services](#writing_runit_services)
	* [32bit packages](#32bit_pkgs)
	* [Subpackages](#pkgs_sub)
	* [Development packages](#pkgs_development)
	* [Data packages](#pkgs_data)
	* [Documentation packages](#pkgs_documentation)
	* [Python packages](#pkgs_python)
	* [Go packages](#pkgs_go)
	* [Haskell packages](#pkgs_haskell)
	* [Font packages](#pkgs_font)
	* [Renaming a package](#pkg_rename)
	* [Removing a package](#pkg_remove)
	* [XBPS Triggers](#xbps_triggers)
		* [appstream-cache](#triggers_appstream_cache)
		* [binfmts](#triggers_binfmts)
		* [dkms](#triggers_dkms)
		* [gconf-schemas](#triggers_gconf_schemas)
		* [gdk-pixbuf-loaders](#triggers_gdk_pixbuf_loaders)
		* [gio-modules](#triggers_gio_modules)
		* [gettings-schemas](#triggers_gsettings_schemas)
		* [gtk-icon-cache](#triggers_gtk_icon_cache)
		* [gtk-immodules](#triggers_gtk_immodules)
		* [gtk-pixbuf-loaders](#triggers_gtk_pixbuf_loaders)
		* [gtk3-immodules](#triggers_gtk3_immodules)
		* [hwdb.d-dir](#triggers_hwdb.d_dir)
		* [info-files](#triggers_info_files)
		* [initramfs-regenerate](#triggers_initramfs_regenerate)
		* [kernel-hooks](#triggers_kernel_hooks)
		* [mimedb](#triggers_mimedb)
		* [mkdirs](#triggers_mkdirs)
		* [openjdk-profile](#triggers_openjdk_profile)
		* [pango-modules](#triggers_pango_module)
		* [pycompile](#triggers_pycompile)
		* [register-shell](#triggers_register_shell)
		* [system-accounts](#triggers_system_accounts)
		* [texmf-dist](#triggers_texmf_dist)
		* [update-desktopdb](#triggers_update_desktopdb)
		* [x11-fonts](#triggers_x11_fonts)
		* [xml-catalog](#triggers_xml_catalog)
	* [Void specific documentation](#documentation)
	* [Notes](#notes)
	* [Contributing via git](#contributing)
* [Help](#help)

<a id="Introduction"></a>
## Introduction

The `void-packages` repository contains all the
recipes to download, compile and build binary packages for Void Linux.
These `source` package files are called `templates`.

The `template` files are shell scripts that define `variables` and `functions`
to be processed by `xbps-src`, the package builder, to generate binary packages.
The shell used by `xbps-src` is GNU bash; `xbps-src` doesn't aim to be
compatible with POSIX `sh`.

By convention, all templates start with a comment saying that it is a
`template file` for a certain package. Most of the lines should be kept under 80
columns; variables that list many values can be split into new lines, with the
continuation in the next line indented by one space.

A simple `template` example is as follows:

```
# Template file for 'foo'
pkgname=foo
version=1.0
revision=1
build_style=gnu-configure
short_desc="A short description max 72 chars"
maintainer="name <email>"
license="GPL-3.0-or-later"
homepage="http://www.foo.org"
distfiles="http://www.foo.org/foo-${version}.tar.gz"
checksum="fea0a94d4b605894f3e2d5572e3f96e4413bcad3a085aae7367c2cf07908b2ff"
```

The template file contains definitions to download, build and install the
package files to a `fake destdir`, and after this a binary package can be
generated with the definitions specified on it.

Don't worry if anything is not clear as it should be. The reserved `variables`
and `functions` will be explained later. This `template` file should be created
in a directory matching `$pkgname`, Example: `void-packages/srcpkgs/foo/template`.

If everything went fine after running

    $ ./xbps-src pkg <pkgname>

a binary package named `foo-1.0_1.<arch>.xbps` will be generated in the local repository
`hostdir/binpkgs`.

<a id="buildphase"></a>
### Package build phases

Building a package consist of the following phases:

- `setup` This phase prepares the environment for building a package.

- `fetch` This phase downloads required sources for a `source package`, as defined by
the `distfiles` variable or `do_fetch()` function.

- `extract` This phase extracts the `distfiles` files into `$wrksrc` or executes the `do_extract()`
function, which is the directory to be used to compile the `source package`.

- `patch` This phase applies all patches in the patches directory of the package and
can be used to perform other operations before configuring the package.

- `configure` This phase executes the `configuration` of a `source package`, i.e `GNU configure scripts`.

- `build` This phase compiles/prepares the `source files` via `make` or any other compatible method.

- `check` This optional phase checks the result of the `build` phase by running the testsuite provided by the package.
If the default `do_check` function provided by the build style doesn't do anything, the template should set
`make_check_target` and/or `make_check_args` appropriately or define its own `do_check` function. If tests take too long
or can't run in all environments, `make_check` should be set to fitting value or
`do_check` should be customized to limit testsuite unless `XBPS_CHECK_PKGS` is `full`.

- `install` This phase installs the `package files` into the package destdir `<masterdir>/destdir/<pkgname>-<version>`,
via `make install` or any other compatible method.

- `pkg` This phase builds the `binary packages` with files stored in the
`package destdir` and registers them into the local repository.

- `clean` This phase cleans up the package (if defined).

`xbps-src` supports running just the specified phase, and if it ran
successfully, the phase will be skipped later (unless its work directory
`${wrksrc}` is removed with `xbps-src clean`).

<a id="namingconventions"></a>
### Package naming conventions

<a id="libs"></a>
#### Libraries

Libraries are packages which provide shared objects (\*.so) in /usr/lib.
They should be named like their upstream package name with the following
exceptions:

- The package is a subpackage of a front end application and provides
shared objects used by the base package and other third party libraries. In that
case it should be prefixed with 'lib'. An exception from that rule is: If an
executable is only used for building that package, it moves to the -devel
package.

Example: wireshark -> subpkg libwireshark

Libraries have to be split into two sub packages: `<name>` and `<name>-devel`.

- `<name>` should only contain those parts of a package which are needed to run
a linked program.

- `<name>-devel` should contain all files which are needed to compile a package
against this package. If the library is a sub package, its corresponding
development package should be named `lib<name>-devel`

<a id="language_modules"></a>
#### Language Modules

Language modules are extensions to script or compiled languages. Those packages
do not provide any executables themselves, but can be used by other packages
written in the same language.

The naming convention to those packages is:

```
<language>-<name>
```

If a package provides both, a module and a executable, it should be split into
a package providing the executable named `<name>` and the module named
`<language>-<name>`. If a package starts with the languages name itself, the
language prefix can be dropped. Short names for languages are no valid substitute
for the language prefix.

Example: python-pam, perl-URI, python3-pyside2

<a id="language_bindings"></a>
#### Language Bindings

Language Bindings are packages which allow programs or libraries to have
extensions or plugins written in a certain language.

The naming convention to those packages is:
```
<name>-<language>
```

Example: gimp-python, irssi-perl

<a id="programs"></a>
#### Programs

Programs put executables under /usr/bin (or in very special cases in other
.../bin directories)

For those packages the upstream packages name should be used. Remember that
in contrast to many other distributions, void doesn't lowercase package names.
As a rule of thumb, if the tar.gz of a package contains uppercase letter, then
the package name should contain them too; if it doesn't, the package name
is lowercase.

Programs can be split into program packages and library packages. The program
package should be named as described above. The library package should be
prefixed with "lib" (see section `Libraries`)

<a id="global_funcs"></a>
### Global functions

The following functions are defined by `xbps-src` and can be used on any template:

- *vinstall()* `vinstall <file> <mode> <targetdir> [<name>]`

	Installs `file` with the specified `mode` into `targetdir` in the pkg `$DESTDIR`.
	The optional 4th argument can be used to change the `file name`.

- *vcopy()* `vcopy <pattern> <targetdir>`

	Copies recursively all files in `pattern` to `targetdir` in the pkg `$DESTDIR`.

- *vmove()* `vmove <pattern>`

	Moves `pattern` to the specified directory in the pkg `$DESTDIR`.

- *vmkdir()* `vmkdir <directory> [<mode>]`

	Creates a directory in the pkg `$DESTDIR`. The 2nd optional argument sets the mode of the directory.

- *vbin()* `vbin <file> [<name>]`

	Installs `file` into `usr/bin` in the pkg `$DESTDIR` with the
	permissions 0755. The optional 2nd argument can be used to change
	the `file name`.

- *vman()* `vman <file> [<name>]`

	Installs `file` as a man page. `vman()` parses the name and
	determines the section as well as localization. Also transparently
	converts gzipped (.gz) and bzipped (.bz2) manpages into plaintext.
	Example mappings:

	- `foo.1` -> `${DESTDIR}/usr/share/man/man1/foo.1`
	- `foo.fr.1` -> `${DESTDIR}/usr/share/man/fr/man1/foo.1`
	- `foo.1p` -> `${DESTDIR}/usr/share/man/man1/foo.1p`
	- `foo.1.gz` -> `${DESTDIR}/usr/share/man/man1/foo.1`
	- `foo.1.bz2` -> `${DESTDIR}/usr/share/man/man1/foo.1`

- *vdoc()* `vdoc <file> [<name>]`

	Installs `file` into `usr/share/doc/<pkgname>` in the pkg
	`$DESTDIR`. The optional 2nd argument can be used to change the
	`file name`.

- *vconf()* `vconf <file> [<name>]`

	Installs `file` into `etc` in the pkg
	`$DESTDIR`. The optional 2nd argument can be used to change the
	`file name`.

- *vsconf()* `vsconf <file> [<name>]`

	Installs `file` into `usr/share/examples/<pkgname>` in the pkg
	`$DESTDIR`. The optional 2nd argument can be used to change the
	`file name`.

- <a id="vlicense"></a>
 *vlicense()* `vlicense <file> [<name>]`

	Installs `file` into `usr/share/licenses/<pkgname>` in the pkg
	`$DESTDIR`. The optional 2nd argument can be used to change the
	`file name`. See [license](#var_license) for when to use it.

- *vsv()* `vsv <service>`

	Installs `service` from `${FILESDIR}` to /etc/sv. The service must
	be a directory containing at least a run script. Note the `supervise`
	symlink will be created automatically by `vsv` and that the run script
	is automatically made executable by this function.
	For further information on how to create a new service directory see
	[The corresponding section the FAQ](http://smarden.org/runit/faq.html#create).

- *vsed()* `vsed -i <file> -e <regex>`

	Wrapper around sed that checks sha256sum of a file before and after running
	the sed command to detect cases in which the sed call didn't change anything.
	Takes any arbitrary amount of files and regexes by calling `-i file` and
	`-e regex` repeatedly, at least one file and one regex must be specified.

	Note that vsed will call the sed command for every regex specified against
	every file specified, in the order that they are given.

- *vcompletion()* `<file> <shell> [<command>]`

	Installs shell completion from `file` for `command`, in the correct location
	and with the appropriate filename for `shell`. If `command` isn't specified,
	it will default to `pkgname`. The `shell` argument can be one of `bash`,
	`fish` or `zsh`.

> Shell wildcards must be properly quoted, Example: `vmove "usr/lib/*.a"`.

<a id="global_vars"></a>
### Global variables

The following variables are defined by `xbps-src` and can be used on any template:

- `makejobs` Set to `-jX` if `XBPS_MAKEJOBS` is defined, to allow parallel jobs with `GNU make`.

- `sourcepkg`  Set to the to main package name, can be used to match the main package
rather than additional binary package names.

- `CHROOT_READY`  Set if the target chroot (masterdir) is ready for chroot builds.

- `CROSS_BUILD` Set if `xbps-src` is cross compiling a package.

- `XBPS_CHECK_PKGS` Set if `xbps-src` is going to run tests for a package.
Longer testsuites should only be run in `do_check()` if it is set to `full`.

- `DESTDIR` Full path to the fake destdir used by the source pkg, set to
`<masterdir>/destdir/${sourcepkg}-${version}`.

- `FILESDIR` Full path to the `files` package directory, i.e `srcpkgs/foo/files`.
The `files` directory can be used to store additional files to be installed
as part of the source package.

- `PKGDESTDIR` Full path to the fake destdir used by the `pkg_install()` function in
`subpackages`, set to `<masterdir>/destdir/${pkgname}-${version}`.

- `XBPS_BUILDDIR` Directory to store the `source code` of the source package being processed,
set to `<masterdir>/builddir`. The package `wrksrc` is always stored
in this directory such as `${XBPS_BUILDDIR}/${wrksrc}`.

- `XBPS_MACHINE` The machine architecture as returned by `xbps-uhelper arch`.

- `XBPS_ENDIAN` The machine's endianness ("le" or "be").

- `XBPS_LIBC` The machine's C library ("glibc" or "musl").

- `XBPS_WORDSIZE` The machine's word size in bits (32 or 64).

- `XBPS_NO_ATOMIC8` The machine lacks native 64-bit atomics (needs libatomic emulation).

- `XBPS_SRCDISTDIR` Full path to where the `source distfiles` are stored, i.e `$XBPS_HOSTDIR/sources`.

- `XBPS_SRCPKGDIR` Full path to the `srcpkgs` directory.

- `XBPS_TARGET_MACHINE` The target machine architecture when cross compiling a package.

- `XBPS_TARGET_ENDIAN` The target machine's endianness ("le" or "be").

- `XBPS_TARGET_LIBC` The target machine's C library ("glibc" or "musl").

- `XBPS_TARGET_WORDSIZE` The target machine's word size in bits (32 or 64).

- `XBPS_TARGET_NO_ATOMIC8` The target machine lacks native 64-bit atomics (needs libatomic emulation).

- `XBPS_FETCH_CMD` The utility to fetch files from `ftp`, `http` of `https` servers.

- `XBPS_WRAPPERDIR` Full path to where xbps-src's wrappers for utilities are stored.

- `XBPS_CROSS_BASE` Full path to where cross-compile dependencies are installed, varies according to the target architecture triplet. i.e `aarch64` -> `/usr/aarch64-linux-gnu`.

- `XBPS_RUST_TARGET` The target architecture triplet used by `rustc` and `cargo`.

- `XBPS_BUILD_ENVIRONMENT` Enables continuous-integration-specific operations. Set to `void-packages-ci` if in continuous integration.

<a id="available_vars"></a>
### Available variables

<a id="mandatory_vars"></a>
#### Mandatory variables

The list of mandatory variables for a template:

- `homepage` An URL pointing to the upstream homepage.


- <a id="var_license"></a>
`license` A string matching the license's [SPDX Short identifier](https://spdx.org/licenses),
`Public Domain`, or string prefixed with `custom:` for other licenses.
Multiple licenses should be separated by commas, Example: `GPL-3.0-or-later, custom:Hugware`.

  Empty meta-packages that don't include any files
  and thus have and require no license should use
  `Public Domain`.

  Note: `MIT`, `BSD`, `ISC` and custom licenses
  require the license file to be supplied with the binary package.

- `maintainer` A string in the form of `name <user@domain>`.  The email for this field
must be a valid email that you can be reached at. Packages using
`users.noreply.github.com` emails will not be accepted.

- `pkgname` A string with the package name, matching `srcpkgs/<pkgname>`.

- `revision` A number that must be set to 1 when the `source package` is created, or
updated to a new `upstream version`. This should only be increased when
the generated `binary packages` have been modified.

- `short_desc` A string with a brief description for this package. Max 72 chars.

- `version` A string with the package version. Must not contain dashes or underscore
and at least one digit is required. Shell's variable substitution usage is not allowed.

Neither `pkgname` or `version` should contain special characters which make it
necessary to quote them, so they shouldn't be quoted in the template.

<a id="optional_vars"></a>
#### Optional variables

- `hostmakedepends` The list of `host` dependencies required to build the package, and
that will be installed to the master directory. There is no need to specify a version
because the current version in srcpkgs will always be required.
Example: `hostmakedepends="foo blah"`.

- `makedepends` The list of `target` dependencies required to build the package, and that
will be installed to the master directory. There is no need to specify a version
because the current version in srcpkgs will always be required.
Example: `makedepends="foo blah"`.

- `checkdepends` The list of dependencies required to run the package checks, i.e.
the script or make rule specified in the template's `do_check()` function.
Example: `checkdepends="gtest"`.

- `depends` The list of dependencies required to run the package. These dependencies
are not installed to the master directory, rather are only checked if a binary package
in the local repository exists to satisfy the required version. Dependencies
can be specified with the following version comparators: `<`, `>`, `<=`, `>=`
or `foo-1.0_1` to match an exact version. If version comparator is not
defined (just a package name), the version comparator is automatically set to `>=0`.
Example: `depends="foo blah>=1.0"`. See the [Runtime dependencies](#deps_runtime) section
for more information.

- `bootstrap` If enabled the source package is considered to be part of the `bootstrap`
process and required to be able to build packages in the chroot. Only a
small number of packages must set this property.

- `conflicts` An optional list of packages conflicting with this package.
Conflicts can be specified with the following version comparators: `<`, `>`, `<=`, `>=`
or `foo-1.0_1` to match an exact version. If version comparator is not
defined (just a package name), the version comparator is automatically set to `>=0`.
Example: `conflicts="foo blah>=0.42.3"`.

- `distfiles` The full URL to the `upstream` source distribution files. Multiple files
can be separated by whitespaces. The files must end in `.tar.lzma`, `.tar.xz`,
`.txz`, `.tar.bz2`, `.tbz`, `.tar.gz`, `.tgz`, `.gz`, `.bz2`, `.tar` or
`.zip`. To define a target filename, append `>filename` to the URL.
Example:
	distfiles="http://foo.org/foo-1.0.tar.gz http://foo.org/bar-1.0.tar.gz>bar.tar.gz"

  To avoid repetition, several variables for common hosting sites
  exist:

  | Variable         | Value                                           |
  |------------------|-------------------------------------------------|
  | CPAN_SITE        | https://cpan.perl.org/modules/by-module          |
  | DEBIAN_SITE      | http://ftp.debian.org/debian/pool               |
  | FREEDESKTOP_SITE | https://freedesktop.org/software                 |
  | GNOME_SITE       | https://ftp.gnome.org/pub/GNOME/sources          |
  | GNU_SITE         | https://ftp.gnu.org/gnu                          |
  | KERNEL_SITE      | https://www.kernel.org/pub/linux                 |
  | MOZILLA_SITE     | https://ftp.mozilla.org/pub                      |
  | NONGNU_SITE      | https://download.savannah.nongnu.org/releases    |
  | PYPI_SITE        | https://files.pythonhosted.org/packages/source  |
  | SOURCEFORGE_SITE | https://downloads.sourceforge.net/sourceforge    |
  | UBUNTU_SITE      | http://archive.ubuntu.com/ubuntu/pool           |
  | XORG_SITE        | https://www.x.org/releases/individual            |
  | KDE_SITE         | https://download.kde.org/stable                 |
  | VIDEOLAN_SITE    | https://download.videolan.org/pub/videolan      |

- `checksum` The `sha256` digests matching `${distfiles}`. Multiple files can be
separated by blanks. Please note that the order must be the same than
was used in `${distfiles}`. Example: `checksum="kkas00xjkjas"`

If a distfile changes its checksum for every download because it is packaged
on the fly on the server, like e.g. snapshot tarballs from any of the
`https://*.googlesource.com/` sites, the checksum of the `archive contents`
can be specified by prepending a commercial at (@).
For tarballs you can find the contents checksum by using the command
`tar xf <tarball.ext> --to-stdout | sha256sum`.

- `wrksrc` The directory name where the package sources are extracted, by default
set to `${pkgname}-${version}`. If the top level directory of a package's `distfile` is different from the default, `wrksrc` must be set to the top level directory name inside the archive.

- `build_wrksrc` A directory relative to `${wrksrc}` that will be used when building the package.

- `create_wrksrc` Enable it to create the `${wrksrc}` directory. Required if a package
contains multiple `distfiles`.

- `build_style` This specifies the `build method` for a package. Read below to know more
about the available package `build methods` or effect of leaving this not set.

- `build_helper` Whitespace-separated list of files in `common/build-helper` to be
sourced and its variables be made available on the template. i.e. `build_helper="rust"`.

- `configure_script` The name of the `configure` script to execute at the `configure` phase if
`${build_style}` is set to `configure` or `gnu-configure` build methods.
By default set to `./configure`.

- `configure_args` The arguments to be passed in to the `configure` script if `${build_style}`
is set to `configure` or `gnu-configure` build methods. By default, prefix
must be set to `/usr`. In `gnu-configure` packages, some options are already
set by default: `--prefix=/usr --sysconfdir=/etc --infodir=/usr/share/info --mandir=/usr/share/man --localstatedir=/var`.

- `make_cmd` The executable to run at the `build` phase if `${build_style}` is set to
`configure`, `gnu-configure` or `gnu-makefile` build methods.
By default set to `make`.

- `make_build_args` The arguments to be passed in to `${make_cmd}` at the build phase if
`${build_style}` is set to `configure`, `gnu-configure` or `gnu-makefile`
build methods. Unset by default.

- `make_check_args` The arguments to be passed in to `${make_cmd}` at the check phase if
`${build_style}` is set to `configure`, `gnu-configure` or `gnu-makefile`
build methods. Unset by default.

- `make_install_args` The arguments to be passed in to `${make_cmd}` at the `install`
phase if `${build_style}` is set to `configure`, `gnu-configure` or `gnu-makefile` build methods.

- `make_build_target` The build target. If `${build_style}` is set to `configure`, `gnu-configure`
or `gnu-makefile`, this is the target passed to `${make_cmd}` in the build phase;
when unset the default target is used.
If `${build_style}` is `python3-pep517`, this is the path of the package
directory that should be built as a Python wheel; when unset, defaults to `.` (the current
directory with respect to the build).

- `make_check_target` The target to be passed in to `${make_cmd}` at the check phase if
`${build_style}` is set to `configure`, `gnu-configure` or `gnu-makefile`
build methods. By default set to `check`.

- `make_install_target` The installation target. When `${build_style}` is set to `configure`,
`gnu-configure` or `gnu-makefile`, this is the target passed to `${make_command}` in the install
phase; when unset, it defaults to `install`. If `${build_style}` is `python-pep517`, this is the
path of the Python wheel produced by the build phase that will be installed; when unset, the
`python-pep517` build style will look for a wheel matching the package name and version in the
current directory with respect to the install.

- `make_check_pre` The expression in front of `${make_cmd}`. This can be used for wrapper commands
or for setting environment variables for the check command. By default empty.

- `patch_args` The arguments to be passed in to the `patch(1)` command when applying
patches to the package sources during `do_patch()`. Patches are stored in
`srcpkgs/<pkgname>/patches` and must be in `-p1` format. By default set to `-Np1`.

- `disable_parallel_build` If set the package won't be built in parallel
and `XBPS_MAKEJOBS` will be set to 1. If a package does not work well with `XBPS_MAKEJOBS`
but still has a mechanism to build in parallel, set `disable_parallel_build` and
use `XBPS_ORIG_MAKEJOBS` (which holds the original value of `XBPS_MAKEJOBS`) in the template.

- `disable_parallel_check` If set tests for the package won't be built and run in parallel
and `XBPS_MAKEJOBS` will be set to 1. If a package does not work well with `XBPS_MAKEJOBS`
but still has a mechanism to run checks in parallel, set `disable_parallel_check` and
use `XBPS_ORIG_MAKEJOBS` (which holds the original value of `XBPS_MAKEJOBS`) in the template.

- `make_check` Sets the cases in which the `check` phase is run.
This option has to be accompanied by a comment explaining why the tests fail.
Allowed values:
  - `yes` (the default) to run if `XBPS_CHECK_PKGS` is set.
  - `extended` to run if `XBPS_CHECK_PKGS` is `full`.
  - `ci-skip` to run locally if `XBPS_CHECK_PKGS` is set, but not as part of pull request checks.
  - `no` to never run.


- `keep_libtool_archives` If enabled the `GNU Libtool` archives won't be removed. By default those
files are always removed automatically.

- `skip_extraction` A list of filenames that should not be extracted in the `extract` phase.
This must match the basename of any url defined in `${distfiles}`.
Example: `skip_extraction="foo-${version}.tar.gz"`.

- `nodebug` If enabled -dbg packages won't be generated even if `XBPS_DEBUG_PKGS` is set.

- `conf_files` A list of configuration files the binary package owns; this expects full
paths, wildcards will be extended, and multiple entries can be separated by blanks.
Example: `conf_files="/etc/foo.conf /etc/foo2.conf /etc/foo/*.conf"`.

- `mutable_files` A list of files the binary package owns, with the expectation
  that those files will be changed. These act a lot like `conf_files` but
  without the assumption that a human will edit them.

- `make_dirs` A list of entries defining directories and permissions to be
  created at install time. Each entry should be space separated, and will
  itself contain spaces. `make_dirs="/dir 0750 user group"`. User and group and
  mode are required on every line, even if they are `755 root root`. By
  convention, there is only one entry of `dir perms user group` per line.

- `repository` Defines the repository in which the package will be placed. See
  *Repositories* for a list of valid repositories.

- `nostrip` If set, the ELF binaries with debugging symbols won't be stripped. By
default all binaries are stripped.

- `nostrip_files` White-space separated list of ELF binaries that won't be stripped of
debugging symbols. Files can be given by full path or by filename.

- `noshlibprovides` If set, the ELF binaries won't be inspected to collect the provided
sonames in shared libraries.

- `noverifyrdeps` If set, the ELF binaries and shared libraries won't be inspected to collect
their reverse dependencies. You need to specify all dependencies in the `depends` when you
need to set this.

- `skiprdeps` White space separated list of filenames specified by their absolute path in
the `$DESTDIR` which will not be scanned for runtime dependencies. This may be useful to
skip files which are not meant to be run or loaded on the host but are to be sent to some
target device or emulation.

- `ignore_elf_files` White space separated list of machine code files
in /usr/share directory specified by absolute path, which are expected and allowed.

- `ignore_elf_dirs` White space separated list of directories in /usr/share directory
specified by absolute path, which are expected and allowed to contain machine code files.

- `nocross` If set, cross compilation won't be allowed and will exit immediately.
This should be set to a string describing why it fails, or a link to a buildlog (from the official builders, CI buildlogs can vanish) demonstrating the failure.

- `restricted` If set, xbps-src will refuse to build the package unless
`etc/conf` has `XBPS_ALLOW_RESTRICTED=yes`. The primary builders for Void
Linux do not have this setting, so the primary repositories will not have any
restricted package. This is useful for packages where the license forbids
redistribution.

- `subpackages` A white space separated list of subpackages (matching `foo_package()`)
to override the guessed list. Only use this if a specific order of subpackages is required,
otherwise the default would work in most cases.

- `broken` If set, building the package won't be allowed because its state is currently broken.
This should be set to a string describing why it is broken, or a link to a buildlog demonstrating the failure.

- `shlib_provides` A white space separated list of additional sonames the package provides on.
This appends to the generated file rather than replacing it.

- `shlib_requires` A white space separated list of additional sonames the package requires.
This appends to the generated file rather than replacing it.

- `nopie` Only needs to be set to something to make active, disables building the package with hardening
  features (PIE, relro, etc). Not necessary for most packages.

- `nopie_files` White-space separated list of ELF binaries that won't be checked
for PIE. Files must be given by full path.

- `reverts` xbps supports a unique feature which allows to downgrade from broken
packages automatically. In the `reverts` field one can define a list of broken
pkgver the resulting package should revert. This field *must* be defined before
`version` and `revision` fields in order to work as expected. The versions
defined in `reverts` must be bigger than the one defined in `version`.
Example:

    ```
    reverts="2.0_1 2.0_2"
    version=1.9
    revision=2
    ```

- `alternatives` A white space separated list of supported alternatives the package provides.
A list is composed of three components separated by a colon: group, symlink and target.
Example: `alternatives="vi:/usr/bin/vi:/usr/bin/nvi ex:/usr/bin/ex:/usr/bin/nvi-ex"`.

- `font_dirs` A white space separated list of directories specified by an absolute path where a
font package installs its fonts.
It is used in the `x11-fonts` xbps-trigger to rebuild the font cache during install/removal
of the package.
Example: `font_dirs="/usr/share/fonts/TTF /usr/share/fonts/X11/misc"`

- `dkms_modules` A white space separated list of Dynamic Kernel Module Support (dkms) modules
that will be installed and removed by the `dkms` xbps-trigger with the install/removal of the
package.
The format is a white space separated pair of strings that represent the name of the module,
most of the time `pkgname`, and the version of the module, most of the time `version`.
Example: `dkms_modules="$pkgname $version zfs 4.14"`

- `register_shell` A white space separated list of shells defined by absolute path to be
registered into the system shells database. It is used by the `register-shell` trigger.
Example: `register_shell="/bin/tcsh /bin/csh"`

- `tags` A white space separated list of tags (categories) that are registered into the
package metadata and can be queried with `xbps-query` by users.
Example for qutebrowser: `tags="browser chromium-based qt5 python3"`

- `perl_configure_dirs` A white space separate list of directories relative to `wrksrc`
that contain Makefile.PL files that need to be processes for the package to work. It is
used in the perl-module build_style and has no use outside of it.
Example: `perl_configure_dirs="blob/bob foo/blah"`

- `preserve` If set, files owned by the package in the system are not removed when
the package is updated, reinstalled or removed. This is mostly useful for kernel packages
that shouldn't remove the kernel files when they are removed in case it might break the
user's booting and module loading. Otherwise in the majority of cases it should not be
used.

- `fetch_cmd` Executable to be used to fetch URLs in `distfiles` during the `do_fetch` phase.

- `changelog` An URL pointing to the upstream changelog. Raw text files are preferred.

- `archs` Whitespace separated list of architectures that a package can be
built for, available architectures can be found under `common/cross-profiles`.
In general, `archs` should only be set if the upstream software explicitly targets
certain architectures or there is a compelling reason why the software should not be
available on some supported architectures.
Prepending pattern with tilde means disallowing build on indicated archs.
First matching pattern is taken to allow/deny build. When no pattern matches,
package is build if last pattern includes tilde.
Examples:

	```
	# Build package only for musl architectures
	archs="*-musl"
	# Build package for x86_64-musl and any non-musl architecture
	archs="x86_64-musl ~*-musl"
	# Default value (all arches)
	archs="*"
	```
A special value `noarch` used to be available, but has since been removed.

- `nocheckperms` If set, xbps-src will not fail on common permission errors (world writable files, etc.)

- `nofixperms` If set, xbps-src will not fix common permission errors (executable manpages, etc.)

<a id="explain_depends"></a>
#### About the many types of `depends` variables

So far, we have listed four types of `depends` variables: `hostmakedepends`,
`makedepends`, `checkdepends` and `depends`. These different kinds of variables
are necessary because `xbps-src` supports cross compilation and to avoid
installing unnecessary packages in the build environment.

During a build process, there are programs that must be _run_ on the host, such
as `yacc` or the C compiler. The packages that contain these programs should be
listed in `hostmakedepends`, and will be installed on the host when building the
target package. Some of these packages are dependencies of the `base-chroot`
package and don't need to be listed. It is possible that some of the programs
necessary to build a project are located in `-devel` packages.

The target package can also depend on other packages for libraries to link
against or header files. These packages should be listed in `makedepends` and
will match the target architecture, regardless of the architecture of the build
machine. Typically, `makedepends` will contain mainly `-devel` packages.

Furthermore, if `XBPS_CHECK_PKGS` is set or the `-Q` option is passed to
`xbps-src`, the target package might require specific dependencies or libraries
that are linked into its test binaries to run its test suite. These dependencies
should be listed in `checkdepends` and will be installed as if they were part of
`hostmakedepends`. Some dependencies that can be included in `checkdepends` are:

- `dejagnu`: used for some GNU projects
- `cmocka-devel`: linked into test binaries
- `dbus`: makes it possible to run `dbus-run-session <test-command>` to provide
  a D-Bus session for applications that need it
- `git`: some test suites run the `git` command

Lastly, a package may require certain dependencies at runtime, without which it
is unusable. These dependencies, when they aren't detected automatically by
XBPS, should be listed in `depends`. This is mostly relevant for Perl and Python
modules and other programs that use `dlopen(3)` instead of dynamically linking.

Finally, as a general rule, if a package is built the exact same way whether or
not a particular package is present in `makedepends` or `hostmakedepends`, that
package shouldn't be added as a build time dependency.

<a id="repositories"></a>
#### Repositories

<a id="repo_by_branch"></a>
##### Repositories defined by Branch

The global repository takes the name of
the current branch, except if the name of the branch is master. Then the resulting
repository will be at the global scope. The usage scenario is that the user can
update multiple packages in a second branch without polluting his local repository.

<a id="pkg_defined_repo"></a>
##### Package defined Repositories

The second way to define a repository is by setting the `repository` variable in
a template. This way the maintainer can define repositories for a specific
package or a group of packages. This is currently used to distinguish between
closed source packages, which are put in the `nonfree` repository and other
packages which are at the root-repository.

The following repository names are valid:

* `nonfree`: Repository for closed source packages.

<a id="updates"></a>
### Checking for new upstream releases

New upstream versions can be automatically checked using
`./xbps-src update-check <pkgname>`. In some cases you need to override
the sensible defaults by assigning the following variables in a `update`
file in the same directory as the relevant `template` file:

- `site` contains the URL where the version number is
  mentioned.  If unset, defaults to `homepage` and the directories where
`distfiles` reside.

- `pkgname` is the package name the default pattern checks for.
If unset, defaults to `pkgname` from the template.

- `pattern` is a perl-compatible regular expression
matching the version number.  Anchor the version number using `\K`
and `(?=...)`.  Example: `pattern='<b>\K[\d.]+(?=</b>)'`, this
matches a version number enclosed in `<b>...</b>` tags.

- `ignore` is a space-separated list of shell globs that match
version numbers which are not taken into account for checking newer
versions.  Example: `ignore="*b*"`

- `version` is the version number used to compare against
upstream versions. Example: `version=${version//./_}`

- `single_directory` can be set to disable
detecting directory containing one version of sources in url,
then searching new version in adjacent directories.

- `vdprefix` is a perl-compatible regular expression matching
part that precedes numeric part of version directory
in url. Defaults to `(|v|$pkgname)[-_.]*`.

- `vdsuffix` is a perl-compatible regular expression matching
part that follows numeric part of version directory
in url. Defaults to `(|\.x)`.

<a id="patches"></a>
### Handling patches

Sometimes software needs to be patched, most commonly to fix bugs that have
been found or to fix compilation with new software.

To handle this, xbps-src has patching functionality. It will look for all files
that match the glob `srcpkgs/$pkgname/patches/*.{diff,patch}` and will
automatically apply all files it finds using `patch(1)` with `-Np1`. This happens
during the `do_patch()` phase. The variable `PATCHESDIR` is
available in the template, pointing to the `patches` directory.

The patching behaviour can be changed in the following ways:

- A file called `series` can be created in the `patches` directory with a newline
separated list of patches to be applied in the order presented. When present
xbps-src will only apply patches named in the `series` file.

- A file with the same name as one of the patches but with `.args` as extension can
be used to set the args passed to `patch(1)`. As an example, if `foo.patch` requires
special arguments to be passed to `patch(1)` that can't be used when applying other
patches, `foo.patch.args` can be created containing those args.

<a id="build_scripts"></a>
### build style scripts

The `build_style` variable specifies the build method to build and install a
package. It expects the name of any available script in the
`void-packages/common/build-style` directory. Please note that required packages
to execute a `build_style` script must be defined via `$hostmakedepends`.

The current list of available `build_style` scripts is the following:

- If `build_style` is not set, the template must (at least) define
`do_install()` function and optionally more build phases such as
`do_configure()`, `do_build()`, etc., and may overwrite default `do_fetch()` and
`do_extract()` that fetch and extract files defined in `distfiles` variable.

- `cargo` For packages written in rust that use Cargo for building.
Configuration arguments (such as `--features`) can be defined in the variable
`configure_args` and are passed to cargo during `do_build`.

- `cmake` For packages that use the CMake build system, configuration arguments
can be passed in via `configure_args`. The `cmake_builddir` variable may be
defined to specify the directory for building under `build_wrksrc` instead of
the default `build`.

- `configure` For packages that use non-GNU configure scripts, at least `--prefix=/usr`
should be passed in via `configure_args`.

- `fetch` For packages that only fetch files and are installed as is via `do_install()`.

- `gnu-configure` For packages that use GNU configure scripts, additional configuration
arguments can be passed in via `configure_args`.

- `gnu-makefile` For packages that use GNU make, build arguments can be passed in via
`make_build_args` and install arguments via `make_install_args`. The build
target can be overridden via `make_build_target` and the install target
via `make_install_target`. This build style tries to compensate for makefiles
that do not respect environment variables, so well written makefiles, those
that do such things as append (`+=`) to variables, should have `make_use_env`
set in the body of the template.

- `go` For programs written in Go that follow the standard package
structure. The variable `go_import_path` must be set to the package's
import path, e.g. `github.com/github/hub` for the `hub` program. This
information can be found in the `go.mod` file for modern Go projects.
It's expected that the distfile contains the package, but dependencies
will be downloaded with `go get`.

- `meta` For `meta-packages`, i.e packages that only install local files or simply
depend on additional packages. This build style does not install
dependencies to the root directory, and only checks if a binary package is
available in repositories.

- `R-cran` For packages that are available on The Comprehensive R Archive
Network (CRAN). The build style requires the `pkgname` to start with
`R-cran-` and any dashes (`-`) in the CRAN-given version to be replaced
with the character `r` in the `version` variable. The `distfiles`
location will automatically be set as well as the package made to depend
on `R`.

- `gemspec` For packages that use
[gemspec](https://guides.rubygems.org/specification-reference/) files for building a ruby
gem and then installing it. The gem command can be overridden by `gem_cmd`. `configure_args`
can be used to pass arguments during compilation. If your package does not make use of compiled
extensions consider using the `gem` build style instead.

- `gem` For packages that are installed using gems from [RubyGems](https://rubygems.org/).
The gem command can be overridden by `gem_cmd`.
`distfiles` is set by the build style if the template does not do so. If your gem
provides extensions which must be compiled consider using the `gemspec` build style instead.

- `ruby-module` For packages that are ruby modules and are installable via `ruby install.rb`.
Additional install arguments can be specified via `make_install_args`.

- `perl-ModuleBuild` For packages that use the Perl
[Module::Build](https://metacpan.org/pod/Module::Build) method.

- `perl-module` For packages that use the Perl
[ExtUtils::MakeMaker](http://perldoc.perl.org/ExtUtils/MakeMaker.html) build method.

- `raku-dist` For packages that use the Raku `raku-install-dist` build method with rakudo.

- `waf3` For packages that use the Python3 `waf` build method with python3.

- `waf` For packages that use the Python `waf` method with python2.

- `slashpackage` For packages that use the /package hierarchy and package/compile to build,
such as `daemontools` or any `djb` software.

- `qmake` For packages that use Qt4/Qt5 qmake profiles (`*.pro`), qmake arguments
for the configure phase can be passed in via `configure_args`, make build arguments can
be passed in via `make_build_args` and install arguments via `make_install_args`. The build
target can be overridden via `make_build_target` and the install target
via `make_install_target`.

- `meson` For packages that use the Meson Build system, configuration options can be passed
via `configure_args`, the meson command can be overridden by `meson_cmd` and the location of
the out of source build by `meson_builddir`

- `void-cross` For cross-toolchain packages used to build Void systems. There are no
mandatory variables (target triplet is inferred), but you can specify some optional
ones - `cross_gcc_skip_go` can be specified to skip `gccgo`, individual subproject
configure arguments can be specified via `cross_*_configure_args` where `*` is `binutils`,
`gcc_bootstrap` (early gcc), `gcc` (final gcc), `glibc` (or `musl`), `configure_args` is
additionally passed to both early and final `gcc`. You can also specify custom `CFLAGS`
and `LDFLAGS` for the libc as `cross_(glibc|musl)_(cflags|ldflags)`.

- `zig-build` For packages using [Zig](https://ziglang.org)'s build
system. Additional arguments may be passed to the `zig build` invocation using
`configure_args`.

For packages that use the Python module build method (`setup.py` or
[PEP 517](https://www.python.org/dev/peps/pep-0517/)), you can choose one of the following:

- `python-module` to build *both* Python 2.x and 3.x modules

- `python2-module` to build Python 2.x only modules

- `python3-module` to build Python 3.x only modules

- `python3-pep517` to build Python 3.x only modules that provide a PEP 517 build description without
a `setup.py` script

Environment variables for a specific `build_style` can be declared in a filename
matching the `build_style` name, Example:

    `common/environment/build-style/gnu-configure.sh`

- `texmf` For texmf zip/tarballs that need to go into /usr/share/texmf-dist. Includes
duplicates handling.

<a id="build_helper"></a>
### build helper scripts

The `build_helper` variable specifies shell snippets to be sourced that will create a
suitable environment for working with certain sets of packages.

The current list of available `build_helper` scripts is the following:

- `rust` specifies environment variables required for cross-compiling crates via cargo and
for compiling cargo -sys crates.

- `gir` specifies dependencies for native and cross builds to deal with
GObject Introspection. The following variables may be set in the template to handle
cross builds which require additional hinting or exhibit problems. `GIR_EXTRA_LIBS_PATH` defines
additional paths to be searched when linking target binaries to be introspected.
`GIR_EXTRA_OPTIONS` defines additional options for the `g-ir-scanner-qemuwrapper` calling
`qemu-<target_arch>-static` when running the target binary. You can for example specify
`GIR_EXTRA_OPTIONS="-strace"` to see a trace of what happens when running that binary.

- `qemu` sets additional variables for the `cmake` and `meson` build styles to allow
executing cross-compiled binaries inside qemu.
It sets `CMAKE_CROSSCOMPILING_EMULATOR` for cmake and `exe_wrapper` for meson
to `qemu-<target_arch>-static` and `QEMU_LD_PREFIX` to `XBPS_CROSS_BASE`.
It also creates the `vtargetrun` function to wrap commands in a call to
`qemu-<target_arch>-static` for the target architecture.

- `qmake` creates the `qt.conf` configuration file (cf. `qmake` `build_style`)
needed for cross builds and a qmake-wrapper to make `qmake` use this configuration.
This aims to fix cross-builds for when the build-style is mixed: e.g. when in a
`gnu-configure` style the configure script calls `qmake` or a `Makefile` in
`gnu-makefile` style, respectively.

- `cmake-wxWidgets-gtk3` sets the `WX_CONFIG` variable which is used by FindwxWidgets.cmake

<a id="functions"></a>
### Functions

The following functions can be defined to change the behavior of how the
package is downloaded, compiled and installed.

- `pre_fetch()` Actions to execute before `do_fetch()`.

- `do_fetch()` if defined and `distfiles` is not set, use it to fetch the required sources.

- `post_fetch()` Actions to execute after `do_fetch()`.

- `pre_extract()` Actions to execute after `post_fetch()`.

- `do_extract()` if defined and `distfiles` is not set, use it to extract the required sources.

- `post_extract()` Actions to execute after `do_extract()`.

- `pre_patch()` Actions to execute after `post_extract()`.

- `do_patch()` if defined use it to prepare the build environment and run hooks to apply patches.

- `post_patch()` Actions to execute after `do_patch()`.

- `pre_configure()` Actions to execute after `post_patch()`.

- `do_configure()` Actions to execute to configure the package; `${configure_args}` should
still be passed in if it's a GNU configure script.

- `post_configure()` Actions to execute after `do_configure()`.

- `pre_build()` Actions to execute after `post_configure()`.

- `do_build()` Actions to execute to build the package.

- `post_build()` Actions to execute after `do_build()`.

- `pre_check()` Actions to execute after `post_build()`.

- `do_check()` Actions to execute to run checks for the package.

- `post_check()` Actions to execute after `do_check()`.

- `pre_install()` Actions to execute after `post_check()`.

- `do_install()` Actions to execute to install the package files into the `fake destdir`.

- `post_install()` Actions to execute after `do_install()`.

- `do_clean()` Actions to execute to clean up after a successful package phase.

> A function defined in a template has preference over the same function
defined by a `build_style` script.

Current working directory for functions is set as follows:

- For pre_fetch, pre_extract, do_clean: `<masterdir>`.

- For do_fetch, post_fetch: `XBPS_BUILDDIR`.

- For do_extract through do_patch: `wrksrc`.

- For post_patch through post_install: `build_wrksrc`
if it is defined, otherwise `wrksrc`.

<a id="build_options"></a>
### Build options

Some packages might be built with different build options to enable/disable
additional features; The XBPS source packages collection allows you to do this with some simple tweaks
to the `template` file.

The following variables may be set to allow package build options:

- `build_options` Sets the build options supported by the source package.

- `build_options_default` Sets the default build options to be used by the source package.

- `desc_option_<option>` Sets the description for the build option `option`. This must match the
keyword set in *build_options*. Note that if the build option is generic enough, its description
should be added to `common/options.description` instead.

After defining those required variables, you can check for the
`build_option_<option>` variable to know if it has been set and adapt the source
package accordingly. Additionally, the following functions are available:

- *vopt_if()* `vopt_if <option> <if_true> [<if_false>]`

  Outputs `if_true` if `option` is set, or `if_false` if it isn't set.

- *vopt_with()* `vopt_with <option> [<flag>]`

  Outputs `--with-<flag>` if the option is set, or `--without-<flag>`
  otherwise. If `flag` isn't set, it defaults to `option`.

  Examples:

  - `vopt_with dbus`
  - `vopt_with xml xml2`

- *vopt_enable()* `vopt_enable <option> [<flag>]`

  Same as `vopt_with`, but uses `--enable-<flag>` and
  `--disable-<flag>` respectively.

- *vopt_conflict()* `vopt_conflict <option 1> <option 2>`

  Emits an error and exits if both options are set at the same time.

- *vopt_bool()* `vopt_bool <option> <property>`

  Outputs `-D<property>=true` if the option is set, or
  `-D<property>=false` otherwise.

The following example shows how to change a source package that uses GNU
configure to enable a new build option to support PNG images:

```
# Template file for 'foo'
pkgname=foo
version=1.0
revision=1
build_style=gnu-configure
configure_args="... $(vopt_with png)"
makedepends="... $(vopt_if png libpng-devel)"
...

# Package build options
build_options="png"
desc_option_png="Enable support for PNG images"

# To build the package by default with the `png` option:
#
# build_options_default="png"

...

```

The supported build options for a source package can be shown with `xbps-src`:

    $ ./xbps-src show-options foo

Build options can be enabled with the `-o` flag of `xbps-src`:

    $ ./xbps-src -o option,option1 <cmd> foo

Build options can be disabled by prefixing them with `~`:

    $ ./xbps-src -o ~option,~option1 <cmd> foo

Both ways can be used together to enable and/or disable multiple options
at the same time with `xbps-src`:

    $ ./xbps-src -o option,~option1,~option2 <cmd> foo

The build options can also be shown for binary packages via `xbps-query(8)`:

    $ xbps-query -R --property=build-options foo

Permanent global package build options can be set via `XBPS_PKG_OPTIONS` variable in the
`etc/conf` configuration file. Per package build options can be set via
`XBPS_PKG_OPTIONS_<pkgname>`.

> NOTE: if `pkgname` contains `dashes`, those should be replaced by `underscores`
Example: `XBPS_PKG_OPTIONS_xorg_server=opt`.

The list of supported package build options and its description is defined in the
`common/options.description` file.

<a id="deps_runtime"></a>
#### Runtime dependencies

Dependencies for ELF objects are detected automatically by `xbps-src`, hence runtime
dependencies must not be specified in templates via `$depends` with the following exceptions:

- ELF objects using dlopen(3).
- non ELF objects, i.e perl/python/ruby/etc modules.
- Overriding the minimal version specified in the `shlibs` file.

The runtime dependencies for ELF objects are detected by checking which SONAMEs
they require and then the SONAMEs are mapped to a binary package name with a minimal
required version. The `shlibs` file in the `void-packages/common` directory
sets up the `<SONAME> <pkgname>>=<version>` mappings.

For example the `foo-1.0_1` package provides the `libfoo.so.1` SONAME and
software requiring this library will link to `libfoo`; the resulting binary
package will have a run-time dependency to `foo>=1.0_1` package as specified in
`common/shlibs`:

```
# common/shlibs
...
libfoo.so.1 foo-1.0_1
...
```

- The first field specifies the SONAME.
- The second field specified the package name and minimal version required.
- A third optional field (usually set to `ignore`) can be used to skip checks in soname bumps.

Dependencies declared via `${depends}` are not installed to the master directory, rather are
only checked if they exist as binary packages, and are built automatically by `xbps-src` if
the specified version is not in the local repository.

As a special case, `virtual` dependencies may be specified as runtime dependencies in the
`${depends}` template variable. Several different packages can provide common functionality by
declaring a virtual name and version in the `${provides}` template variable (e.g.,
`provides="vpkg-0.1_1"`). Packages that rely on the common functionality without concern for the
specific provider can declare a dependency on the virtual package name with the prefix `virtual?`
(e.g., `depends="virtual?vpkg-0.1_1"`). When a package is built by `xbps-src`, providers for any
virtual packages will be confirmed to exist and will be built if necessary. A map from virtual
packages to their default providers is defined in `etc/defaults.virtual`. Individual mappings can be
overridden by local preferences in `etc/virtual`. Comments in `etc/defaults.virtual` provide more
information on this map.

<a id="install_remove_files"></a>
### INSTALL and REMOVE files

The INSTALL and REMOVE shell snippets can be used to execute certain actions at a specified
stage when a binary package is installed, updated or removed. There are some variables
that are always set by `xbps` when the scripts are executed:

- `$ACTION`: to conditionalize its actions: `pre` or `post`.
- `$PKGNAME`: the package name.
- `$VERSION`: the package version.
- `$UPDATE`: set to `yes` if package is being upgraded, `no` if package is being `installed` or `removed`.
- `$CONF_FILE`: full path to `xbps.conf`.
- `$ARCH`: the target architecture it is running on.

An example of how an `INSTALL` or `REMOVE` script shall be created is shown below:

```
# INSTALL
case "$ACTION" in
pre)
	# Actions to execute before the package files are unpacked.
	...
	;;
post)
	if [ "$UPDATE" = "yes" ]; then
		# actions to execute if package is being updated.
		...
	else
		# actions to execute if package is being installed.
		...
	fi
	;;
esac
```

subpackages can also have their own `INSTALL` and `REMOVE` files, simply create them
as `srcpkgs/<pkgname>/<subpkg>.INSTALL` or `srcpkgs/<pkgname>/<subpkg>.REMOVE` respectively.

> NOTE: always use paths relative to the current working directory, otherwise if the scripts cannot
be executed via `chroot(2)` won't work correctly.

> NOTE: do not use INSTALL/REMOVE scripts to print messages, see the next section for
more information.

<a id="install_remove_files_msg"></a>
### INSTALL.msg and REMOVE.msg files

The `INSTALL.msg` and `REMOVE.msg` files can be used to print a message at post-install
or pre-remove time, respectively.

Ideally those files should not exceed 80 chars per line.

subpackages can also have their own `INSTALL.msg` and `REMOVE.msg` files, simply create them
as `srcpkgs/<pkgname>/<subpkg>.INSTALL.msg` or `srcpkgs/<pkgname>/<subpkg>.REMOVE.msg` respectively.

<a id="runtime_account_creation"></a>
### Creating system accounts/groups at runtime

There's a trigger along with some variables that are specifically to create
**system users and groups** when the binary package is being configured.
The following variables can be used for this purpose:

- `system_groups` This specifies the names of the new *system groups* to be created, separated
by blanks. Optionally the **gid** can be specified by delimiting it with a
colon, i.e `system_groups="_mygroup:78"` or `system_groups="_foo _blah:8000"`.

- `system_accounts` This specifies the names of the new **system users/groups** to be created,
separated by blanks, i.e `system_accounts="_foo _blah:22"`. Optionally the **uid** and **gid**
can be specified by delimiting it with a colon, i.e `system_accounts="_foo:48"`.
Additional variables for the **system accounts** can be specified to change its behavior:

	- `<account>_homedir` the home directory for the user. If unset defaults to `/var/empty`.
	- `<account>_shell` the shell for the new user. If unset defaults to `/sbin/nologin`.
	- `<account>_descr` the description for the new user. If unset defaults to `<account> unprivileged user`.
	- `<account>_groups` additional groups to be added to for the new user.
	- `<account>_pgroup` to set the primary group, by default primary group is set to `<account>`.

The **system user** is created by using a dynamically allocated **uid/gid** in your system
and it's created as a `system account`, unless the **uid** is set. A new group will be created for the
specified `system account` and used exclusively for this purpose.

System accounts and groups must be prefixed with an underscore to prevent clashing with names of user
accounts.

> NOTE: The underscore policy does not apply to old packages, due to the inevitable breakage of
> changing the username only new packages should follow it.

<a id="writing_runit_services"></a>
### Writing runit services

Void Linux uses [runit](http://smarden.org/runit/) for booting and supervision of services.

Most information about how to write them can be found in their
[FAQ](http://smarden.org/runit/faq.html#create). The following are guidelines specific to
Void Linux on how to write services.

If the service daemon supports CLI flags, consider adding support for changing it via the
`OPTS` variable by reading a file called `conf` in the same directory as the daemon.

```sh
#!/bin/sh
[ -r conf ] && . ./conf
exec daemon ${OPTS:- --flag-enabled-by-default}
```

If the service requires the creation of a directory under `/run` or its link `/var/run`
for storing runtime information (like Pidfiles) write it into the service file. It
is advised to use `install` if you need to create it with specific permissions instead
of `mkdir -p`.

```sh
#!/bin/sh
install -d -m0700 /run/foo
exec foo
```

```sh
#!/bin/sh
install -d -m0700 -o bar -g bar /run/bar
exec bar
```

If the service requires directories in parts of the system that are not generally in
temporary filesystems. Then use the `make_dirs` variable in the template to create
those directories when the package is installed.

If the package installs a systemd service file or other unit, leave it in place as a
reference point so long as including it has no negative side effects.

Examples of when *not* to install systemd units:

1. When doing so changes runtime behavior of the packaged software.
2. When it is done via a compile time flag that also changes build dependencies.

<a id="32bit_pkgs"></a>
### 32bit packages

32bit packages are built automatically when the builder is x86 (32bit), but
there are some variables that can change the behavior:

- `lib32depends` If this variable is set, dependencies listed here will be used rather than
those detected automatically by `xbps-src` and **depends**. Please note that
dependencies must be specified with version comparators, Example:
`lib32depends="foo>=0 blah<2.0"`.

- `lib32disabled` If this variable is set, no 32bit package will be built.

- `lib32files` Additional files to be added to the **32bit** package. This expect absolute
paths separated by blanks, Example: `lib32files="/usr/bin/blah /usr/include/blah."`.

- `lib32symlinks` Makes a symlink of the target filename stored in the `lib32` directory.
This expects the basename of the target file, Example: `lib32symlinks="foo"`.

- `lib32mode` If unset, only shared/static libraries and pkg-config files will be copied to the
**32bit** package. If set to `full` all files will be copied to the 32bit package, unmodified.

<a id="pkgs_sub"></a>
### Subpackages

In the example shown above just a binary package is generated, but with some
simple tweaks multiple binary packages can be generated from a single
template/build, this is called `subpackages`.

To create additional `subpackages` the `template` must define a new function
with this naming: `<subpkgname>_package()`, Example:

```
# Template file for 'foo'
pkgname=foo
version=1.0
revision=1
build_style=gnu-configure
short_desc="A short description max 72 chars"
maintainer="name <email>"
license="GPL-3.0-or-later"
homepage="http://www.foo.org"
distfiles="http://www.foo.org/foo-${version}.tar.gz"
checksum="fea0a94d4b605894f3e2d5572e3f96e4413bcad3a085aae7367c2cf07908b2ff"

# foo-devel is a subpkg
foo-devel_package() {
	short_desc+=" - development files"
	depends="${sourcepkg}>=${version}_${revision}"
	pkg_install() {
		vmove usr/include
		vmove "usr/lib/*.a"
		vmove "usr/lib/*.so"
		vmove usr/lib/pkgconfig
	}
}
```

All subpackages need an additional symlink to the `main` pkg, otherwise dependencies
requiring those packages won't find its `template` Example:

```
 /srcpkgs
  |- foo <- directory (main pkg)
  |  |- template
  |- foo-devel <- symlink to `foo`
```

The main package should specify all required `build dependencies` to be able to build
all subpackages defined in the template.

An important point of `subpackages` is that they are processed after the main
package has run its `install` phase. The `pkg_install()` function specified on them
commonly is used to move files from the `main` package destdir to the `subpackage` destdir.

The helper functions `vinstall`, `vmkdir`, `vcopy` and `vmove` are just wrappers that simplify
the process of creating, copying and moving files/directories between the `main` package
destdir (`$DESTDIR`) to the `subpackage` destdir (`$PKGDESTDIR`).

Subpackages are processed always in alphabetical order; To force a custom order,
the `subpackages` variable can be declared with the wanted order.

<a id="pkgs_development"></a>
### Development packages

A development package, commonly generated as a subpackage, shall only contain
files required for development, that is, headers, static libraries, shared
library symlinks, pkg-config files, API documentation or any other script
that is only useful when developing for the target software.

A development package should depend on packages that are required to link
against the provided shared libraries, i.e if `libfoo` provides the
`libfoo.so.2` shared library and the linking needs `-lbar`, the package
providing the `libbar` shared library should be added as a dependency;
and most likely it shall depend on its development package.

If a development package provides a `pkg-config` file, you should verify
what dependencies the package needs for dynamic or static linking, and add
the appropriate `development` packages as dependencies.

Development packages for the C and C++ languages usually `vmove` the
following subset of files from the main package:

* Header files `usr/include`
* Static libraries `usr/lib/*.a`
* Shared library symbolic links `usr/lib/*.so`
* Cmake rules `usr/lib/cmake` `usr/share/cmake`
* Package config files `usr/lib/pkgconfig` `usr/share/pkgconfig`
* Autoconf macros `usr/share/aclocal`
* Gobject introspection XML files `usr/share/gir-1.0`
* Vala bindings `usr/share/vala`

<a id="pkgs_data"></a>
### Data packages

Another common subpackage type is the `-data` subpackage. This subpackage
type used to split architecture independent, big(ger) or huge amounts
of data from a package's main and architecture dependent part. It is up
to you to decide, if a `-data` subpackage makes sense for your package.
This type is common for games (graphics, sound and music), part libraries (CAD)
or card material (maps).
The main package must then have `depends="${pkgname}-data-${version}_${revision}"`,
possibly in addition to other, non-automatic depends.

<a id="pkgs_documentation"></a>
### Documentation packages

Packages intended for user interaction do not always unconditionally require
their documentation part. A user who does not want to e.g. develop
with Qt5 will not need to install the (huge) qt5-doc package.
An expert may not need it or opt to use an online version.

In general a `-doc` package is useful, if the main package can be used both with
or without documentation and the size of the documentation isn't really small.
The base package and the `-devel` subpackage should be kept small so that when
building packages depending on a specific package there is no need to install large
amounts of documentation for no reason. Thus the size of the documentation part should
be your guidance to decide whether or not to split off a `-doc` subpackage.

<a id="pkgs_python"></a>
### Python packages

Python packages should be built with the `python{,2,3}-module` build style, if possible.
This sets some environment variables required to allow cross compilation. Support to allow
building a python module for multiple versions from a single template is also possible.
The `python3-pep517` build style provides means to build python packages that provide a build-system
definition compliant with [PEP 517](https://www.python.org/dev/peps/pep-0517/) without a traditional
`setup.py` script. The `python3-pep517` build style does not provide a specific build backend, so
packages will need to add an appropriate backend provider to `hostmakedepends`.

Python packages that rely on `python3-setuptools` should generally map `setup_requires`
dependencies in `setup.py` to `hostmakedepends` in the template and `install_requires`
dependencies to `depends` in the template; include `python3` in `depends` if there are no other
python dependencies. If the package includes a compiled extension, the `python3-devel` packages
should be added to `makedepends`, as should any python packages that also provide native libraries
against which the extension will be linked (even if that package is also included in
`hostmakedepends` to satisfy `setuptools`).

**NB**: Python `setuptools` will attempt to use `pip` or `EasyInstall` to fetch any missing
dependencies at build time. If you notice warnings about `EasyInstall` deprecation or python eggs
present in `${wrksrc}/.eggs` after building the package, then those packages should be added to
`hostmakedepends`.

The following variables may influence how the python packages are built and configured
at post-install time:

- `pycompile_module`: By default, files and directories installed into
`usr/lib/pythonX.X/site-packages`, excluding `*-info` and `*.so`, are byte-compiled
at install time as python modules.  This variable expects subset of them that
should be byte-compiled, if default is wrong.  Multiple python modules may be specified separated
by blanks, Example: `pycompile_module="foo blah"`. If a python module installs a file into
`site-packages` rather than a directory, use the name of the file, Example:
`pycompile_module="fnord.py"`.

- `pycompile_dirs`: this variable expects the python directories that should be `byte-compiled`
recursively by the target python version. This differs from `pycompile_module` in that any
path may be specified, Example: `pycompile_dirs="usr/share/foo"`.

- `python_version`: this variable expects the supported Python major version.
In most cases version is inferred from shebang, install path or build style.
Only required for some multi-language
applications (e.g., the application is written in C while the command is
written in Python) or just single Python file ones that live in `/usr/bin`.

Also, a set of useful variables are defined to use in the templates:

| Variable    | Value                            |
|-------------|----------------------------------|
| py2_ver     | 2.X                              |
| py2_lib     | usr/lib/python2.X                |
| py2_sitelib | usr/lib/python2.X/site-packages  |
| py2_inc     | usr/include/python2.X            |
| py3_ver     | 3.X                              |
| py3_lib     | usr/lib/python3.X                |
| py3_sitelib | usr/lib/python3.X/site-packages  |
| py3_inc     | usr/include/python3.Xm           |

> NOTE: it's expected that additional subpkgs must be generated to allow packaging for multiple
python versions.

<a id="pkgs_go"></a>
### Go packages

Go packages should be built with the `go` build style, if possible.
The `go` build style takes care of downloading Go dependencies and
setting up cross compilation.

The following template variables influence how Go packages are built:

- `go_import_path`: The import path of the package included in the
  distfile, as it would be used with `go get`. For example, GitHub's
  `hub` program has the import path `github.com/github/hub`. This
  variable is required.
- `go_package`: A space-separated list of import paths of the packages
  that should be built. Defaults to `go_import_path`.
- `go_build_tags`: An optional, space-separated list of build tags to
  pass to Go.
- `go_mod_mode`: The module download mode to use. May be `off` to ignore
  any go.mod files, `default` to use Go's default behavior, or anything
  accepted by `go build -mod MODE`.  Defaults to `vendor` if there's
  a vendor directory, otherwise `default`.
- `go_ldflags`: Arguments to pass to the linking steps of go tool.

The following environment variables influence how Go packages are built:

- `XBPS_MAKEJOBS`: Value passed to the `-p` flag of `go install`, to
  control the parallelism of the Go compiler.

Occasionally it is necessary to perform operations from within the Go
source tree.  This is usually needed by programs using go-bindata or
otherwise preping some assets.  If possible do this in pre_build().
The path to the package's source inside `$GOPATH` is available as
`$GOSRCPATH`.

<a id="pkgs_haskell"></a>
### Haskell packages

We build Haskell package using `stack` from
[Stackage](http://www.stackage.org/), generally the LTS versions.
Haskell templates need to have host dependencies on `ghc` and `stack`,
and set build style to `haskell-stack`.

The following variables influence how Haskell packages are built:

- `stackage`: The Stackage version used to build the package, e.g.
  `lts-3.5`. Alternatively:
  - You can prepare a `stack.yaml` configuration for the project and put it
    into `files/stack.yaml`.
  - If a `stack.yaml` file is present in the source files, it will be used
- `make_build_args`: This is passed as-is to `stack build ...`, so
  you can add your `--flag ...` parameters there.

<a id="pkgs_font"></a>
### Font packages

Font packages are very straightforward to write, they are always set with the
following variables:

- `depends="font-util"`: because they are required for regenerating the font
cache during the install/removal of the package
- `font_dirs`: which should be set to the directory where the package
installs its fonts

<a id="pkg_rename"></a>
### Renaming a package

- Create empty package of old name, depending on new package. This is
necessary to provide updates to systems where old package is already
installed. This should be a subpackage of new one, except when version
number of new package decreased: then create a separate template using
old version and increased revision.
- Edit references to package in other templates and common/shlibs.
- Don't set `replaces=`, it can result in removing both packages from
systems by xbps.

<a id="pkg_remove"></a>
### Removing a package

Follows a list of things that should be done to help guarantee that a
package template removal and by extension its binary packages from
Void Linux's repositories goes smoothly.

Before removing a package template:

- Guarantee that no package depends on it or any of its subpackages.
For that you can search the templates for references to the package
with `grep -r '\bpkg\b' srcpkgs/`.
- Guarantee that no package depends on shlibs provided by it.

When removing the package template:

- Remove all symlinks that point to the package.
`find srcpkgs/ -lname <pkg>` should be enough.
- If the package provides shlibs make sure to remove them from
common/shlibs.
- Some packages use patches and files from other packages using symlinks,
generally those packages are the same but have been split as to avoid
cyclic dependencies. Make sure that the package you're removing is not
the source of those patches/files.
- Remove package template.
- Add `pkgname<=version_revision` to `replaces` variable of `removed-packages`
template.  All removed subpkgs should be added too.
This will uninstall package from systems where it is installed.
- Remove the package from the repository index
or contact a team member that can do so.

<a id="xbps_triggers"></a>
### XBPS Triggers

XBPS triggers are a collection of snippets of code, provided by the `xbps-triggers`
package, that are added to the INSTALL/REMOVE scripts of packages either manually
by setting the `triggers` variable in the template, or automatically, when specific
conditions are met.

The following is a list of all available triggers, their current status, what each
of them does and what conditions need to be for it to be included automatically on a
package.

This is not a complete overview of the package. It is recommended to read the variables
referenced and the triggers themselves.

<a id="triggers_appstream_cache"></a>
#### appstream-cache

The appstream-cache trigger is responsible for rebuilding the appstream metadata cache.

During installation it executes `appstreamcli refresh-cache --verbose --force --datapath
$APPSTREAM_PATHS --cachepath var/cache/app-info/gv`. By default APPSTREAM_PATHS are all the
paths that appstreamcli will look into for metadata files.

The directories searched by appstreamcli are:

- `usr/share/appdata`
- `usr/share/app-info`
- `var/lib/app-info`
- `var/cache/app-info`

During removal of the `AppStream` package it will remove the `var/cache/app-info/gv`
directory.

It is automatically added to packages that have XML files under one of the directories
searched by appstreamcli.

<a id="triggers_binfmts"></a>
#### binfmts

The binfmts trigger is responsible for registration and removal of arbitrary
executable binary formats, know as binfmts.

During installation/removal it uses `update-binfmts` from the `binfmt-support` package
to register/remove entries from the arbitrary executable binary formats database.

To include the trigger use the `binfmts` variable, as the trigger won't do anything unless
it is defined.

<a id="triggers_dkms"></a>
#### dkms

The dkms trigger is responsible for compiling and removing dynamic kernel modules of a
package.

During installation the trigger compiles and installs the dynamic module for all `linux`
packages that have their corresponding linux-headers package installed. During removal
the corresponding module will be removed

To include the trigger use the `dkms_modules` variable, as the trigger won't do anything
unless it is defined.

<a id="triggers_gconf_schemas"></a>
#### gconf-schemas

The gconf-schemas trigger is responsible for registering and removing .schemas and
.entries files into the schemas database directory

During installation it uses `gconftool-2` to install .schemas and .entries files into
`usr/share/gconf/schemas`. During removal it uses `gconftool-2` to remove the entries
and schemas belonging to the package that is being removed from the database.

To include it add `gconf-schemas` to `triggers` and add the appropriate .schemas in
the `gconf_schemas` variable and .entries in `gconf_entries`.

It is automatically added to packages that have `/usr/share/gconf/schemas` present
as a directory. All files with the schemas file extension under that directory
are passed to the trigger.

<a id="triggers_gdk_pixbuf_loaders"></a>
#### gdk-pixbuf-loaders

The gdk-pixbuf-loaders trigger is responsible for maintaining the GDK Pixbuf loaders cache.

During installation it runs `gdk-pixbuf-query-loaders --update-cache` and also deletes
the obsolete `etc/gtk-2.0/gdk-pixbuf.loaders` file if present. During removal of the
gdk-pixbuf package it removes the cache file if present. Normally at
`usr/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache`.

It can be added by defining `gdk-pixbuf-loaders` in the `triggers` variable. It is also
added automatically to any package that has the path `usr/lib/gdk-pixbuf-2.0/2.10.0/loaders`
available as a directory.

<a id="triggers_gio_modules"></a>
#### gio-modules

The gio-modules trigger is responsible for updating the Glib GIO module cache with
`gio-querymodules` from the `glib` package

During install and removal it just runs `gio-querymodules` to update the cache file
present under `usr/lib/gio/modules`.

It is automatically added to packages that have `/usr/lib/gio/modules` present
as a directory.

<a id="triggers_gsettings_schemas"></a>
#### gsettings-schemas

The gsettings-schemas trigger is responsible for compiling Glib's GSettings XML
schema files during installation and removing the compiled files during removal.

During installation it uses `glib-compile-schemas` from `glib` to compile the
schemas into files with the suffix .compiled into `/usr/share/glib-2.0/schemas`.

During removal of the glib package it deletes all files inside
`/usr/share/glib-2.0/schemas` that end with .compiled.

It is automatically added to packages that have `/usr/share/glib-2.0/schemas` present
as a directory.

<a id="triggers_gtk_icon_cache"></a>
#### gtk-icon-cache

The gtk-icon-cache trigger is responsible for updating the gtk+ icon cache.

During installation it uses `gtk-update-icon-cache` to update the icon cache.

During removal of the gtk+ package it deletes the `icon-theme.cache` file
in the directories defined by the variable `gtk_iconcache_dirs`.

It is automatically added on packages that have `/usr/share/icons` available
as a directory, all directories under that directory have their absolute path
passed to the trigger.

<a id="triggers_gtk_immodules"></a>
#### gtk-immodules

The gtk-immodules trigger is responsible for updating the IM (Input Method) modules
file for gtk+.

During installation it uses `gtk-query-immodules-2.0 --update-cache` to update the
cache file. It also removes the obsolete configuration file  `etc/gtk-2.0/gtk.immodules`
if present.

During removal of the `gtk+` package it removes the cache file which is located at
`usr/lib/gtk-2.0/2.10.0/immodules.cache`.

It is automatically added to packages that have `/usr/lib/gtk-2.0/2.10.0/immodules`
present as a directory.

<a id="triggers_gtk_pixbuf_loaders"></a>
#### gtk-pixbuf-loaders

gtk-pixbuf-loaders is the old name for the current `gdk-pixbuf-loaders` trigger and is
in the process of being removed. It currently re-execs into `gdk-pixbuf-loaders` as a
compatibility measure.

For information about how it works refer to [gdk-pixbuf-loaders](#triggers_gdk_pixbuf_loaders).

<a id="triggers_gtk3_immodules"></a>
#### gtk3-immodules

The gtk3-immodules trigger is responsible for updating the IM (Input Method) modules
file for gtk+3.

During installation it executes `gtk-query-immodules-3.0 --update-cache` to update the
cache file. It also removes the obsolete configuration file  `etc/gtk-3.0/gtk.immodules`
if present.

During removal of the `gtk+3` package it removes the cache file which is located at
`usr/lib/gtk-3.0/3.0.0/immodules.cache`.

It is automatically added to packages that have `/usr/lib/gtk-3.0/3.0.0/immodules`
present as a directory.

<a id="triggers_hwdb.d_dir"></a>
#### hwdb.d-dir

The hwdb.d-dir trigger is responsible for updating the hardware database.

During installation and removal it runs `usr/bin/udevadm hwdb --root=. --update`.

It is automatically added to packages that have `/usr/lib/udev/hwdb.d` present
as a directory.

<a id="triggers_info_files"></a>
#### info-files

The info-files trigger is responsible for registering and unregistering the GNU info
files of a package.

It checks the existence of the info files presented to it and if it is running under
another architecture.

During installation it uses `install-info` to register info files into
`usr/share/info`.

During removal it uses `install-info --delete` to remove the info files from the
registry located at `usr/share/info`.

If it is running under another architecture it tries to use the host's `install-info`
utility.

<a id="triggers_initramfs_regenerate"></a>
### initramfs-regenerate

The initramfs-regenerate trigger will trigger the regeneration of all kernel
initramfs images after package installation or removal. The trigger must be
manually requested.

This hook is probably most useful for DKMS packages because it will provide a
means to include newly compiled kernel modules in initramfs images for all
currently available kernels. When used in a DKMS package, it is recommended to
manually include the `dkms` trigger *before* the `initramfs-regenerate` trigger
using, for example,

    ```
    triggers="dkms initramfs-regenerate"
    ```

Although `xbps-src` will automatically include the `dkms` trigger whenever
`dkms_modules` is installed, the automatic addition will come *after*
`initramfs-regenerate`, which will cause initramfs images to be recreated
before the modules are compiled.

By default, the trigger uses `dracut --regenerate-all` to recreate initramfs
images. If `/etc/default/initramfs-regenerate` exists and defines
`INITRAMFS_GENERATOR=mkinitcpio`, the trigger will instead use `mkinitcpio` and
loop over all kernel versions for which modules appear to be installed.
Alternatively, setting `INITRAMFS_GENERATOR=none` will disable image
regeneration entirely.

<a id="triggers_kernel_hooks"></a>
#### kernel-hooks

The kernel-hooks trigger is responsible for running scripts during installation/removal
of kernel packages.

The available targets are pre-install, pre-remove, post-install and post-remove.

When run it will try to run all executables found under `etc/kernel.d/$TARGET`. The
`TARGET` variable is one of the 4 targets available for the trigger. It will also
create the directory if it isn't present.

During updates it won't try to run any executables when running with the pre-remove
target.

It is automatically added if the helper variable `kernel_hooks_version` is defined.
However it is not obligatory to have it defined.

<a id="triggers_mimedb"></a>
#### mimedb

The mimedb trigger is responsible for updating the shared-mime-info database.

In all runs it will just execute `update-mime-database -n usr/share/mime`.

It is automatically added to packages that have `/usr/share/mime` available as
a directory.

<a id="triggers_mkdirs"></a>
#### mkdirs

The mkdirs trigger is responsible for creating and removing directories dictated
by the `make_dirs` variable.

During installation it takes the `make_dirs` variable and splits it into groups of
4 variables.

- dir = full path to the directory
- mode = Unix permissions for the directory
- uid = name of the owning user
- gid = name of the owning group

It will continue to split the values of `make_dirs` into groups of 4 until the values
end.

During installation it will create a directory with `dir` then set mode with `mode`
and permission with `uid:gid`.

During removal it will delete the directory using `rmdir`.

To include this trigger use the `make_dirs` variable, as the trigger won't do anything
unless it is defined.

<a id="triggers_openjdk_profile"></a>
#### openjdk-profile

The openjdk-profile trigger is responsible for creating an entry in /etc/profile.d that
sets the `JAVA_HOME` environment variable to the currently-selected alternative for
`/usr/bin/java` on installation. This trigger must be manually requested.

<a id="triggers_pango_module"></a>
#### pango-modules

The pango-modules trigger is currently being removed since upstream has removed the
code responsible for it.

It used to update the pango modules file with `pango-modulesquery` during installation
of any package.

Currently it removes `etc/pango/pango.modules` file during removal of the pango package.

It can be added by defining `pango-modules` in the `triggers` variable and has no way to get
added automatically to a package.

<a id="triggers_pycompile"></a>
#### pycompile

The pycompile trigger is responsible for compiling python code into native
bytecode and removing generated bytecode.

During installation it will compile all python code under the paths it is given by
`pycompile_dirs` and all modules described in `pycompile_module` into native bytecode and
update the ldconfig(8) cache.

During removal it will remove all the native bytecode and update the ldconfig(8) cache.

To include this trigger use the variables `pycompile_dirs` and `pycompile_module`. The
trigger won't do anything unless at least one of those variables is defined.

A `python_version` variable can be set to direct behaviour of the trigger.

<a id="triggers_register_shell"></a>
#### register-shell

The register-shell trigger is responsible for registering and removing shell entries
into `etc/shells`.

During installation it will append the `etc/shells` file with the new shell and also
change the permissions to `644` on the file.

During removal it will use `sed` to delete the shell from the file.

To include this trigger use the `register_shell` variable, as the trigger won't do
anything unless it is defined.

<a id="triggers_system_accounts"></a>
#### system-accounts

The system-accounts trigger is responsible for creating and disabling system accounts
and groups.

During removal it will disable the account by setting the Shell to /bin/false,
Home to /var/empty, and appending ' - for uninstalled package $pkgname' to the
Description.
Example: `transmission unprivileged user - for uninstalled package transmission`

This trigger can only be used by using the `system_accounts` variable.

<a id="triggers_texmf_dist"></a>
#### texmf-dist

The texmf-dist trigger is responsible for regenerating TeXLive's texmf databases.

During both installation and removal, it regenerates both the texhash and format
databases using `texhash` and `fmtutil-sys`, to add or remove any new hashes or
formats.

It runs on every package that changes /usr/share/texmf-dist. This is likely overkill,
but it is much cleaner rather than checking each format directory and each directory
that is hashed. In addition, it is very likely any package touching /usr/share/texmf-dist
requires one of these triggers anyway.

<a id="triggers_update_desktopdb"></a>
#### update-desktopdb

The update-desktopdb trigger is responsible for updating the system's MIME database.

During installation it will execute `update-desktop-database usr/share/applications`
which will result in a cache file being created at `usr/share/applications/mimeinfo.cache`.

During removal of the `desktop-file-utils` package it will remove the cache file that
was created during installation.

It is automatically added to packages that have `/usr/share/applications` available as
a directory.

<a id="triggers_x11_fonts"></a>
#### x11-fonts

The x11-fonts trigger is responsible for rebuilding the fonts.dir and fonts.scale files
for packages that install X11 fonts, and update fontconfig's cache for these fonts.

During installation and removal it executes `mkfontdir`, `mkfontscale` and `fc-cache` for
all font directories it was given via the `font_dirs` variable.

To include this trigger use the `font_dirs` variable, as the trigger won't do anything
unless it is defined.

<a id="triggers_xml_catalog"></a>
#### xml-catalog

The xml-catalog trigger is responsible for registering and removing SGML/XML catalog entries.

During installation it uses `xmlcatmgr` to register all catalogs, passed to it by the
`sgml_entries` and `xml_entries` variables, in `usr/share/sgml/catalog` and
`usr/share/xml/catalog` respectively.

During removal it uses `xmlcatmgr` to remove all catalogs passed to it by the
`sgml_entries` and `xml_entries` variables, in `usr/share/sgml/catalog` and
`usr/share/xml/catalog` respectively.

To include this trigger use the `sgml_entries` variable or/and the `xml_entries` variable,
as the trigger won't do anything unless either of them are defined.

<a id="documentation"></a>
### Void specific documentation

When you want document details of package's configuration and usage specific to Void Linux,
not covered by upstream documentation, put notes into
`srcpkgs/<pkgname>/files/README.voidlinux` and install with
`vdoc "${FILESDIR}/README.voidlinux"`.

<a id="notes"></a>
### Notes

- Make sure that all software is configured to use the `/usr` prefix.

- Binaries should always be installed at `/usr/bin`.

- Manual pages should always be installed at `/usr/share/man`.

- If a software provides **shared libraries** and headers, probably you should
create a `development package` that contains `headers`, `static libraries`
and other files required for development (not required at runtime).

- If you are updating a package please be careful with SONAME bumps, check
the installed files (`./xbps-src show-files pkg`) before pushing new updates.

- Make sure that binaries are not stripped by the software, let xbps-src do this;
otherwise the `debug` packages won't have debugging symbols.

<a id="contributing"></a>
### Contributing via git

To get started, [fork](https://help.github.com/articles/fork-a-repo) the void-linux `void-packages` git repository on GitHub and clone it:

    $ git clone git@github.com:<user>/void-packages.git

See [CONTRIBUTING.md](./CONTRIBUTING.md) for information on how to format your
commits and other tips for contributing.

Once you've made changes to your `forked` repository, submit
a github pull request.

To keep your forked repository always up to date, setup the `upstream` remote
to pull in new changes:

    $ git remote add upstream https://github.com/void-linux/void-packages.git
    $ git pull --rebase upstream master

<a id="help"></a>
## Help

If after reading this `manual` you still need some kind of help, please join
us at `#xbps` via IRC at `irc.libera.chat`.
