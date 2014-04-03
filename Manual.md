# The XBPS source packages manual

This article contains an exhaustive manual of how to create new source
packages for XBPS, the `Void Linux` native packaging system.

## Introduction

The `xbps-packages` repository contains all `source` packages that are the
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
in a directory matching `$pkgname`, i.e: `xbps-packages/srcpkgs/foo/template`.

If everything went fine after running

    $ xbps-src build-pkg
    
a binary package named `foo-1.0_1.<arch>.xbps` will be generated in the local repository
`<masterdir>/host/binpkgs`.



### Package build phases

Building a package consist of the following phases:

- `setup` This phase prepares the environment for building a package.

- `fetch` This phase downloads required sources for a `source package`, as defined by
the `distfiles` variable or `do_fetch()` function.

- `extract` This phase extracts the `distfiles` files into `$wrksrc` or executes the `do_extract()`
function, which is the directory to be used to compile the `source package`.

- `configure` This phase executes the `configuration` of a `source package`, i.e `GNU configure scripts`.

- `build` This phase compiles/prepares the `source files` via `make` or any other compatible method.

- `install` This phase installs the `package files` into a `fake destdir`,
via `make install` or any other compatible method.

- `pkg` This phase builds the `binary packages` with files stored in the
`package destdir` and registers them into the local repository.

`xbps-src` supports running just the specified phase, and if it ran
successfully, the phase will be skipped later (unless its work directory
`${wrksrc}` is removed with `xbps-src clean`).

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

> Shell wildcards must be properly quoted, i.e `vmove "usr/lib/*.a"`.

### Global variables

The following variables are defined by `xbps-src` and can be used on any template:

- `makejobs` Set to `-jX` if `XBPS_MAKEJOBS` is defined, to allow parallel jobs with `GNU make`.

- `sourcepkg`  Set to the to main package name, can be used to match the main package
rather than additional binary package names.

- `CHROOT_READY`  True if the target chroot (masterdir) is ready for chroot builds.

- `CROSS_BUILD` True if `xbps-src` is cross compiling a package.

- `DESTDIR` Full path to the fake destdir used by the source pkg, set to
`${XBPS_MASTERDIR}/destdir/${sourcepkg}-${version}`.

- `FILESDIR` Full path to the `files` package directory, i.e `srcpkgs/foo/files`.
The `files` directory can be used to store additional files to be installed
as part of the source package.

- `PKGDESTDIR` Full path to the fake destdir used by the `pkg_install()` function in
`subpackages`, set to `${XBPS_MASTERDIR}/destdir/${pkgname}-${version}`.

- `XBPS_BUILDDIR` Directory to store the `source code` of the source package being processed,
set to `${XBPS_MASTERDIR}/destdir`. The package `wrksrc` is always stored
in this directory.

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

- `hostmakedepends` The list of `host` dependencies required to build the package. Dependencies
can be specified with the following version comparators: `<`, `>`, `<=`, `>=`
or `foo-1.0_1` to match an exact version. If version comparator is not
defined (just a package name), the version comparator is automatically set to `>=0`.
Example `hostmakedepends="foo blah<1.0"`.

- `makedepends` The list of `target` dependencies required to build the package. Dependencies
can be specified with the following version comparators: `<`, `>`, `<=`, `>=`
or `foo-1.0_1` to match an exact version. If version comparator is not
defined (just a package name), the version comparator is automatically set to `>=0`.
Example `makedepends="foo blah>=1.0"`.

- `depends` The list of dependencies required to run the package. Dependencies
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

- `force_debug_pkgs` If enabled binary packages with debugging symbols will be generated
even if `XBPS_DEBUG_PKGS` is disabled in `xbps-src.conf` or in the
`command line arguments`.

- `conf_files` A list of configuration files the binary package owns; this expects full
paths, and multiple entries can be separated by blanks, i.e:
`conf_files="/etc/foo.conf /etc/foo2.conf"`.

- `noarch` If set, the binary package is not architecture specific and can be shared
by all supported architectures.

- `nonfree` If set, the binary package will be put into the *non free* repository.

- `nostrip` If set, the ELF binaries with debugging symbols won't be stripped. By
default all binaries are stripped.

### build style scripts

The `build_style` variable specifies the build method to build and install a
package. It expects the name of any available script in the
`xbps-packages/common/build_style` directory. Please note that required packages
to execute a `build_style` script must be defined via `$hostmakedepends`.

The current list of available `build_style` scripts is the following:

- `cmake` For packages that use the CMake build system, configuration arguments
can be passed in via `configure_args`.

- `configure` For packages that use non-GNU configure scripts, at least `--prefix=/usr`
should be passed in via `configure_args`.

- `gnu-configure` For packages that use GNU configure scripts, additional configuration
arguments can be passed in via `configure_args`.

- `gnu-makefile` For packages that use GNU make, build arguments can be passed in via
`make_build_args` and install arguments via `make_install_args`. The build
target can be overriden via `make_build_target` and the install target
via `make_install_target`.

- `meta` For `meta-packages`, i.e packages that only install local files or simply
depend on additional packages. This build style does not install
dependencies to the root directory, and only checks if a binary package is
available in repositories.

- `perl-ModuleBuild` For packages that use the Perl
[Module::Build](http://search.cpan.org/~leont/Module-Build-0.4202/lib/Module/Build.pm) method.

- `perl` For packages that use the Perl
[ExtUtils::MakeMaker](http://perldoc.perl.org/ExtUtils/MakeMaker.html) build method.

- `python-module` For packages that use the Python module build method (setup.py).

- `waf3` For packages that use the Python3 `waf` build method with python3.

- `waf` For packages that use the Python `waf` method with python2.

> If `build_style` is not set, the template must (at least) define a
`do_install()` function and optionally more phases via `do_xxx()` functions.

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

- `pre_install()` ctions to execute after `post_build()`.

- `do_install()` Actions to execute to install the package files into the `fake destdir`.

- `post_install()` Actions to execute after `do_install()`.

> A function defined in a template has preference over the same function
defined by a `build_style` script.

### Build options

Some packages might be built with different build options to enable/disable
additional features; `xbps-src` allows you to do this with some simple tweaks
to the `template` file.

The following variables may be set to allow package build options:

- `build_options` Sets the build options supported by the source package.

- `build_options_default` Sets the default build options to be used by the source package.

- `desc_option_<option>` Sets the description for the build option `option`. This must match the
keyword set in *build_options*.

After defining those required variables, you can check for the
`build_option_<option>` variable to know if it has been set and adapt the source
package accordingly.

The following example shows how to change a source package that uses GNU
configure to enable a new build option to support PNG images:

```
# Template file for 'foo'
pkgname=foo
version=1.0
revision=1
build_style=gnu-configure
...

# Package build options
build_options="png"
desc_option_png="Enable support for PNG images"

# To build the package by default with the `png` option:
#
# build_options_default="png"

if [ "$build_option_png" ]; then
	configure_args+=" --with-png"
	makedepends+=" libpng-devel"
else
	configure_args+=" --without-png"
fi
...

```

The supported build options for a source package can be shown with xbps-src:

    $ xbps-src show-options foo

Build options can be enabled with the `-o` flag of xbps-src:

    $ xbps-src -o option,option1 foo

Build options can be disabled by prefixing them with `~`:

    $ xbps-src -o ~option,~option1 foo

Both ways can be used together to enable and/or disable multiple options
at the same time with xbps-src:

    $ xbps-src -o option,~option1,~option2 foo

The build options can also be shown for binary packages via `xbps-query(8)`:

    $ xbps-query -R --property=build-options foo

### Runtime dependencies

Dependencies for ELF objects are detected automatically by `xbps-src`, hence runtime
dependencies must not be specified in templates via `$depends` with the following exceptions:

- ELF objects using dlopen(3).
- non ELF objects, i.e perl/python/ruby/etc modules.
- Overriding the minimal version specified in the `shlibs` file.

The runtime dependencies for ELF objects are detected by checking which SONAMEs
they require and then the SONAMEs are mapped to a binary package name with a minimal
required version. The `shlibs` file in the `xbps-packages/common` directory
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
- A third optional field specifies the architecture (rarely used).

### Creating system accounts/groups at runtime

There's a trigger along with some variables that are specifically to create
**system users and groups** when the binary package is being configured.
The following variables can be used for this purpose:

- `system_groups` This specifies the names of the new *system groups* to be created, separated
by blanks. Optionally the **gid** can be specified by delimiting it with a
colon, i.e `system_groups="mygroup:78"` or `system_groups="foo blah:8000"`.

- `system_accounts` This specifies the names of the new **system users/groups** to be created,
separated by blanks, i.e `system_accounts="foo blah"`. Additional variables
for the **system accounts** can be specified to change its behavior:

	- `<account>_homedir` the home directory for the user. If unset defaults to `/`.
	- `<account>_shell` the shell for the new user. If unset defaults to `/sbin/nologin`.
	- `<account>_descr` the description for the new user. If unset defaults to `<user> unprivileged user`.
	- `<account>_groups` additional groups to be added to for the new user.

The **system user** is created by using a dynamically allocated **uid/gid** in your system
and it's created as a `system account`. A new group will be created for the
specified `system account` and used exclusived for this purpose.

### 32bit packages

32bit packages are built automatically when the builder is x86 (32bit), but
there are some variables that can change the behavior:

- `lib32depends` If this variable is set, dependencies listed here will be used rather than
those detected automatically by xbps-src and **depends**. Please note that
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

### Development packages

A development package, commonly generated as a subpackage, shall only contain
files required for development, that is, headers, static libraries, shared
library symlinks, pkg-config files, API documentation or any other script
that is only useful when developping for the target software.

A development package should depend on packages that are required to link
against the provided shared libraries, i.e if `libfoo` provides the
`libfoo.so.2` shared library and the linking needs `-lbar`, the package
providing the `libbar` shared library should be added as a dependency;
and most likely it shall depend on its development package.

If a development package provides a `pkg-config` file, you should verify
what dependencies the package needs for dynamic or static linking, and add
the appropiate `development` packages as dependencies.

### Notes

- Make sure that all software is configured to use the `/usr` prefix.

- Binaries should always be installed at `/usr/bin` and `/usr/sbin`.

- Manual pages should always be installed at `/usr/share/man` and
uncompressed.

- If a software provides **shared libraries** and headers, probably you should
create a `development package` that contains `headers`, `static libraries`
and other files required for development (not required at runtime).

- If you are updating a package please be careful with SONAME bumps, check
the installed files (`xbps-src show-files`) before pushing new updates.

### Contributing via git

Fork the voidlinux `xbps-packages` git repository on github and clone it:

    $ git clone git://github.com/<user>/xbps-packages.git

You can now make your own commits to the `forked` repository:

    $ git add ...
    $ git commit ...
    $ git push ...

To keep your forked repository always up to date, setup the `upstream` remote
to pull in new changes:

    $ git remote add upstream git://github.com/voidlinux/xbps-packages.git
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
