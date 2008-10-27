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

#include <prop/proplib.h>

#define _XBPS_PKGDB_DEFPATH	"/usr/local/packages/.xbps-pkgdb.plist"

static void usage(void);

static void
usage(void)
{
	printf("usage: xbps-pkgdb <action> [<pkgname> <version>]\n");
	printf("\n");
	printf("  Available actions:\n");
	printf("    installed, list, register, unregister, version\n");
	exit(1);
}

int
main(int argc, char **argv)
{
	prop_dictionary_t dbdict;
	prop_object_iterator_t dbditer;
	prop_object_t obj, obj2;
	prop_string_t pkg;
	char dbfile[PATH_MAX], *dbfileenv, *tmppath, *in_chroot_env;
	bool in_chroot = false;

	if (argc < 2)
		usage();

	if ((dbfileenv = getenv("XBPS_PKGDB_FPATH")) != NULL) {
		/* Use path as defined by XBPS_PKGDB_FPATH env var */
		tmppath = strncpy(dbfile, dbfileenv, sizeof(dbfile));
		if (sizeof(*tmppath) >= sizeof(dbfile))
			exit(1);
	} else {
		/* Use default path */
		tmppath =
		    strncpy(dbfile, _XBPS_PKGDB_DEFPATH, sizeof(dbfile));
		if (sizeof(*tmppath) >= sizeof(dbfile))
			exit(1);
	}
	/* nul terminate string */
	dbfile[sizeof(dbfile) - 1] = '\0';

	in_chroot_env = getenv("in_chroot");
	if (in_chroot_env != NULL)
		in_chroot = true;

	if (strcmp(argv[1], "installed") == 0) {
		/* Returns 0 if pkg is installed, 1 otherwise */
		if (argc != 3)
			usage();

		dbdict = prop_dictionary_internalize_from_file(dbfile);
		if (dbdict == NULL) {
			perror("ERROR: couldn't read database file");
			exit(1);
		}
		obj = prop_dictionary_get(dbdict, argv[2]);
		if (obj == NULL)
			exit(1);

	} else if (strcmp(argv[1], "register") == 0) {
		/* Registers a package into the database */
		if (argc != 4)
			usage();

		dbdict = prop_dictionary_internalize_from_file(dbfile);
		if (dbdict == NULL) {
			/* create db file and register pkg */
			dbdict = prop_dictionary_create();
			if (dbdict == NULL) {
				perror("ERROR");
				exit(1);
			}
			prop_dictionary_set_cstring_nocopy(dbdict, argv[2], argv[3]);
			if (!prop_dictionary_externalize_to_file(dbdict, dbfile)) {
				perror("ERROR: couldn't write database file");
				exit(1);
			}
			printf("==> Package database file not found, "
			    "creating it.\n");
			prop_object_release(dbdict);
		} else {
			/* register pkg if it's not registered already */
			pkg = prop_dictionary_get(dbdict, argv[2]);
			if (pkg && prop_object_type(pkg) == PROP_TYPE_STRING) {
				printf("==> Package `%s' already registered.\n", argv[2]);
				exit(0);
			}
			prop_dictionary_set_cstring_nocopy(dbdict, argv[2], argv[3]);
			if (!prop_dictionary_externalize_to_file(dbdict, dbfile)) {
				perror(" ERROR: couldn't write database file");
				exit(1);
			}
		}

		printf("%s==> %s-%s registered successfully.\n",
		    in_chroot ? "[chroot] " : "", argv[2], argv[3]);

	} else if (strcmp(argv[1], "unregister") == 0) {
		/* Unregisters a package from the database */
		if (argc != 4)
			usage();

		dbdict = prop_dictionary_internalize_from_file(dbfile);
		if (dbdict == NULL) {
			perror("ERROR: couldn't read database file");
			exit(1);
		}
		obj = prop_dictionary_get(dbdict, argv[2]);
		if (obj == NULL) {
			printf("ERROR: package `%s' not registered in database.\n",
			    argv[2]);
			exit(1);
		}
		prop_dictionary_remove(dbdict, argv[2]);
		if (!prop_dictionary_externalize_to_file(dbdict, dbfile)) {
			perror("ERROR: couldn't write database file");
			exit(1);
		}

		printf("%s==> %s-%s unregistered successfully.\n",
		    in_chroot ? "[chroot] " : "", argv[2], argv[3]);

	} else if (strcmp(argv[1], "list") == 0) {
		/* Lists packages currently registered in database */
		if (argc != 2)
			usage();

		dbdict = prop_dictionary_internalize_from_file(dbfile);
		if (dbdict == NULL) {
			perror("ERROR: couldn't read database file");
			exit(1);
		}
		dbditer = prop_dictionary_iterator(dbdict);
		if (dbditer == NULL) {
			perror("ERROR");
			exit(1);
		}
		while ((obj = prop_object_iterator_next(dbditer)) != NULL) {
			obj2 = prop_dictionary_get_keysym(dbdict, obj);
			if (obj2 != NULL) {
				printf("%s", prop_dictionary_keysym_cstring_nocopy(obj));
				printf("-%s\n", prop_string_cstring_nocopy(obj2));
			}
		}
		prop_object_iterator_release(dbditer);

	} else if (strcmp(argv[1], "version") == 0) {
		/* Prints version of an installed package */
		if (argc != 3)
			usage();

		dbdict = prop_dictionary_internalize_from_file(dbfile);
		if (dbdict == NULL) {
			perror("ERROR: couldn't read database file");
			exit(1);
		}
		obj = prop_dictionary_get(dbdict, argv[2]);
		if (obj == NULL) {
			printf("ERROR: package `%s' not registered in database.\n",
			    argv[2]);
			exit(1);
		}
		printf("%s\n", prop_string_cstring_nocopy(obj));

	} else {
		usage();
	}

	exit(0);
}
