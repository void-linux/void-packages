/*-
 * Copyright (c) 2008 Juan Romero Pardines.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <limits.h>

#include <xbps_api.h>

static void
write_plist_file(prop_dictionary_t dict, const char *file)
{
	assert(dict != NULL || file != NULL);

	if (!prop_dictionary_externalize_to_file(dict, file)) {
		prop_object_release(dict);
		printf("=> ERROR: couldn't write to %s (%s)",
		    file, strerror(errno));
		exit(1);
	}
}

static void
usage(void)
{
	printf("usage: xbps-pkgdb <action> [args]\n\n"
	"  Available actions:\n"
	"    register, sanitize-plist, unregister, version\n"
	"  Action arguments:\n"
	"    register\t[<pkgname> <version> <shortdesc>]\n"
	"    sanitize-plist\t[<plist>]\n"
	"    unregister\t[<pkgname> <version>]\n"
	"    version\t[<pkgname>]\n"
	"  Environment:\n"
	"    XBPS_META_PATH\tPath to xbps metadata root directory\n\n"
	"  Examples:\n"
	"    $ xbps-pkgdb register pkgname 2.0 \"A short description\"\n"
	"    $ xbps-pkgdb sanitize-plist /blah/foo.plist\n"
	"    $ xbps-pkgdb unregister pkgname 2.0\n"
	"    $ xbps-pkgdb version pkgname\n");
	exit(1);
}

int
main(int argc, char **argv)
{
	prop_dictionary_t dbdict = NULL, pkgdict;
	const char *version;
	char dbfile[PATH_MAX], *in_chroot_env;
	bool in_chroot = false;
	int rv = 0;

	if (argc < 2)
		usage();

	if (!xbps_append_full_path(dbfile, NULL, XBPS_REGPKGDB)) {
		printf("=> ERROR: couldn't find regpkdb file (%s)\n",
		    strerror(errno));
		exit(EINVAL);
	}

	in_chroot_env = getenv("in_chroot");
	if (in_chroot_env != NULL)
		in_chroot = true;

	if (strcasecmp(argv[1], "register") == 0) {
		/* Registers a package into the database */
		if (argc != 5)
			usage();

		rv = xbps_register_pkg(argv[2], argv[3], argv[4]);
		if (rv == EEXIST) {
			printf("%s=> %s-%s already registered.\n",
			    in_chroot ? "[chroot] " : "", argv[2], argv[3]);
		} else if (rv != 0) {
			printf("%s=> couldn't register %s-%s (%s).\n",
			    in_chroot ? "[chroot] " : "" , argv[2], argv[3],
			    strerror(rv));
		} else {
			printf("%s=> %s-%s registered successfully.\n",
			    in_chroot ? "[chroot] " : "", argv[2], argv[3]);
		}

	} else if (strcasecmp(argv[1], "unregister") == 0) {
		/* Unregisters a package from the database */
		if (argc != 4)
			usage();

		if (!xbps_remove_pkg_dict_from_file(argv[2], dbfile)) {
			if (errno == ENODEV)
				printf("=> ERROR: %s not registered "
				    "in database.\n", argv[2]);
			else
				printf("=> ERROR: couldn't unregister %s "
				    "from database (%s)\n", argv[2],
				    strerror(errno));
			exit(EINVAL);
		}

		printf("%s=> %s-%s unregistered successfully.\n",
		    in_chroot ? "[chroot] " : "", argv[2], argv[3]);

	} else if (strcasecmp(argv[1], "version") == 0) {
		/* Prints version of an installed package */
		if (argc != 3)
			usage();

		pkgdict = xbps_find_pkg_in_dict(
			prop_dictionary_internalize_from_file(dbfile), argv[2]);
		if (pkgdict == NULL)
			exit(1);
		if (!prop_dictionary_get_cstring_nocopy(pkgdict, "version",
		    &version))
			exit(1);
		printf("%s\n", version);

	} else if (strcasecmp(argv[1], "sanitize-plist") == 0) {
		/* Sanitize a plist file (indent the file properly) */
		if (argc != 3)
			usage();

		dbdict = prop_dictionary_internalize_from_file(argv[2]);
		if (dbdict == NULL) {
			printf("=> ERROR: couldn't sanitize %s plist file "
			    "(%s)\n", argv[2], strerror(errno));
			exit(1);
		}
		write_plist_file(dbdict, argv[2]);

	} else {
		usage();
	}

	exit(0);
}
