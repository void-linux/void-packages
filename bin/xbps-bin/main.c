/*-
 * Copyright (c) 2008-2009 Juan Romero Pardines.
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
#include <strings.h>
#include <errno.h>
#include <limits.h>
#include <libgen.h>
#include <unistd.h>

#include <xbps_api.h>
#include "defs.h"
#include "../xbps-repo/util.h"

static void	usage(void);
static int	list_pkgs_in_dict(prop_object_t, void *, bool *);

static void
usage(void)
{
	printf("Usage: xbps-bin [options] [target] [arguments]\n\n"
	" Available targets:\n"
        "    autoremove, files, install, list, remove, show, update\n"
	" Targets with arguments:\n"
	"    files\t<pkgname>\n"
	"    install\t<pkgname>\n"
	"    remove\t<pkgname>\n"
	"    show\t<pkgname>\n"
	"    update\t<pkgname>\n"
	" Options shared by all targets:\n"
	"    -r\t\t<rootdir>\n"
	"    -v\t\t<verbose>\n"
	" Options used by the files target:\n"
	"    -C\t\tTo check the SHA256 hash for any listed file.\n"
	" Options used by the (auto)remove target:\n"
	"    -f\t\tForce removal, even if package is required by other\n"
	"      \t\tpackages that are currently installed.\n"
	"\n"
	" Examples:\n"
	"    $ xbps-bin autoremove\n"
	"    $ xbps-bin -C files klibc\n"
	"    $ xbps-bin install klibc\n"
	"    $ xbps-bin -r /path/to/root install klibc\n"
	"    $ xbps-bin list\n"
	"    $ xbps-bin -f remove klibc\n"
	"    $ xbps-bin show klibc\n"
	"    $ xbps-bin update klibc\n");
	exit(EXIT_FAILURE);
}

static int
list_pkgs_in_dict(prop_object_t obj, void *arg, bool *loop_done)
{
	const char *pkgname, *version, *short_desc;
	(void)arg;
	(void)loop_done;

	assert(prop_object_type(obj) == PROP_TYPE_DICTIONARY);

	prop_dictionary_get_cstring_nocopy(obj, "pkgname", &pkgname);
	prop_dictionary_get_cstring_nocopy(obj, "version", &version);
	prop_dictionary_get_cstring_nocopy(obj, "short_desc", &short_desc);
	if (pkgname && version && short_desc) {
		printf("%s-%s\t%s\n", pkgname, version, short_desc);
		return 0;
	}

	return EINVAL;
}

int
main(int argc, char **argv)
{
	prop_dictionary_t dict;
	prop_array_t reqby, orphans;
	prop_object_t obj;
	prop_object_iterator_t iter;
	const char *pkgname, *version, *sep, *rootdir;
	char *plist;
	int c, flags = 0, rv = 0;
	bool chkhash = false, forcerm = false, verbose = false;

	while ((c = getopt(argc, argv, "Cfr:v")) != -1) {
		switch (c) {
		case 'C':
			chkhash = true;
			break;
		case 'f':
			forcerm = true;
			break;
		case 'r':
			/* To specify the root directory */
			xbps_set_rootdir(optarg);
			break;
		case 'v':
			verbose = true;
			flags |= XBPS_VERBOSE;
			break;
		case '?':
		default:
			usage();
		}
	}

	argc -= optind;
	argv += optind;

	if (argc < 1)
		usage();

	if (flags != 0)
		xbps_set_flags(flags);

	if (strcasecmp(argv[0], "list") == 0) {
		/* Lists packages currently registered in database. */
		if (argc != 1)
			usage();

		rootdir = xbps_get_rootdir();
		plist = xbps_xasprintf("%s/%s/%s", rootdir,
		    XBPS_META_PATH, XBPS_REGPKGDB);
		if (plist == NULL)
			exit(EXIT_FAILURE);

		dict = prop_dictionary_internalize_from_file(plist);
		if (dict == NULL) {
			printf("No packages currently registered.\n");
			free(plist);
			exit(EXIT_SUCCESS);
		}

		if (!xbps_callback_array_iter_in_dict(dict, "packages",
		    list_pkgs_in_dict, NULL)) {
			prop_object_release(dict);
			free(plist);
			exit(EXIT_FAILURE);
		}
		prop_object_release(dict);
		free(plist);

	} else if (strcasecmp(argv[0], "install") == 0) {
		/* Installs a binary package and required deps. */
		if (argc != 2)
			usage();

		xbps_install_pkg(argv[1], false);

	} else if (strcasecmp(argv[0], "update") == 0) {
		/* Update an installed package. */
		if (argc != 2)
			usage();

		xbps_install_pkg(argv[1], true);

	} else if (strcasecmp(argv[0], "remove") == 0) {
		/* Removes a binary package. */
		if (argc != 2)
			usage();

		/*
		 * First check if package is required by other packages.
		 */
		dict = xbps_find_pkg_installed_from_plist(argv[1]);
		if (dict == NULL) {
			printf("Package %s is not installed.\n", argv[1]);
			exit(EXIT_FAILURE);
		}
		prop_dictionary_get_cstring_nocopy(dict, "version", &version);

		reqby = prop_dictionary_get(dict, "requiredby");
		if (reqby != NULL && prop_array_count(reqby) > 0) {
			printf("WARNING! %s-%s is required by the following "
			    "packages:\n", argv[1], version);
			sep = "\t";
			(void)xbps_callback_array_iter_in_dict(dict,
			    "requiredby", list_strings_in_array, (void *)sep);
			if (!forcerm) {
				prop_object_release(dict);
				printf("If you are sure about this, use "
				    "-f to force deletion for this package.\n");
				exit(EXIT_FAILURE);
			} else
				printf("Forcing %s-%s for deletion!\n",
				    argv[1], version);
		}

		printf("Removing package %s-%s ... ", argv[1], version);
		if (verbose)
			printf("\n");

		(void)fflush(stdout);

		rv = xbps_remove_binary_pkg(argv[1], false);
		if (rv != 0) {
			if (!verbose)
				printf("failed! (%s)\n", strerror(rv));
			else
				printf("Unable to remove %s-%s (%s).\n",
				    argv[1], version, strerror(errno));

			prop_object_release(dict);
			exit(EXIT_FAILURE);
		}
		if (!verbose)
			printf("done.\n");
		else
			printf("Package %s-%s removed successfully.\n",
			    argv[1], version);

		prop_object_release(dict);

	} else if (strcasecmp(argv[0], "show") == 0) {
		/* Shows info about an installed binary package. */
		if (argc != 2)
			usage();

		rv = show_pkg_info_from_metadir(argv[1]);
		if (rv != 0) {
			printf("Package %s not installed.\n", argv[1]);
			exit(EXIT_FAILURE);
		}

	} else if (strcasecmp(argv[0], "files") == 0) {
		/* Shows files installed by a binary package. */
		if (argc != 2)
			usage();

		rv = show_pkg_files_from_metadir(argv[1], chkhash);
		if (rv != 0) {
			printf("Package %s not installed.\n", argv[1]);
			exit(EXIT_FAILURE);
		}

	} else if (strcasecmp(argv[0], "autoremove") == 0) {
		/*
		 * Removes orphan pkgs. These packages were installed
		 * as dependency and any installed package does not depend
		 * on it currently.
		 */
		if (argc != 1)
			usage();

		orphans = xbps_find_orphan_packages();
		if (orphans == NULL)
			exit(EXIT_FAILURE);
		if (orphans != NULL && prop_array_count(orphans) == 0) {
			printf("There are not orphaned packages currently.\n");
			exit(EXIT_SUCCESS);
		}

		iter = prop_array_iterator(orphans);
		if (iter == NULL)
			exit(EXIT_FAILURE);

		printf("The following packages were installed automatically\n"
		    "(as dependencies) and aren't needed anymore:\n");
		while ((obj = prop_object_iterator_next(iter)) != NULL) {
			prop_dictionary_get_cstring_nocopy(obj, "pkgname",
			    &pkgname);
			prop_dictionary_get_cstring_nocopy(obj, "version",
			    &version);
			printf("\t%s-%s\n", pkgname, version);
		}
		if (!forcerm) {
			printf("If you are really sure you don't need them, "
			    "use -f to confirm.\n");
			goto out;
		}

		prop_object_iterator_reset(iter);

		while ((obj = prop_object_iterator_next(iter)) != NULL) {
			prop_dictionary_get_cstring_nocopy(obj, "pkgname",
			    &pkgname);
			prop_dictionary_get_cstring_nocopy(obj, "version",
			    &version);
			printf("Removing package %s-%s ... ",
			    pkgname, version);
			if (verbose)
				printf("\n");

			(void)fflush(stdout);

			rv = xbps_remove_binary_pkg(pkgname, false);
			if (rv != 0) {
				if (!verbose)
					printf("failed! (%s)\n", strerror(rv));
				prop_object_iterator_release(iter);
				prop_object_release(orphans);
				exit(EXIT_FAILURE);
			}
			if (!verbose)
				printf("done.\n");
		}
out:
		prop_object_iterator_release(iter);
		prop_object_release(orphans);

	} else {
		usage();
	}

	exit(EXIT_SUCCESS);
}
