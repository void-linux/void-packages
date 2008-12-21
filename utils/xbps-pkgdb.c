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

#include "xbps_api.h"

typedef struct pkg_data {
	const char *pkgname;
	const char *version;
	const char *short_desc;
} pkg_data_t;

static prop_dictionary_t make_dict_from_pkg(pkg_data_t *);
static void register_pkg(prop_dictionary_t, pkg_data_t *, const char *);
static void write_plist_file(prop_dictionary_t, const char *);

static prop_dictionary_t
make_dict_from_pkg(pkg_data_t *pkg)
{
	prop_dictionary_t dict;

	assert(pkg != NULL || pkg->pkgname != NULL);
	assert(pkg->version != NULL || pkg->short_desc != NULL);

	dict = prop_dictionary_create();
	assert(dict != NULL);

	prop_dictionary_set_cstring_nocopy(dict, "pkgname", pkg->pkgname);
	prop_dictionary_set_cstring_nocopy(dict, "version", pkg->version);
	prop_dictionary_set_cstring_nocopy(dict, "short_desc", pkg->short_desc);

	return dict;
}

static void
register_pkg(prop_dictionary_t dict, pkg_data_t *pkg, const char *dbfile)
{
	prop_dictionary_t pkgdict;
	prop_array_t array;

	assert(dict != NULL || pkg != NULL || dbfile != NULL);
	pkgdict = make_dict_from_pkg(pkg);
	assert(pkgdict != NULL);
	array = prop_dictionary_get(dict, "packages");
	assert(array != NULL);
	assert(prop_object_type(array) == PROP_TYPE_ARRAY);

	if (!xbps_add_obj_to_array(array, pkgdict)) {
		printf("ERROR: couldn't register '%s-%s' in database!\n",
		    pkg->pkgname, pkg->version);
		exit(1);
	}

	write_plist_file(dict, dbfile);
}

static void
write_plist_file(prop_dictionary_t dict, const char *file)
{
	assert(dict != NULL || file != NULL);

	if (!prop_dictionary_externalize_to_file(dict, file)) {
		prop_object_release(dict);
		perror("=> ERROR: couldn't write to database file");
		exit(1);
	}
}

static void
usage(void)
{
	printf("usage: xbps-pkgdb <action> [args]\n\n"
	"  Available actions:\n"
	"    list, register, sanitize-plist, unregister, version\n"
	"  Action arguments:\n"
	"    list\t[none]\n"
	"    register\t[<pkgname> <version> <shortdesc>]\n"
	"    sanitize-plist\t[<plist>]\n"
	"    unregister\t[<pkgname> <version>]\n"
	"    version\t[<pkgname>]\n"
	"  Environment:\n"
	"    XBPS_REGPKGDB_PATH\tPath to xbps pkgdb plist file\n\n"
	"  Examples:\n"
	"    $ xbps-pkgdb list\n"
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
	prop_array_t dbarray = NULL;
	pkg_data_t pkg;
	const char *version;
	char dbfile[PATH_MAX], *dbfileenv, *tmppath, *in_chroot_env;
	bool in_chroot = false;

	if (argc < 2)
		usage();

	if ((dbfileenv = getenv("XBPS_REGPKGDB_PATH")) != NULL) {
		/* Use path as defined by XBPS_REGPKGDB_PATH env var */
		tmppath = strncpy(dbfile, dbfileenv, sizeof(dbfile) - 1);
		if (sizeof(*tmppath) >= sizeof(dbfile))
			exit(1);
	} else {
		/* Use default path */
		tmppath =
		    strncpy(dbfile, XBPS_REGPKGDB_DEFPATH, sizeof(dbfile) - 1);
		if (sizeof(*tmppath) >= sizeof(dbfile))
			exit(1);
	}
	/* nul terminate string */
	dbfile[sizeof(dbfile) - 1] = '\0';

	in_chroot_env = getenv("in_chroot");
	if (in_chroot_env != NULL)
		in_chroot = true;

	if (strcasecmp(argv[1], "register") == 0) {
		/* Registers a package into the database */
		if (argc != 5)
			usage();

		dbdict = prop_dictionary_internalize_from_file(dbfile);
		if (dbdict == NULL) {
			/* Create package dictionary and add its objects. */
			pkg.pkgname = argv[2];
			pkg.version = argv[3];
			pkg.short_desc = argv[4];
			pkgdict = make_dict_from_pkg(&pkg);
			assert(pkgdict != NULL);

			/* Add pkg dictionary into array. */
			dbarray = prop_array_create();
			if (!xbps_add_obj_to_array(dbarray, pkgdict)) {
				printf("=> ERROR: couldn't register %s-%s\n",
				    pkg.pkgname, pkg.version);
				exit(1);
			}

			/* Add array into main dictionary. */
			dbdict = prop_dictionary_create();
			if (!xbps_add_obj_to_dict(dbdict, dbarray,
			    "packages")) {
				printf("=> ERROR: couldn't register %s-%s\n",
				    pkg.pkgname, pkg.version);
				exit(1);
			}

			/* Write main dictionary to file. */
			write_plist_file(dbdict, dbfile);

			printf("%s==> Package database file not found, "
			    "creating it.\n", in_chroot ? "[chroot] " : "");

			prop_object_release(dbdict);
		} else {
			/* Check if pkg is already registered. */
			pkgdict = xbps_find_pkg_in_dict(dbdict, argv[2]);
			if (pkgdict != NULL) {
				printf("%s=> Package %s-%s already registered.\n",
				    in_chroot ? "[chroot] " : "",
				    argv[2], argv[3]);
				exit(0);
			}
			pkg.pkgname = argv[2];
			pkg.version = argv[3];
			pkg.short_desc = argv[4];

			register_pkg(dbdict, &pkg, dbfile);
		}

		printf("%s=> %s-%s registered successfully.\n",
		    in_chroot ? "[chroot] " : "", argv[2], argv[3]);

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

	} else if (strcasecmp(argv[1], "list") == 0) {
		/* Lists packages currently registered in database */
		if (argc != 2)
			usage();

		dbdict = prop_dictionary_internalize_from_file(dbfile);
		if (!xbps_callback_array_iter_in_dict(dbdict,
		    "packages", xbps_list_pkgs_in_dict, NULL))
			exit(EINVAL);

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
			printf("=> ERROR: couldn't sanitize %s plist file\n",
			    argv[2]);
			exit(1);
		}
		if (!prop_dictionary_externalize_to_file(dbdict, argv[2])) {
			printf("=> ERROR: couldn't write new plist file "
			    "(%s)\n", strerror(errno));
			exit(1);
		}

	} else {
		usage();
	}

	exit(0);
}
