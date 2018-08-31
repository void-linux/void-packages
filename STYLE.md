style(7)

# NAME

**style**  - xbps-src template file style guide

# DESCRIPTION

This file specifies the preferred style for files used by xbps-src, the ports system used by Void Linux.

These guidelines should be followed for all new submissions. Old non-compliant
templates should be made to conform when modified.

This manual assumes knowledge of what templates are, how they work and what
they are for.

# STYLE

## HEADER

Templates **always** start with a header

```
# Template file for '<pkgname>'
```
	
If your package requires another package to have version synchrony a comment
can be added below the header.

```
# Requires version and revision synchrony with '<pkgname>'
```
	
## VARIABLES

Immediately after the header the variables begin, it is required that **pkgname**,
**version** then **revision** start the template unless **reverts** is used,
which must come between **pkgname** and **version**.

```
pkgname=foo
reverts="1.0.1_1"
version=1.0.0
revision=1
```

if **archs** is used, it should come after **revision**.

if applicable **wrksrc** and **build_wrksrc** come right after **revision** and
*archs*, then **build_style** and **build_helper**.

Variables that are related to a build_style like **go_import_path**,
**configure_args**, **make_install_target** must come directly after it.

Afterwards come the dependencies, ordered as:

1. hostmakedepends
2. makedepends
3. depends
4. checkdepends

```
hostmakedepends="automake gettext-devel glib-devel gobject-introspection gtk-doc
 gtk-update-icon-cache pkg-config $(vopt_if wayland 'wayland-devel
 wayland-protocols')"
makedepends="at-spi2-atk-devel gdk-pixbuf-devel libepoxy-devel pango-devel
 $(vopt_if colord 'colord-devel') $(vopt_if cups 'cups-devel')
 $(vopt_if wayland 'libxkbcommon-devel wayland-devel wayland-protocols
 libwayland-egl MesaLib-devel') $(vopt_if x11 'libXcursor-devel libXdamage-devel
 libXext-devel libXinerama-devel libXi-devel libXrandr-devel
 libXcomposite-devel')"
depends="gtk-update-icon-cache shared-mime-info $(vopt_if x11 'dbus-x11')"
```

After the dependencies comes **short_desc**. Start it with an uppercase
character, don't pass over 72 chars or use an article at the beginning.

```
# Wrong!
# Superfluous usage of A
short_desc="A configuration language guaranteed to terminate"
# Correct!
short_desc="Configuration language guaranteed to terminate"
```

**maintainer** follows. It uses a **name <email>** scheme, name and email must
match the git equivalents used to commit. The email must be usable for contact
and not try to be obscured.

```
# Wrong! (Email not reachable)
maintainer="maxice8 <maxice8@github.noreply.com>"
# Wrong! (Doesn't follow the scheme, missing <>)
maintainer="maxice8 thinkabit.ukim@gmail.com"
# Wrong! (Email obscured)
maintainer="maxice8 <thinkabit.ukimATgmailDOTcom>"
# Correct
maintainer="maxice8 <thinkabit.ukim@gmail.com>"
```

Then there is **license** which should be specified according to the SPDX
short-identifier. If multiple licenses apply then they should all be listed
and each one be separated by a comma and a space.

```
# Wrong!
# GPL-2 isn't a SPDX short-identifier
# there is no proper separation between the licenses
license="GPL-2 MPL-2.0"
# Correct!
license="LGPL-2.1-or-later, Apache-2.0"
```

**homepage**, **changelog** and **distfiles** follow, if multiple distfiles are
present then they should be broken with a newline, the same applies to
**checksum**.

```
homepage="https://foosoft.com"
changelog="https://foosoft.com/dist/foo/changelog.txt"
distfiles="https://foosoft.com/dist/foo/${version}.tar.xz
 https://foosoft.com/dist/bar/${version}.tar.xz"
```

Variables that are knobs to functionality and are not specific to a
**build_style** should come at the end of the variables section.

The same applies for variables that take structured values like **conf_files**.
There is no specific ordering for such variables. but it is preferred that
multi-line versions of **conf_files** and other variables that are prone to
requiring multiple lines like **make_dirs** should be at the end, with a blank
space separating them from the other variables.

When using **nopie**, **nocross** and **broken** make the value be something
descriptive, if no other description is available, a build log showcasing the
failure is acceptable.

```
broken="Segfaults at runtime"
nocross="Tries to execute binary built for target on host"
```

If **alternatives** is used it should be the last line, if there are multiple
alternatives presented then they should be 1 on each line, prefixed with
whitespace.

```
checksum=blablablablablablablablablabla

alternatives="foo:foo:usr/bin/foo
 foo:bar:usr/bin/bar"
```

Variables that are not used by _xbps-src_ need to be prefixed with
an underscore.

## QUOTING

Some rules of thumb to follow when quoting variables:

- Don't quote variables that cannot contain spaces. i.e: **pkgname**
- Quote when there is a strong chance the variable contain spaces
- Quote when a subshell is being run or a variable is being expanded

> When expanding variables, put it in brackets.

**pkgname** and **version** must **never** be quoted.

Here is a list of variables that should **never** be quoted:

- pkgname
- version
- revision
- build_style
- configure_script
- make_cmd
- make_build_target
- make_check_target
- make_install_target
- disable_parallel_build
- keep_libtool_archives
- nodebug
- repository
- nostrip
- noshlibprovides
- noverifyrdeps
- restricted
- nopie
- bootstrap
- create_wrksrc

Here is a list of variables that should be quoted in a specific condition:

- archs
	- If the value isn't **noarch**
- wrksrc
	- If the value contain spaces or variable expansion
- build_wrksrc
	- If the value contain spaces or variable expansion
- checksum
	- If there is more than 1 value

Here is a list of variables that should always be quoted:

- reverts
- build_helper
- configure_args
- make_build_args
- make_check_args
- make_install_args
- patch_args
- hostmakedepends
- makedepends
- depends
- checkdepends
- short_desc
- maintainer
- license
- homepage
- distfiles
- skip_extraction
- conf_files
- mutable_files
- make_dirs
- nostrip_files
- skiprdeps
- nocross
- subpackages
- broken
- shlib_provides
- shlib_requires
- alternatives
- font_dirs
- dkms_modules
- register_shell
- tags
- perl_configure_dirs
- preserve
- fetch_cmd
- conflicts

## CONTROL STRUCTURES

Control structures are conditionals provided by the shell to
control the flow of execution of the template. Examples:

```
# if statement
if [ "$CROSS_BUILD" ]; then
	hostmakedepends+=" python3"
fi
```

```
# case statement
case "$XBPS_TARGET_MACHINE" in
	x86_64) ;;
	i686*) broken="Requires 128bit integers" ;;
esac
```

```
# for loops
for f in examples/*.conf; do
	vsconf $f
done
```

```
# while loops
cat ../debian/patches/series | while read p; do
	patch -p1 -i ../debian/patches/$p
done
```

Control structures must start after the variables, with 1 blank line separating
them. There should be 1 blank separating each occurrence of a control structure.

When manipulating variables inside the control structures be sure to use _bash_
append feature so the variable doesn't override the global declaration, unkess
of course that is what is meant.

```
# Wrong!
# space between ] and ;
if [ -n "$CROSS_BUILD" ] ; then
	hostmakedepends+=" glib-devel"
fi

# Wrong!
# then keyword should be on the same line
if [ -n "$CROSS_BUILD" ]
then
	hostmakedepends+=" glib-devel"
fi

# Correct!
if [ "$CROSS_BUILD" ]; then
	hostmakedepends+=" glib-devel"
fi
```

## BUILD PHASES

Then comes the build phases which are function declarations. They should have
1 hard tab of identation inside them and must follow the same spacing rules
as control structures.

The order of the build phases respects the order of operations done by
_xbps-src_, the ordering for a specific build phase is:

1. pre_<phase>
2. do_<phase>
3. post_<phase>

And the ordering of all operations are:

1. fetch
2. extract
3. patch
4. configure
5. build
6. check
7. install
8. pkg

## SUBPACKAGES

The last section for the template covers the subpackages declarations which are
functions that are declared as **<subpkgname>\_package()**, the same spacing and
indentation rules of build phases apply here.

## EXTRA GUIDELINES

Create variables to replace long repetitive values, do not do so when replacing
something only once.

Do not guard **build phases** and **subpackages** functions behind **control
structures**. Declare them in the root of the template and have the
**control structure** inside. Even if the function is otherwise empty.

When breaking a line inside a variable, indent it with 1 space.

Prefer native _bash_ functions like variable substitution to shelling
out to external tools.

## UPDATING MARKDOWN

This document is written in SirCmpwn's scdoc and then transformed into
a suitable manpage. The scdoc file is also suitable for use as a markdown file.

This document is written in scdoc and used as a markdown file on GitHub, it is
also transformed into roff to be used as a manpage and is shipped as part of
base-files as _style.7_.

To generate the roff file from the scdoc file.

```
# Replace all occurrences of numbered lists for Markdown with scdoc equivalent
$ sed 's|^[0-9].*\.|.|g ; s|\*\*|*|g' STYLE.md | scdoc > style.7
```

## AUTHORS

maxice8 \<thinkabit.ukim@gmail.com\>
