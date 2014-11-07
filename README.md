[![Pullreq xlint](https://travis-ci.org/voidlinux/void-packages.svg?branch=master)](https://travis-ci.org/voidlinux/void-packages)

## The XBPS source packages collection

This repository contains the XBPS source packages collection to build binary packages
for the Void Linux distribution.

To start using it first you'll need some external dependencies:

- bash
- xbps >= 0.41

Make sure your user is added to the `xbuilder` group to be able to use `xbps-uchroot(8)`,
otherwise `xbps-src` won't work correctly.

Type:

     $ ./xbps-src -h

to see all available targets/options and start building any available package
in the `srcpkgs` directory.

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

### Contributing

See [Manual](https://github.com/voidlinux/xbps-packages/blob/master/Manual.md)
for documentation to create and learn about the source packages.
