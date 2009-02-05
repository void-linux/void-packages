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

static void	usage(void);
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

		if (geteuid() != 0) {
			printf("ERROR: root permissions are needed to install"
			    "and remove binary packages.\n");
			exit(EXIT_FAILURE);
		}

		/* Install into root directory by default. */
		if (strcasecmp(argv[0], "install") == 0) {
			rv = xbps_install_binary_pkg(argv[1], root);
			if (rv) {
				printf("ERROR: unable to install %s.\n", argv[1]);
				exit(rv);
			}
			printf("Package %s installed successfully.\n", argv[1]);
		} else {
			rv = xbps_remove_binary_pkg(argv[1], root);
			if (rv) {
				if (rv == ENOENT)
					printf("Package %s is not installed.\n",
					    argv[1]);
				else
					printf("ERROR: unable to remove %s.\n",
					    argv[1]);
				exit(rv);
			}
			printf("Package %s removed successfully.\n", argv[1]);
		}

	} else {
		usage();
	}

	exit(EXIT_SUCCESS);
}
