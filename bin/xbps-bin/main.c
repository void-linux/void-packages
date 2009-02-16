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
#include <errno.h>
#include <limits.h>
#include <libgen.h>
#include <unistd.h>

#include <xbps_api.h>
#include "../xbps-repo/util.h"

static void	usage(void);
static void	show_missing_deps(prop_dictionary_t, const char *);
static int	show_missing_dep_cb(prop_object_t, void *, bool *);
static int	list_pkgs_in_dict(prop_object_t, void *, bool *);

static void
usage(void)
{
	printf("Usage: xbps-bin [options] [action] [arguments]\n\n"
	" Available actions:\n"
        "    install, list, remove, show\n"
	" Actions with arguments:\n"
	"    install\t<pkgname>\n"
	"    remove\t<pkgname>\n"
	"    show\t<pkgname>\n"
	" Options shared by all actions:\n"
	"    -r\t\t<rootdir>\n"
	"\n"
	" Examples:\n"
	"    $ xbps-bin install klibc\n"
	"    $ xbps-bin -r /path/to/root install klibc\n"
	"    $ xbps-bin list\n"
	"    $ xbps-bin remove klibc\n"
	"    $ xbps-bin show klibc\n");
	exit(EXIT_FAILURE);
}

static int
list_pkgs_in_dict(prop_object_t obj, void *arg, bool *loop_done)
{
	const char *pkgname, *version, *short_desc;

	assert(prop_object_type(obj) == PROP_TYPE_DICTIONARY);

	prop_dictionary_get_cstring_nocopy(obj, "pkgname", &pkgname);
	prop_dictionary_get_cstring_nocopy(obj, "version", &version);
	prop_dictionary_get_cstring_nocopy(obj, "short_desc", &short_desc);
	if (pkgname && version && short_desc) {
		printf("%s (%s)\t%s\n", pkgname, version, short_desc);
		return 0;
	}

	return EINVAL;
}

static void
show_missing_deps(prop_dictionary_t d, const char *pkgname)
{
	printf("Unable to locate some required packages for %s:\n",
	    pkgname);
	(void)xbps_callback_array_iter_in_dict(d, "missing_deps",
	    show_missing_dep_cb, NULL);
}

static int
show_missing_dep_cb(prop_object_t obj, void *arg, bool *loop_done)
{
	const char *pkgname, *version;

	prop_dictionary_get_cstring_nocopy(obj, "pkgname", &pkgname);
	prop_dictionary_get_cstring_nocopy(obj, "version", &version);
	if (pkgname && version) {
		printf("\tmissing binary package for: %s >= %s\n",
		    pkgname, version);
		return 0;
	}

	return EINVAL;
}

int
main(int argc, char **argv)
{
	prop_dictionary_t dict;
	char *plist, *root = NULL;
	int c, rv = 0;

	while ((c = getopt(argc, argv, "r:")) != -1) {
		switch (c) {
		case 'r':
			/* To specify the root directory */
			root = optarg;
			xbps_set_rootdir(root);
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

	if (strcasecmp(argv[0], "list") == 0) {
		/* Lists packages currently registered in database. */
		if (argc != 1)
			usage();

		plist = xbps_append_full_path(true, NULL, XBPS_REGPKGDB);
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

	} else if ((strcasecmp(argv[0], "install") == 0) ||
		   (strcasecmp(argv[0], "remove") == 0))  {
		/* Installs a binary package and required deps. */
		if (argc != 2)
			usage();

		/* Install into root directory by default. */
		if (strcasecmp(argv[0], "install") == 0) {
			rv = xbps_install_binary_pkg(argv[1], root);
			if (rv) {
				dict = xbps_get_pkg_deps_dictionary();
				if (dict == NULL && errno == ENOENT)
					printf("Unable to locate %s in "
					    "repository pool.\n", argv[1]);
				else if (dict && errno == ENOENT)
					show_missing_deps(dict, argv[1]);

				exit(EXIT_FAILURE);
			}
			printf("Package %s installed successfully.\n", argv[1]);
		} else {
			rv = xbps_remove_binary_pkg(argv[1], root);
			if (rv) {
				if (errno == ENOENT)
					printf("Package %s is not installed.\n",
					    argv[1]);
				else
					printf("Unable to remove %s (%s).\n",
					    argv[1], strerror(errno));
				exit(EXIT_FAILURE);
			}
			printf("Package %s removed successfully.\n", argv[1]);
		}

	} else if (strcasecmp(argv[0], "show") == 0) {
		/* Shows info about an installed binary package. */
		if (argc != 2)
			usage();

		rv = show_pkg_info_from_metadir(argv[1]);
		if (rv != 0) {
			printf("Package %s not installed\n", argv[1]);
			exit(EXIT_FAILURE);
		}
	} else {
		usage();
	}

	exit(EXIT_SUCCESS);
}
