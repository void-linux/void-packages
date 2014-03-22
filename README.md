## The XBPS packages collection

This repository contains the XBPS package collection to build binary packages
for the Void Linux distribution.

To start using it first you'll need some external dependencies:

- GNU make
- GNU bash
- C compiler
- fakeroot
- xbps >= 0.33

The `xbps-src` utility and its helpers must be built first:

     $ make

The `xbps-src` chroot helper required to chroot and setup the bind mounts must
be a setgid binary that can only be executed by a special group, by default `xbuilder`.
To set the appropiate permissions run the `setup` target:

     $ sudo make setup

After that you can run:

     $ ./xbps-src -h

to see all available targets/options and start building any available package
in the `srcpkgs` directory.

See [Manual](https://github.com/voidlinux/xbps-packages/blob/master/Manual.md)
for documentation to create and learn about the source packages.
