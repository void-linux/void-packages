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
static void unregister_pkg(prop_dictionary_t, const char *, const char *);
static void write_plist_file(prop_dictionary_t, const char *);

static prop_dictionary_t
make_dict_from_pkg(pkg_data_t *pkg)
{
	prop_dictionary_t dict;

	if (pkg == NULL || pkg->pkgname == NULL || pkg->version == NULL ||
	    pkg->short_desc == NULL)
		return NULL;

	dict = prop_dictionary_create();
	if (dict == NULL)
		return NULL;

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

	if (dict == NULL || pkg == NULL || dbfile == NULL) {
		printf("%s: NULL dict/pkg/dbfile\n", __func__);
		exit(1);
	}

	pkgdict = make_dict_from_pkg(pkg);
	if (pkgdict == NULL) {
		printf("%s: NULL pkgdict\n", __func__);
		exit(1);
	}

	array = prop_dictionary_get(dict, "packages_installed");
	if (array == NULL || prop_object_type(array) != PROP_TYPE_ARRAY) {
		printf("%s: NULL or incorrect array type\n", __func__);
		exit(1);
	}

	if (!xbps_add_obj_to_array(array, pkgdict)) {
		printf("ERROR: couldn't register package in database!\n");
		exit(1);
	}

	write_plist_file(dict, dbfile);
}

static void
unregister_pkg(prop_dictionary_t dict, const char *pkgname, const char *dbfile)
{
	prop_array_t array;
	prop_object_t obj;
	prop_object_iterator_t iter;
	const char *curpkgn;
	int i = 0;
	bool found = false;

	if (dict == NULL || pkgname == NULL) {
		printf("%s: NULL dict/pkgname\n", __func__);
		exit(1);
	}

	array = prop_dictionary_get(dict, "packages_installed");
	if (array == NULL || prop_object_type(array) != PROP_TYPE_ARRAY) {
		printf("%s: NULL or incorrect array type\n", __func__);
		exit(1);
	}

	iter = prop_array_iterator(array);
	if (iter == NULL) {
		printf("%s: NULL iter\n", __func__);
		exit(1);
	}

	/* Iterate over the array of dictionaries to find its index. */
	while ((obj = prop_object_iterator_next(iter))) {
		prop_dictionary_get_cstring_nocopy(obj, "pkgname", &curpkgn);
		if (strcmp(curpkgn, pkgname) == 0) {
			found = true;
			break;
		}
		i++;
	}

	if (found == false) {
		printf("=> ERROR: %s not registered in database.\n", pkgname);
		exit(1);
	}

	prop_array_remove(array, i);
	if (!xbps_add_array_to_dict(dict, array, "packages_installed")) {
		printf("=> ERROR: couldn't unregister %s from database\n",
		    pkgname);
		exit(1);
	}

	write_plist_file(dict, dbfile);
}

static void
write_plist_file(prop_dictionary_t dict, const char *file)
{
	if (dict == NULL || file == NULL) {
		printf("=> ERROR: couldn't write to database file.\n");
		exit(1);
	}

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
		tmppath = strncpy(dbfile, dbfileenv, sizeof(dbfile));
		if (sizeof(*tmppath) >= sizeof(dbfile))
			exit(1);
	} else {
		/* Use default path */
		tmppath =
		    strncpy(dbfile, XBPS_REGPKGDB_DEFPATH, sizeof(dbfile));
		if (sizeof(*tmppath) >= sizeof(dbfile))
			exit(1);
	}
	/* nul terminate string */
	dbfile[sizeof(dbfile) - 1] = '\0';

	in_chroot_env = getenv("in_chroot");
	if (in_chroot_env != NULL)
		in_chroot = true;

	if (strcmp(argv[1], "register") == 0) {
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
			if (pkgdict == NULL) {
				printf("=> ERROR: couldn't register pkg\n");
				exit(1);
			}

			/* Add pkg dictionary into array. */
			dbarray = prop_array_create();
			if (!xbps_add_obj_to_array(dbarray, pkgdict)) {
				printf("=> ERROR: couldn't register pkg\n");
				exit(1);
			}

			/* Add array into main dictionary. */
			dbdict = prop_dictionary_create();
			if (!xbps_add_array_to_dict(dbdict, dbarray,
			    "packages_installed")) {
				printf("=> ERROR: couldn't register pkg\n");
				exit(1);
			}

			/* Write main dictionary to file. */
			write_plist_file(dbdict, dbfile);

			printf("%s==> Package database file not found, "
			    "creating it.\n", in_chroot ? "[chroot] " : "");

			prop_object_release(dbdict);
		} else {
			/* Check if pkg is already registered. */
			pkgdict = xbps_find_pkg_in_dict(dbdict,
			    "packages_installed", argv[2]);
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

	} else if (strcmp(argv[1], "unregister") == 0) {
		/* Unregisters a package from the database */
		if (argc != 4)
			usage();

		unregister_pkg(prop_dictionary_internalize_from_file(dbfile),
		    argv[2], dbfile);

		printf("%s=> %s-%s unregistered successfully.\n",
		    in_chroot ? "[chroot] " : "", argv[2], argv[3]);

	} else if (strcmp(argv[1], "list") == 0) {
		/* Lists packages currently registered in database */
		if (argc != 2)
			usage();

		dbdict = prop_dictionary_internalize_from_file(dbfile);
		xbps_callback_array_iter_in_dict(dbdict,
		    "packages_installed", xbps_list_pkgs_in_dict);

	} else if (strcmp(argv[1], "version") == 0) {
		/* Prints version of an installed package */
		if (argc != 3)
			usage();

		pkgdict = xbps_find_pkg_in_dict(
			prop_dictionary_internalize_from_file(dbfile),
			"packages_installed", argv[2]);
		if (pkgdict == NULL)
			exit(1);
		if (!prop_dictionary_get_cstring_nocopy(pkgdict, "version",
		    &version))
			exit(1);
		printf("%s\n", version);

	} else if (strcmp(argv[1], "sanitize-plist") == 0) {
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
			printf("=> ERROR: couldn't write new plist file\n");
			exit(1);
		}

	} else {
		usage();
	}

	exit(0);
}
