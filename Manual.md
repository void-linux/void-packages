# The XBPS source packages manual

This article contains an exhaustive manual of how to create new source
packages for XBPS, the `Void Linux` native packaging system.

## Introduction

The `void-packages` repository contains all `source` packages that are the
recipes to download, compile and build binary packages for `Void`.
Those `source` package files are called `templates`.

The `template files` are `GNU bash` shell scripts that must define some required/optional
`variables` and `functions` that are processed by `xbps-src` (the package builder)
to generate the resulting binary packages.

A simple `template` example is as follows:

```
# Template file for 'foo'

pkgname="foo"
version="1.0"
revision=1
build_style=gnu-configure
short_desc="A short description max 72 chars"
maintainer="name <email>"
license="GPL-3"
homepage="http://www.foo.org"
distfiles="http://www.foo.org/foo-${version}.tar.gz"
checksum="fea0a94d4b605894f3e2d5572e3f96e4413bcad3a085aae7367c2cf07908b2ff"
```

The template file contains definitions to download, build and install the
package files to a `fake destdir`, and after this a binary package can be
generated with the definitions specified on it.

Don't worry if anything is not clear as it should be. The reserved `variables`
and `functions` will be explained later. This `template` file should be created
in a directory matching `$pkgname`, i.e: `void-packages/srcpkgs/foo/template`.

If everything went fine after running

    $ ./xbps-src pkg <pkgname>
    
a binary package named `foo-1.0_1.<arch>.xbps` will be generated in the local repository
`hostdir/binpkgs`.

### Package build phases

Building a package consist of the following phases:

- `setup` This phase prepares the environment for building a package.

- `fetch` This phase downloads required sources for a `source package`, as defined by
the `distfiles` variable or `do_fetch()` function.

- `extract` This phase extracts the `distfiles` files into `$wrksrc` or executes the `do_extract()`
function, which is the directory to be used to compile the `source package`.

- `configure` This phase executes the `configuration` of a `source package`, i.e `GNU configure scripts`.

- `build` This phase compiles/prepares the `source files` via `make` or any other compatible method.

- `install` This phase installs the `package files` into the package destdir `<masterdir>/destdir/<pkgname>-<version>`,
via `make install` or any other compatible method.

- `pkg` This phase builds the `binary packages` with files stored in the
`package destdir` and registers them into the local repository.

- `clean` This phase cleans up the package (if defined).

`xbps-src` supports running just the specified phase, and if it ran
successfully, the phase will be skipped later (unless its work directory
`${wrksrc}` is removed with `xbps-src clean`).

### Package naming conventions

#### Libraries

Libraries are packages which provide shared objects (\*.so) in /usr/lib.
They should be named like their upstream package name with the following
exceptions:

- The package is a subpackage of a front end application providing and provides
shared objects used by the base package and other third party libraries. In that
case it should be prefixed with 'lib'. An exception from that rule is: If an
executable is only used for building that package, it moves to the -devel
package.

Example: wireshark -> subpkg libwireshark

Libraries have to be split into two sub packages: <name> and <name>-devel.

- `<name>` should only contain those parts of a package which are needed to run
a linked program.

- `<name>-devel` should contain all files which are needed to compile a package
against this package. If the library is a sub package, its corresponding
development package should be named `lib<name>-devel`

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

Example: python-pam, perl-URI, python-pyside

#### Language Bindings

Language Bindings are packages which allow programs or libraries to have
extensions or plugins written in a certian language.

The naming convention to those packages is:
```
<name>-<language>
```

Example: gimp-python, irssi-perl

#### Programs

Programs put executables under /usr/bin (or in very special cases in other
.../bin directories)

For those packages the upstream packages name should be used. Remember that
in contrast to many other distributions, void doesn't lowercase package names.
As a rule of thumb, if the tar.gz of a package contains uppercase letter, then
the package name should contain them too; if it doesn't, the package name
is lowercase.

Programs can be split into program packages and library packages. The program
package should be named as describe above. The library package should be prefix
with "lib" (see section `Libraries`)

### Global functions

The following functions are defined by `xbps-src` and can be used on any template:

- *vinstall()* `vinstall <file> <mode> <targetdir> [<name>]`

	Installs `file` with the specified `mode` into `targetdir` into the pkg `$DESTDIR`
The optional 4th argument can be used to change the `file name`.

- *vcopy()* `vcopy <pattern> <targetdir>`

	Copies resursively all files in `pattern` to `targetdir` into the pkg `$DESTDIR`

- *vmove()* `vmove <pattern>`

	Moves `pattern` to the specified directory in the pkg `$DESTDIR`

- *vmkdir()* `vmkdir <directory> [<mode>]`

	Creates a directory in the pkg `$DESTDIR`. The 2nd optional argument sets the mode of the directory.

- *vbin()* `vbin <file> [<name>]`

	Installs `file` into `usr/bin` in the pkg `$DESTDIR` with the
	permissions 0755. The optional 2nd argument can be used to change
	the `file name`.

- *vman()* `vman <file> [<name>]`

	Installs `file` as a man page. `vman()` parses the name and
	determines the section as well as localization. Example mappings:

	`foo.1` -> `${DESTDIR}/usr/share/man/man1/foo.1`  
	`foo.fr.1` -> `${DESTDIR}/usr/share/man/fr/man1/foo.1`  
	`foo.1p` -> `${DESTDIR}/usr/share/man/man1/foo.1p`  

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

- *vlicense()* `vlicense <file> [<name>]`

	Installs `file` into `usr/share/licenses/<pkgname>` in the pkg
	`$DESTDIR`. The optional 2nd argument can be used to change the
	`file name`.

- *vsv()* `vsv <service>`

	Installs `service` from `${FILESDIR}` to /etc/sv. The service must
	be a directory containing at least a run script. Note the `supervise`
	symlink will be created automatically by `vsv`.
	For further informations on how to create a new service directory see
	[The corresponding section the FAQ](http://smarden.org/runit/faq.html#create).

> Shell wildcards must be properly quoted, i.e `vmove "usr/lib/*.a"`.

### Global variables

The following variables are defined by `xbps-src` and can be used on any template:

- `makejobs` Set to `-jX` if `XBPS_MAKEJOBS` is defined, to allow parallel jobs with `GNU make`.

- `sourcepkg`  Set to the to main package name, can be used to match the main package
rather than additional binary package names.

- `CHROOT_READY`  Set if the target chroot (masterdir) is ready for chroot builds.

- `CROSS_BUILD` Set if `xbps-src` is cross compiling a package.

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

- `XBPS_MACHINE` The machine architecture as returned by `uname -m`.

- `XBPS_SRCDISTDIR` Full path to where the `source distfiles` are stored, i.e `$XBPS_HOSTDIR/sources`.

- `XBPS_SRCPKGDIR` Full path to the `srcpkgs` directory.

- `XBPS_TARGET_MACHINE` The target machine architecture when cross compiling a package.

- `XBPS_FETCH_CMD` The utility to fetch files from `ftp`, `http` of `https` servers.

### Available variables

#### Mandatory variables

The list of mandatory variables for a template:

- `homepage` A string pointing to the `upstream` homepage.

- `license` A string matching any license file available in `/usr/share/licenses`.
Multiple licenses should be separated by commas, i.e `GPL-3, LGPL-2.1`.

- `maintainer` A string in the form of `name <user@domain>`.

- `pkgname` A string with the package name, matching `srcpkgs/<pkgname>`.

- `revision` A number that must be set to 1 when the `source package` is created, or
updated to a new `upstream version`. This should only be increased when
the generated `binary packages` have been modified.

- `short_desc` A string with a brief description for this package. Max 72 chars.

- `version` A string with the package version. Must not contain dashes and at least
one digit is required.


#### Optional variables

- `hostmakedepends` The list of `host` dependencies required to build the package, and
that will be installed to the master directory. Dependencies
can be specified with the following version comparators: `<`, `>`, `<=`, `>=`
or `foo-1.0_1` to match an exact version. If version comparator is not
defined (just a package name), the version comparator is automatically set to `>=0`.
Example `hostmakedepends="foo blah<1.0"`.

- `makedepends` The list of `target` dependencies required to build the package, and that
will be installed to the master directory. Dependencies
can be specified with the following version comparators: `<`, `>`, `<=`, `>=`
or `foo-1.0_1` to match an exact version. If version comparator is not
defined (just a package name), the version comparator is automatically set to `>=0`.
Example `makedepends="foo blah>=1.0"`.

- `depends` The list of dependencies required to run the package. These dependencies
are not installed to the master directory, rather are only checked if a binary package
in the local repository exists to satisfy the required version. Dependencies
can be specified with the following version comparators: `<`, `>`, `<=`, `>=`
or `foo-1.0_1` to match an exact version. If version comparator is not
defined (just a package name), the version comparator is automatically set to `>=0`.
Example `depends="foo blah>=1.0"`. See the `Runtime dependencies` section for more information.

- `bootstrap` If enabled the source package is considered to be part of the `bootstrap`
process and required to be able to build packages in the chroot. Only a
small number of packages must set this property.

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
  | CPAN_SITE        | http://cpan.perl.org/modules/by-module          |
  | DEBIAN_SITE      | http://ftp.debian.org/debian/pool               |
  | FREEDESKTOP_SITE | http://freedesktop.org/software                 |
  | GNOME_SITE       | http://ftp.gnome.org/pub/GNOME/sources          |
  | GNU_SITE         | http://mirrors.kernel.org/gnu                   |
  | KERNEL_SITE      | http://www.kernel.org/pub/linux                 |
  | MOZILLA_SITE     | http://ftp.mozilla.org/pub/mozilla.org          |
  | NONGNU_SITE      | http://download.savannah.nongnu.org/releases    |
  | PYPI_SITE        | http://pypi.python.org/packages/source          |
  | SOURCEFORGE_SITE | http://downloads.sourceforge.net/sourceforge    |
  | UBUNTU_SITE      | http://archive.ubuntu.com/ubuntu/pool           |
  | XORG_HOME        | http://xorg.freedesktop.org/wiki/               |
  | XORG_SITE        | http://xorg.freedesktop.org/releases/individual |

- `checksum` The `sha256` digests matching `${distfiles}`. Multiple files can be
separated by blanks. Please note that the order must be the same than
was used in `${distfiles}`. Example `checksum="kkas00xjkjas"`

- `wrksrc` The directory name where the package sources are extracted, by default
set to `${pkgname}-${version}`.

- `build_wrksrc` A directory relative to `${wrksrc}` that will be used when building the package.

- `create_wrksrc` Enable it to create the `${wrksrc}` directory. Required if a package
contains multiple `distfiles`.

- `only_for_archs` This expects a separated list of architectures where the package can be
built matching `uname -m` output. Example `only_for_archs="x86_64 armv6l"`

- `build_style` This specifies the `build method` for a package. Read below to know more
about the available package `build methods`. If `build_style` is not set,
the package must define at least a `do_install()` function, and optionally
more build phases as such `do_configure()`, `do_build()`, etc.

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
`${build_style}` is set to `configure`, `gnu-configure` or `gnu_makefile`
build methods. Unset by default.

- `make_install_args` The arguments to be passed in to `${make_cmd}` at the `install-destdir`
phase if `${build_style}` is set to `configure`, `gnu-configure` or
`gnu_makefile` build methods. By default set to
`PREFIX=/usr DESTDIR=${DESTDIR}`.

- `make_build_target` The target to be passed in to `${make_cmd}` at the build phase if
`${build_style}` is set to `configure`, `gnu-configure` or `gnu_makefile`
build methods. Unset by default (`all` target).

- `make_install_target` The target to be passed in to `${make_cmd}` at the `install-destdir` phase
if `${build_style}` is set to `configure`, `gnu-configure` or `gnu_makefile`
build methods. By default set to `install`.

- `patch_args` The arguments to be passed in to the `patch(1)` command when applying
patches to the package sources after `do_extract()`. Patches are stored in
`srcpkgs/<pkgname>/patches` and must be in `-p0` format. By default set to `-Np0`.

- `disable_parallel_build` If set the package won't be built in parallel
and `XBPS_MAKEJOBS` has no effect.

- `keep_libtool_archives` If enabled the `GNU Libtool` archives won't be removed. By default those
files are always removed automatically.

- `skip_extraction` A list of filenames that should not be extracted in the `extract` phase.
This must match the basename of any url defined in `${distfiles}`.
Example `skip_extraction="foo-${version}.tar.gz"`.

- `nodebug` If enabled -dbg packages won't be generated even if `XBPS_DEBUG_PKGS` is set.

- `force_debug_pkgs` If enabled binary packages with debugging symbols will be generated
even if `XBPS_DEBUG_PKGS` is disabled in `void-packages/etc/conf` or in the
`command line arguments`.

- `conf_files` A list of configuration files the binary package owns; this expects full
paths, and multiple entries can be separated by blanks, i.e:
`conf_files="/etc/foo.conf /etc/foo2.conf"`.

- `noarch` If set, the binary package is not architecture specific and can be shared
by all supported architectures.

- `repository` Defines the repository in which the package will be placed. See
  *Repositories* for a list of valid repositories.

- `nostrip` If set, the ELF binaries with debugging symbols won't be stripped. By
default all binaries are stripped.

- `noshlibprovides` If set, the ELF binaries won't be inspected to collect the provided
sonames in shared libraries.

- `nocross` If set, cross compilation won't be allowed and will exit immediately.

- `python_versions` A white space seperated list of python versions which will
be used to build that package. This is only used by the `python-module` build style.

- `subpackages` A white space separated list of subpackages (matching `foo_package()`)
to override the guessed list. Only use this if a specific order of subpackages is required,
otherwise the default would work in most cases.

- `broken` If set, building the package won't be allowed because its state is currently broken.

- `shlib_provides` A white space separated list of additional sonames the package provides on.
This appends to the generated file rather than replacing it.

- `shlib_requires` A white space separated list of additional sonames the package requires.
This appends to the generated file rather than replacing it.

- `reverts` xbps supports a unique feature which allows to downgrade from broken
packages automatically. In the `reverts` field one can define a list of broken
pkgver the resulting package should revert. This field *must* be defined before
`version` and `revision` fields in order to work as expected. The versions
defined in `reverts` must be lesser than the one defined in `version`.
example: `reverts="2.0_1 2.0_2"`

#### Repositories

##### Repositories defined by Branch

The global repository takes the name of
the current branch, except if the name of the branch is master. Then the resulting
repository will be at the global scope. The usage scenario is that the user can
update multiple packages in a second branch without polluting his local repository.

##### Package defined Repositories

The second way to define a repository is by setting the `repository` variable in
a template. This way the maintainer can define repositories for a specific
package or a group of packages. This is currently used to distinguish between
closed source packages, which are put in the `nonfree` repository and other
packages which are at the root-repository.

The following repository names are valid:

* `nonfree`: Repository for closed source packages.

#### Checking for new upstream releases

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

### build style scripts

The `build_style` variable specifies the build method to build and install a
package. It expects the name of any available script in the
`void-packages/common/build-style` directory. Please note that required packages
to execute a `build_style` script must be defined via `$hostmakedepends`.

The current list of available `build_style` scripts is the following:

- `cmake` For packages that use the CMake build system, configuration arguments
can be passed in via `configure_args`.

- `configure` For packages that use non-GNU configure scripts, at least `--prefix=/usr`
should be passed in via `configure_args`.

- `fetch` For packages that only fetch files and are installed as is via `do_install()`.

- `gnu-configure` For packages that use GNU configure scripts, additional configuration
arguments can be passed in via `configure_args`.

- `gnu-makefile` For packages that use GNU make, build arguments can be passed in via
`make_build_args` and install arguments via `make_install_args`. The build
target can be overriden via `make_build_target` and the install target
via `make_install_target`.

- `go` For programs written in Go that follow the standard package
  structure. The variable `go_import_path` must be set to the package's
  import path, e.g. `github.com/github/hub` for the `hub` program. If
  the variable `go_get` is set to `yes`, the package will be
  downloaded with `go get`. Otherwise (the default) it's expected that
  the distfile contains the package. In both cases, dependencies will
  be downloaded with `go get`.

- `meta` For `meta-packages`, i.e packages that only install local files or simply
depend on additional packages. This build style does not install
dependencies to the root directory, and only checks if a binary package is
available in repositories.

- `ruby-module` For packages that are ruby modules and are installable via `ruby install.rb`.
Additional install arguments can be specified via `make_install_args`.

- `perl-ModuleBuild` For packages that use the Perl
[Module::Build](http://search.cpan.org/~leont/Module-Build-0.4202/lib/Module/Build.pm) method.

- `perl` For packages that use the Perl
[ExtUtils::MakeMaker](http://perldoc.perl.org/ExtUtils/MakeMaker.html) build method.

- `python-module` For packages that use the Python module build method (setup.py).
By default the module will be built for python2. The `python_versions` variable may
be defined to set the allowed python versions to be built, i.e:
`python_versions="2.7 3.3"`.

- `waf3` For packages that use the Python3 `waf` build method with python3.

- `waf` For packages that use the Python `waf` method with python2.

> If `build_style` is not set, the template must (at least) define a
`do_install()` function and optionally more phases via `do_xxx()` functions.

Environment variables for a specific `build_style` can be declared in a filename
matching the `build_style` name, i.e:

    `common/environment/build-style/gnu-configure.sh`

### Functions

The following functions can be defined to change the behavior of how the
package is downloaded, compiled and installed.

- `do_fetch()` if defined and `distfiles` is not set, use it to fetch the required sources.

- `do_extract()` if defined and `distfiles` is not set, use it to extract the required sources.

- `post_extract()` Actions to execute after `do_extract()`.

- `pre_configure()` Actions to execute after `post_extract()`.

- `do_configure()` Actions to execute to configure the package; `${configure_args}` should
still be passed in if it's a GNU configure script.

- `post_configure()` Actions to execute after `do_configure()`.

- `pre_build()` Actions to execute after `post_configure()`.

- `do_build()` Actions to execute to build the package.

- `post_build()` Actions to execute after `do_build()`.

- `pre_install()` Actions to execute after `post_build()`.

- `do_install()` Actions to execute to install the package files into the `fake destdir`.

- `post_install()` Actions to execute after `do_install()`.

- `do_clean()` Actions to execute to clean up after a successful package phase.

> A function defined in a template has preference over the same function
defined by a `build_style` script.

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

    $ ./xbps-src -o option,option1 foo

Build options can be disabled by prefixing them with `~`:

    $ ./xbps-src -o ~option,~option1 foo

Both ways can be used together to enable and/or disable multiple options
at the same time with `xbps-src`:

    $ ./xbps-src -o option,~option1,~option2 foo

The build options can also be shown for binary packages via `xbps-query(8)`:

    $ xbps-query -R --property=build-options foo

Permanent global package build options can be set via `XBPS_PKG_OPTIONS` variable in the
`etc/conf` configuration file. Per package build options can be set via
`XBPS_PKG_OPTIONS_<pkgname>`.

> NOTE: if `pkgname` contains `dashes`, those should be replaced by `underscores`
i.e `XBPS_PKG_OPTIONS_xorg_server=opt`.

The list of supported package build options and its description is defined in the
`common/options.description` file.

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

There's a special variant of how `virtual` dependencies can be specified as `runtime dependencies`
and is by using the `virtual?` keyword, i.e `depends="virtual?vpkg-0.1_1"`. This declares
a `runtime` virtual dependency to `vpkg-0.1_1`; this `virtual` dependency will be simply ignored
when the package is being built with `xbps-src`.

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

### INSTALL.msg and REMOVE.msg files

The `INSTALL.msg` and `REMOVE.msg` files can be used to print a message at post-install
or pre-remove time, respectively.

Ideally those files should not exceed 80 chars per line.

subpackages can also have their own `INSTALL.msg` and `REMOVE.msg` files, simply create them
as `srcpkgs/<pkgname>/<subpkg>.INSTALL.msg` or `srcpkgs/<pkgname>/<subpkg>.REMOVE.msg` respectively.

### Creating system accounts/groups at runtime

There's a trigger along with some variables that are specifically to create
**system users and groups** when the binary package is being configured.
The following variables can be used for this purpose:

- `system_groups` This specifies the names of the new *system groups* to be created, separated
by blanks. Optionally the **gid** can be specified by delimiting it with a
colon, i.e `system_groups="mygroup:78"` or `system_groups="foo blah:8000"`.

- `system_accounts` This specifies the names of the new **system users/groups** to be created,
separated by blanks, i.e `system_accounts="foo blah:22"`. Optionally the **uid** and **gid**
can be specified by delimiting it with a color, i.e `system_accounts="foo:48"`.
Additional variables for the **system accounts** can be specified to change its behavior:

	- `<account>_homedir` the home directory for the user. If unset defaults to `/dev/null`.
	- `<account>_shell` the shell for the new user. If unset defaults to `/sbin/nologin`.
	- `<account>_descr` the description for the new user. If unset defaults to `<account> unprivileged user`.
	- `<account>_groups` additional groups to be added to for the new user.
	- `<account>_pgroup` to set the primary group, by default primary group is set to `<account>`.

The **system user** is created by using a dynamically allocated **uid/gid** in your system
and it's created as a `system account`, unless the **uid** is set. A new group will be created for the
specified `system account` and used exclusived for this purpose.

### 32bit packages

32bit packages are built automatically when the builder is x86 (32bit), but
there are some variables that can change the behavior:

- `lib32depends` If this variable is set, dependencies listed here will be used rather than
those detected automatically by `xbps-src` and **depends**. Please note that
dependencies must be specified with version comparators, i.e
`lib32depends="foo>=0 blah<2.0"`.

- `lib32disabled` If this variable is set, no 32bit package will be built.

- `lib32files` Additional files to be added to the **32bit** package. This expect absolute
paths separated by blanks, i.e `lib32files="/usr/bin/blah /usr/include/blah."`.

- `lib32mode` If unset, only shared libraries and pkg-config files will be copied to the
**32bit** package. If set to `full` all files will be copied as is.

### Subpackages

In the example shown above just a binary package is generated, but with some
simple tweaks multiple binary packages can be generated from a single
template/build, this is called `subpackages`.

To create additional `subpackages` the `template` must define a new function
with this naming: `<subpkgname>_package()`, i.e:

```
# Template file for 'foo'

pkgname="foo"
version="1.0"
revision=1
build_style=gnu-configure
short_desc="A short description max 72 chars"
maintainer="name <email>"
license="GPL-3"
homepage="http://www.foo.org"
distfiles="http://www.foo.org/foo-${version}.tar.gz"
checksum="fea0a94d4b605894f3e2d5572e3f96e4413bcad3a085aae7367c2cf07908b2ff"

# foo-devel is a subpkg
foo-devel_package() {
	short_desc+=" - development files"
	depends="${sourcepkg}>=${version}_${revision}"
	pkg_install() {
		vmove usr/include
		vmove usr/lib/*.a
		vmove usr/lib/*.so
		vmove usr/lib/pkgconfig
	}
}
```

All subpackages need an additional symlink to the `main` pkg, otherwise dependencies
requiring those packages won't find its `template` i.e:

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
the appropiate `development` packages as dependencies.

### Python packages

Python packages should be built with the `python-module` build style, if possible. This sets
some environment variables required to allow cross compilation. Support to allow building
a python module for multiple versions from a single template is also possible.

To allow cross compilation, the `python-devel` package (for python 2.7) must be added
to `hostmakedepends` and `makedepends`. If any other python version is also supported,
for example python3.4, those must also be added as host and target build dependencies.

The following variables may influence how the python packages are built and configured
at post-install time:

- `python_versions`: this variable expects the python versions supported by the module.
By default it's always set to `2.7`. If a package for another python version is wanted
you can set all acceptable versions, i.e `python_versions="2.7 3.4"` will build a package
for `python (2.7)` and `python3.4`.

- `pycompile_version`: this variable expects the python version that is used to
byte-compile the python code (it generates the `.py[co]` files at post-install time).
By default it's set to `2.7` for `python 2.x` packages.

- `pycompile_module`: this variable expects the python modules that should be `byte-compiled`
at post-install time. Python modules are those that are installed into the `site-packages`
prefix: `usr/lib/pythonX.X/site-packages`. Multiple python modules may be specified separated
by blanks, i.e `pycompile_module="foo blah"`.

- `pycompile_dirs`: this variable expects the python directories that should be `byte-compiled`
recusively by the target python version. This differs from `pycompile_module` in that any
path may be specified, i.e `pycompile_dirs="usr/share/foo"`.

> NOTE: it's expected that additional subpkgs must be generated to allow packaging for multiple
python versions.

### Go packages

Go packages should be built with the `go` build style, if possible.
The `go` build style takes care of downloading Go dependencies and
setting up cross compilation.

The following variables influence how Go packages are built:

- `go_import_path`: The import path of the package, as it would be
  used with `go get`. For example, GitHub's `hub` program has the
  import path `github.com/github/hub`. This variable is required.
- `go_get`: If set to yes, the package specified via `go_import_path`
  will be downloaded with `go get`. Otherwise, a distfile has to be
  provided. This option should only be used with `-git` (or similar)
  packages; using a versioned distfile is prefered.

### Notes

- Make sure that all software is configured to use the `/usr` prefix.

- Binaries should always be installed at `/usr/bin` and `/usr/sbin`.

- Manual pages should always be installed at `/usr/share/man`.

- If a software provides **shared libraries** and headers, probably you should
create a `development package` that contains `headers`, `static libraries`
and other files required for development (not required at runtime).

- If you are updating a package please be careful with SONAME bumps, check
the installed files (`./xbps-src show-files pkg`) before pushing new updates.

- Make sure that binaries are not stripped by the software, let xbps-src do this;
otherwise the `debug` packages won't have debugging symbols.

### Contributing via git

Fork the voidlinux `void-packages` git repository on github and clone it:

    $ git clone git@github.com:<user>/void-packages.git

You can now make your own commits to the `forked` repository:

    $ git add ...
    $ git commit ...
    $ git push ...

To keep your forked repository always up to date, setup the `upstream` remote
to pull in new changes:

    $ git remote add upstream git://github.com/voidlinux/void-packages.git
    $ git pull upstream master

Once you've made changes to your `forked` repository you can submit
a github pull request; see https://help.github.com/articles/fork-a-repo for more information.

For commit messages please use the following rules:

- If you've imported a new package use `"New package: <pkgver>"`.
- If you've updated a package use `"<pkgname>: updated to <version>"`.
- If you've removed a package use `"<pkgname>: removed ..."`.
- If you've modified a package use `"<pkgname>: ..."`.

## Help

If after reading this `manual` you still need some kind of help, please join
us at `#xbps` via IRC at `irc.freenode.net`.
