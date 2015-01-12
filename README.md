## The XBPS source packages collection

This repository contains the XBPS source packages collection to build binary packages
for the Void Linux distribution.

The included `xbps-src` script will fetch and compile the sources, and install its
files into a `fake destdir` to generate XBPS binary packages that can be installed
or queried through the `xbps-install(8)` and `xbps-query(8)` utilities, respectively.

The `xbps-src` utility uses `xbps-uchroot(8)` to build packages in lightweight linux
`containers` through the use of `namespaces`, that means that processes and bind mounts
are isolated (among others).

### Requirements

- GNU bash
- xbps >= 0.43.1

A privileged group is required to be able to execute `xbps-uchroot(8)`, by default in void
it's the `xbuilder` group.

### Quick setup in Void

Add your user to the `xbuilder` group:

    # usermod -a -G xbuilder <user>

Clone the `void-packages` git repository, install the bootstrap packages:

```
$ git clone git://github.com/voidlinux/void-packages.git
$ cd void-packages
$ ./xbps-src binary-bootstrap
```

Type:

     $ ./xbps-src -h

to see all available targets/options and start building any available package
in the `srcpkgs` directory.

### Install the bootstrap packages

The `bootstrap` packages are a set of packages required to build any available source package in a container. There are two methods to install the `bootstrap`:

 - `bootstrap`: all bootstrap packages will be built from scratch.
 - `binary-bootstrap`: the bootstrap binary packages are downloaded via XBPS repositories.

If you don't want to waste your time building everything from scratch probably it's better to use `binary-bootstrap`.

### Configuration

The `etc/defaults.conf` file contains the possible settings that can be overrided
through the `etc/conf` configuration file for the `xbps-src` utility; if that file
does not exist, will try to read configuration settings from `~/.xbps-src.conf`.

If you want to customize default `CFLAGS`, `CXXFLAGS` and `LDFLAGS`, don't override
those defined in `etc/defaults.conf`, append to them instead via `etc/conf` i.e:

    $ echo 'XBPS_CFLAGS+=" your flags here "' >> etc/conf
    $ echo 'XBPS_LDFLAGS+=" your flags here "' >> etc/conf

#### Virtual packages

The `etc/defaults.virtual` file contains the default replacements for virtual packages,
used as dependencies in the source packages tree.

If you want to customize those replacements, copy `etc/defaults.virtual` to `etc/virtual`
and edit it accordingly to your needs.

### Directory tree

The following directory tree is used with a default configuration file:

         /void-packages
            |- common
            |- etc
            |- srcpkgs
            |  |- xbps
            |     |- template
            |
            |- hostdir
            |  |- binpkgs ...
            |  |- ccache-<arch> ...
            |  |- distcc-<arch> ...
            |  |- repocache ...
            |  |- sources ...
            |
            |- masterdir
            |  |- builddir -> ...
            |  |- destdir -> ...
            |  |- host -> bind mounted from <hostdir>
            |  |- void-packages -> bind mounted from <void-packages>


The description of these directories is as follows:

 - `masterdir`: master directory to be used as rootfs to build/install packages.
 - `builddir`: to unpack package source tarballs and where packages are built.
 - `destdir`: to install packages, aka **fake destdir**.
 - `hostdir/ccache-<arch>`: to store ccache data if the `XBPS_CCACHE` option is enabled.
 - `hostdir/distcc-<arch>`: to store distcc data if the `XBPS_DISTCC` option is enabled.
 - `hostdir/repocache`: to store binary packages from remote repositories.
 - `hostdir/sources`: to store package sources.
 - `hostdir/binpkgs`: local repository to store generated binary packages.

### Building packages

The simplest form of building package is accomplished by running the `pkg` target in `xbps-src`:

```
$ cd void-packages
$ ./xbps-src pkg <pkgname>
```

When the package and its required dependencies are built, the binary packages will be created
and registered in the default local repository at `hostdir/binpkgs`; the path to this local repository can be added to 
any xbps configuration file (see xbps.d(5)) or by explicitly appending them via cmdline, i.e:

    $ xbps-install --repository=/path/to/hostdir/binpkgs ...
    $ xbps-query --repository=/path/to/hostdir/binpkgs ...

> Currently xbps expects absolute path when using the `--repository` option. This has been
corrected in the 0.44 version.

By default **xbps-src** will try to resolve package dependencies in this order:

 - If dependency exists in the local repository, use it (`hostdir/binpkgs`).
 - If dependency exists in a remote repository, use it.
 - If dependency exists in a source package, use it.

It is possible to avoid using remote repositories completely by using the `-N` flag.

> The default local repository may contain multiple *sub-repositories*: `debug`, `multilib`, etc.

### Sharing and signing your local repositories

To share a local repository remotely it's mandatory to sign it and the binary packages
stored on it. This is accomplished with the `xbps-rindex(8)` utility.

First a RSA key must be created with `openssl(1)` or `ssh-keygen(8)`:

	$ openssl genrsa -des3 -out privkey.pem 4096

or

	$ ssh-keygen -t rsa -b 4096 -f privkey.pem

> Only RSA keys in PEM format are currently accepted by xbps.

Once the RSA private key is ready you can use it to sign the repository:

	$ xbps-rindex --sign --signedby "I'm Groot" --privkey privkey.pem $PWD/hostdir/binpkgs

> If --privkey is unset, it defaults to `~/.ssh/id_rsa`.

If the RSA key was protected with a passphrase you'll have to type it, or alternatively set
it via the `XBPS_PASSPHRASE` environment variable.

Once the binary packages have been signed, check the repository contains the appropiate `hex fingerprint`:

	$ xbps-query --repository=$PWD/hostdir/binpkgs -vL
	...

Each time a binary package is created, the repository must be signed as explained above with
the difference that only those new packages will be signed.

> It is not possible to sign a repository with multiple RSA keys.

### Rebuilding and overwriting existing local packages

If for whatever reason a package has been built and it is available in your local repository
and you have to rebuild it without bumping its `version` or `revision` fields, it is possible
to accomplish this task easily with `xbps-src`:

    $ ./xbps-src -f pkg xbps

Reinstalling this package in your target `rootdir` can be easily done too:

    $ xbps-install --repository=/path/to/local/repo -yff xbps-0.25_1

> Please note that the `package expression` must be properly defined to explicitly pick up
the package from the desired repository.

### Enabling distcc for distributed compilation

Setup the slaves (machines that will compile the code):

    # xbps-install -Sy distcc

Enable and start the `distccd` service:

    # ln -s /etc/sv/distccd /var/service

In the host (machine that executes xbps-src) enable the following settings in the `void-packages/etc/conf` file:

    XBPS_DISTCC=yes
    XBPS_DISTCC_HOSTS="192.168.2.101 192.168.2.102"

### Cross compiling packages for a target architecture

Currently `xbps-src` can cross build packages for some target architectures with a cross compiler. The supported target list is the following:

* i686          - for Linux i686 GNU.
* i686-musl     - for Linux i686 Musl libc.
* armv6hf       - for Linux ARMv6 EABI5 (LE Hard Float / GNU)
* armv6hf-musl  - for Linux ARMv6 EABI5 (LE Hard Float / Musl libc)
* armv7hf       - for Linux ARMv7 EABI5 (LE Hard Float / GNU)
* armv7hf-musl  - for Linux ARMv7 EABI5 (LE Hard Float / Musl libc)
* mips          - for Linux MIPS o32 (BE Soft Float / GNU)
* mipsel        - for Linux MIPS o32 (LE Soft Float / GNU)
* x86_64-musl   - for x86_64 Musl/Linux

If a source package has been adapted to be **cross buildable** `xbps-src` will automatically build the binary package(s) with a simple command:

    $ ./xbps-src -a <target> pkg <pkgname>

If the build for whatever reason fails, might be a new build issue or simply because it hasn't been adapted to be **cross compiled**.

### Using xbps-src in a foreign linux distribution

xbps-src can be used in any recent linux distribution matching the cpu architecture.

To use xbps-src in your linux distribution use the following instructions. Let's start downloading the xbps static binaries:

    $ wget http://repo.voidlinux.eu/static/xbps-static-latest.<arch>-musl.tar.xz
    $ mkdir ~/XBPS
    $ tar xvf xbps-static-latest.<arch>.tar.xz -C ~/XBPS
    $ export PATH=~/XBPS/usr/sbin:$PATH

A privileged group is required to be able to chroot with xbps-src, by default it's set to the `xbuilder` group, change this to your desired group:

    # chown root:<group> ~/XBPS/usr/sbin/xbps-uchroot.static
    # chmod 4750 ~/XBPS/usr/sbin/xbps-uchroot.static

Clone the `void-packages` git repository:

    $ git clone git://github.com/voidlinux/void-packages

and `xbps-src` should be fully functional; just start the `bootstrap` process, i.e:

    $ ./xbps-src binary-bootstrap

The default masterdir is created in the current working directory, i.e `void-packages/masterdir`.

### Remaking the masterdir

If for some reason you must update xbps-src and the `bootstrap-update` target is not enough, it's possible to recreate a masterdir with two simple commands (please note that `zap` keeps your `ccache/distcc/host` directories intact):

    $ ./xbps-src zap
    $ ./xbps-src binary-bootstrap

### Keeping your masterdir uptodate

Sometimes the bootstrap packages must be updated to the latest available version in repositories, this is accomplished with the `bootstrap-update` target:

    $ ./xbps-src bootstrap-update

### Building i686/32bit packages on x86_64

A new x86 `masterdir` must be created to build 32bit packages:

    $ ./xbps-src -m masterdir-x86 binary-bootstrap i686

Packages that are multilib only (32bit) must be built on a 32bit masterdir.

    $ ./xbps-src -m masterdir-x86 ...

#### Building packages natively for the musl C library

A native build environment is required to be able to cross compile the bootstrap packages for the musl C library; this is accomplished by installing them via `binary-bootstrap`:

    $ ./xbps-src binary-bootstrap

Now cross compile `base-chroot-musl` for your native architecture:

    $ ./xbps-src -a x86_64-musl pkg base-chroot-musl

Wait until all packages are built and when ready, prepare a new masterdir with the musl packages:

    $ ./xbps-src -m masterdir-x86_64-musl binary-bootstrap x86_64-musl

Your new masterdir is now ready to build natively packages for the musl C library. Try:

    $ ./xbps-src -m masterdir-x86_64-musl chroot
    $ ldd

To see if the musl C dynamic linker is working as expected.

### Contributing

See [Contributing](https://github.com/voidlinux/xbps-packages/blob/master/CONTRIBUTING.md)
for a general overview of how to contribute and the
[Manual](https://github.com/voidlinux/xbps-packages/blob/master/Manual.md)
for details of how to create source packages.
