# Contributing to void-packages

void-packages is the backbone of the Void Linux distribution. It contains all the definitions to build packages from source.

This document describes how you, as a contributor, can help with adding packages, correcting bugs and adding features to void-packages.

## Getting your packages into Void by yourself

If you really want to get a package into Void Linux, we recommend you package it yourself.

We provide a [comprehensive Manual](./Manual.md) on how to create new packages.
There's also a [manual for xbps-src](./README.md), which is used
to build package files from templates.

For this guide, we assume you have basic knowledge about [git](http://git-scm.org), as well as a [GitHub Account](http://github.com).

To get started, [fork](https://help.github.com/articles/fork-a-repo) the void-linux `void-packages` git repository on GitHub and clone it:

    $ git clone git@github.com:<user>/void-packages.git

To keep your forked repository up to date, setup the `upstream` remote to pull in new changes:

    $ git remote add upstream https://github.com/void-linux/void-packages.git
    $ git pull --rebase upstream master

### Creating a new template

You can use the helper tool `xnew`, from the [xtools](https://github.com/chneukirchen/xtools) package, to create new templates:

    $ xnew pkgname subpkg1 subpkg2 ...

Templates must have the name `void-packages/srcpkgs/<pkgname>/template`, where `pkgname` is the same as the `pkgname` variable in the template.

For deeper insights on the contents of template files, please read the [manual](./Manual.md), and be sure to browse the existing template files in the `srcpkgs` directory of this repository for concrete examples.

When you've finished working on the template file, please check it with `xlint` helper from the [xtools](https://github.com/chneukirchen/xtools) package:

    $ xlint template

If `xlint` reports any issues, resolve them before committing.

### Committing your changes

Once you have made and verified your changes to the package template and/or other files, make one commit per package (including all changes to its sub-packages). Each commit message should have one of the following formats:

* for new packages, use ```New package: <pkgname>-<version>``` ([example](https://github.com/void-linux/void-packages/commit/176d9655429188aac10cd229827f99b72982ab10)).

* for package updates, use ```<pkgname>: update to <version>.``` ([example](https://github.com/void-linux/void-packages/commit/b6b82dcbd4aeea5fc37a32e4b6a8dd8bd980d5a3)).

* for template modifications without a version change, use ```<pkgname>: <reason>``` ([example](https://github.com/void-linux/void-packages/commit/8b68d6bf1eb997cd5e7c095acd040e2c5379c91d)).

* for package removals, use ```<pkgname>: remove package``` ([example](https://github.com/void-linux/void-packages/commit/83784632d94deee5d038c8e1c4c1dffa922fca21)).

* for `common/shlibs` modifications, use `common/shlibs: <pkgname>` ([example](https://github.com/void-linux/void-packages/commit/613651c91811cb4fd2e1a6be701c87072d759a9f)).

If you want to describe your changes in more detail, add an empty line followed by those details ([example](https://github.com/void-linux/void-packages/commit/f1c45a502086ba1952f23ace9084a870ce437bc6)).

`xbump`, available in the [xtools](https://github.com/chneukirchen/xtools) package, can be used to commit a new or updated package:

    $ xbump <pkgname> <git commit options>

`xbump` will use `git commit` to commit the changes with the appropriate commit message. For more fine-grained control over the commit, specific options can be passed to `git commit` by adding them after the package name.

After committing your changes, please check that the package builds successfully. From the top level directory of your local copy of the `void-packages` repository, run:

    $ ./xbps-src pkg <pkgname>

Your package must build successfully for at least x86, but we recommend trying to build for armv* as well, e.g.:

    $ ./xbps-src -a armv7l pkg <pkgname>

Runtime testing of packages and building with the `-Q` flag or with `XBPS_CHECK_PKGS=yes` set in the environment or `etc/conf` are strongly encouraged.
New packages will not be accepted unless they have been runtime tested.

### Starting a pull request

Once you have successfully built the package, you can [create a pull request](https://docs.github.com/en/github/collaborating-with-issues-and-pull-requests/creating-a-pull-request). Pull requests are also known as PRs.

Most pull requests should only contain a single package and dependencies which are not part of void-packages yet.

If you make updates to packages containing a soname bump, you also need to update `common/shlibs` and revbump all packages that are dependant.
There should be a commit for each package revbump, and those commits should be part of the same pull request.

When you make changes to your pull request, please *do not close and reopen your pull request*. Instead, just [forcibly git push](#review), overwriting any old commits. Closing and opening your pull requests repeatedly spams the Void maintainers.

#### Continuous Integration

Pull requests are automatically submitted for Continuous Integration (CI) testing to ensure packages build and pass their tests (on native builds) on various combinations of C library and architecture.
Packages that take longer than 120 minutes or need more than 14G of storage to complete their build (for example, Firefox or the Linux kernel) will fail CI and should include `[ci skip]` in the PR title or body (the comment field when the PR is being opened) to avoid wasting CI builder time.
Use your best judgment on build times based on your local building experience. If you skip CI when submitting a PR, please build and cross-build for a variety of architectures locally, with both glibc and musl, and note your local results in PR comments.
Make sure to cover 64-bit and 32-bit architectures.

If you notice a failure in CI that didn't happen locally, that is likely because you didn't run tests locally.
Use `./xbps-src -Q pkg <package>` to do so.
Some tests won't work in the CI environment or at all, and their templates should encode this information using the `make_check` variable.

Continuous Integration will also check if the templates you have changed
comply with the our guidelines. At the moment not all packages comply with the rules, so if you update a package, it may report errors about places you haven't touched. Please feel free to fix those errors too.

#### Review

It's possible (and common) that a pull request will contain mistakes or reviewers will ask for additional tweaks.
Reviewers will comment on your pull request and point out which changes are needed before the pull request can be merged.

Most PRs will have a single commit, as seen [above](#committing-your-changes), so if you need to make changes to the commit and already have a pull request open, you can use the following commands:

    $ git add <file>
    $ git commit --amend
    $ git push -f

A more powerful way of modifying commits than using `git commit --amend` is with [git-rebase](https://git-scm.com/docs/git-rebase#_interactive_mode), which allows you to join, reorder, change description of past commits and more.

Alternatively, if there are issues with your git history, you can make another branch and push it to the existing PR:

    $ git checkout master -b <attempt2>
    $ # do changes anew
    $ git push -f <fork> <attempt2>:<branch-of-pr>

#### Closing the pull request

Once you have applied all requested changes, the reviewers will merge your request.

If the pull request becomes inactive for some days, the reviewers may or may not warn you when they are about to close it.
If it stays inactive further, it will be closed.

Please abstain from temporarily closing a pull request while revising the templates. Instead, leave a comment on the PR describing what still needs work, or add "[WIP]" to the PR title. Only close your pull request if you're sure you don't want your changes to be included.

#### Publishing the package

Once the reviewers have merged the pull request, our [build server](http://build.voidlinux.org) is automatically triggered and builds
all packages in the pull request for all supported platforms. Upon completion, the packages are available to all Void Linux users.
