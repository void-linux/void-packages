## Generating self-hosted rust and cargo bootstrap distfiles

Rust doesn't ship binaries for some of the targets we support bootstrapping on,
so we have to generate distfiles for a few architectures as well, namely
`ppc64le-musl` and `ppc64` for `rust-bootstrap`, and additionally `ppc` for
`cargo-bootstrap`, as the `ppc` cargo binaries provided by upstream have
problems.

Note: Void no longer officially supports PowerPC platforms,
this guide is kept for historical reasons as well as for future reference.

### Set up appropriate masterdirs and remote-repositories

This guide assumes you're on an x86\_64 machine. If you're not, please adapt the
appropriate sections.

First, we bootstrap our masterdirs. We need both a glibc one and a musl one:

```
$ ./xbps-src -m masterdir-glibc binary-bootstrap x86_64
$ ./xbps-src -m masterdir-musl binary-bootstrap x86_64-musl
```

In addition to those, we need to set up binary remotes for the ppc repos. As
they aren't officially maintained by Voidlinux, they aren't included in this
repo, but you can include them locally by creating these three files:

- `etc/xbps.d/repos-remote-ppc.conf`, with
  `repository=https://repo.voidlinux-ppc.org/current/ppc` in it.
- `etc/xbps.d/repos-remote-ppc64.conf`, with
  `repository=https://repo.voidlinux-ppc.org/current/be` in it.
- `etc/xbps.d/repos-remote-ppc64le-musl.conf`, with
  `repository=https://repo.voidlinux-ppc.org/current/musl` in it.

### Bootstrapping on your native architecture

Assuming you've already adjusted the version and checksums for the distfiles
provided by upstream, we can now start building rust for our native
architecture, with both glibc and musl. Run this for both masterdirs
bootstrapped above

```
$ ./xbps-src -m <masterdir> pkg cargo
```

This builds `rust-bootstrap`, `cargo-bootstrap`, `rust` and `cargo` for your
native architecture, which we will need for the next step.

### Crosscompiling for the target architectures and generating distfiles

Now that we have the our native architecture covered, we cross build for the
architectures we need to generate distfiles for:

```
$ ./xbps-src -m <masterdir> -a <arch> pkg -o bindist rust
$ ./xbps-src -m <masterdir> -a <arch> pkg rust
$ ./xbps-src -m <masterdir> -a <arch> pkg -o bindist cargo
```

Repeat these three steps for `masterdir-glibc` with `ppc`, `masterdir-musl` with
`ppc64le-musl` and `masterdir-glibc` with `ppc64`. In the case of `ppc`, you can
skip the `bindist` build for rust, as we are taking those from upstream.

Now that we have run those commands, the generated distfiles are available in
`hostdir/sources/distfiles`. Generate a `sha256sum` for each of those files, and
set the hashes in the appropriate places in the `rust-bootstrap` and
`cargo-bootstrap` templates. If you want to verify you did things correctly, you
can copy the generated distfiles over into `hostdir/sources/rust-bootstrap-${version}`
and `hostdir/sources/cargo-bootstrap-${version}`, and try cross-building the
bootstrap packages for those architectures.
