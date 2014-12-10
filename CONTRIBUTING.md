# Contributing to void-packages

void-packages is the backbone of the Void Linux distribution. It contains all definitions how packages are built from source.

This document describes how you as a contributor can help adding packages, correcting bugs and adding features to void-packages.

## Packages

There are several ways to contribute packages to Void Linux:

### "You lazy bastard" or Package requests

Package requests can be submitted in the form of [issues](https://github.com/voidlinux/void-packages/issues).
Please use `Package Request: <pkgname>` as title when sending such a request and include at least an URL to
the homepage of the software project.

Please note that we do not guarantee that we will fulfill your request.

### Getting your packages into Void by yourself

If you really want to get a package into Void Linux we recommend you to package it yourself.
We provide a [comprehensive Manual](https://github.com/voidlinux/void-packages/blob/master/Manual.md)
on how you can create new packages. Also there's a
[manual about xbps-src](https://github.com/voidlinux/void-packages/blob/master/README.md) which is used
to build package files from templates.

For this guide, we assume you have basic knowledge about [git](http://git-scm.org) and a [GitHub Account](http://github.com)

#### Creating a new template

templates must be placed in `void-packages/srcpkgs/<pkgname>/template` where `pkgname` is the same as the pkgname variable in the template.

For deeper insights on the contents of template files consider reading the [manual](https://github.com/voidlinux/void-packages/blob/master/Manual.md)

There's a helper tool for creating new packages in the [xtools](https://github.com/chneukirchen/xtools) package:
```
xnew pkgname subpkg1 subpkg2 ...
```

#### Committing your changes

Once you have built your template files there are certian rules on how the commit should be named.

* Use the following for newly added packages: `New package: <pkgname>-<version>`
  Example: https://github.com/voidlinux/void-packages/commit/176d9655429188aac10cd229827f99b72982ab10

* Use the following if you update a package: '<pkgname>: update to <version>.'
  Example: https://github.com/voidlinux/void-packages/commit/b6b82dcbd4aeea5fc37a32e4b6a8dd8bd980d5a3

* If you changed something on the template without a version change use '<pkgname>: <reason>'
  Example: https://github.com/voidlinux/void-packages/commit/8b68d6bf1eb997cd5e7c095acd040e2c5379c91d

If you want to describe your changes in more detail, make an empty line and add the description afterwards.
Example: https://github.com/voidlinux/void-packages/commit/f1c45a502086ba1952f23ace9084a870ce437bc6

This is also described in the [manual](https://github.com/voidlinux/void-packages/blob/master/Manual.md) in deeper detail.


There's a helper tool for comitting packages in the [xtools](https://github.com/chneukirchen/xtools) package:
```
xbump <pkgname>
```

#### Starting a pull request

Once you successfully build the package at least on x86 (building it on armv* is recommended too) you can start a pull request.

Most pull request should only contain a single package and it's dependencies which are not part of void-packages yet.

If you make updates to packages containing a soname bump you also need to revbump all packages that are dependant. Those
packages should also be part of the same pull request.

##### Travis

Once you have started a pull request, you will get instant feedback from Travis. It will check if the templates you have changed
comply with the our guidelines. At the moment not all packages comply to the rules, so if you update a package, it may happen, that Travis
reports errors on places you haven't touched. So feel free to fix those errors too.

You are encouraged to check your templates beforehand using the helper from the [xtools](https://github.com/chneukirchen/xtools) package:
```
xlint template
```

##### Review

GitHub reports new pull request at our IRC-Channel, so the reviewers will be instantly informed. Most of the time
your pull request will contain mistakes. It's nothing bad, it just happens.

The reviewers will comment your pull request and point out which changes are needed before the template can be included.

##### Closing the pull request

Once you have applied all comments, the reviewers will merge your request.

If the pull request gets inactive for some days, the reviews may or may not warn you when they are about to close it.
If it stays inactive further, it'll be closed.

Please abstain from temporary closing a pull request while revising the templates. Only close your pull request if
you're sure you don't want your changes to be included.

##### Publishing the package

Once the reviewers have merged the pullrequest, our [build server](http://build.voidlinux.eu) is automaticly triggered and builds
all packages from this pull request for all supported platforms. Once it is finished, the packages are available to all Void Linux users.

