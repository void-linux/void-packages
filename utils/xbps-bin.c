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
#include <libgen.h>

#include "xbps_api.h"

typedef struct repository_info {
	const char *index_version;
	const char *location_local;
	const char *location_remote;
	size_t total_pkgs;
} repo_info_t;

static const char *sanitize_localpath(const char *);
static prop_dictionary_t getrepolist_dict(void);
static bool pkgindex_getinfo(prop_dictionary_t, repo_info_t *);
static void usage(void);

static void
usage(void)
{
	printf("Usage: xbps-bin [action] [arguments]\n\n"
	" Available actions:\n"
        "    repo-add, repo-list, repo-rm, show\n"
	" Action arguments:\n"
	"    repo-add\t[<URI>]\n"
	"    repo-list\t[none]\n"
	"    repo-rm\t[<URI>]\n"
	"    show\t[<pkgname>]\n"
	"\n"
	" Examples:\n"
	"    $ xbps-bin repo-add /path/to/directory\n"
	"    $ xbps-bin repo-add http://www.location.org/xbps-repo\n"
	"    $ xbps-bin repo-list\n"
	"    $ xbps-bin repo-rm /path/to/directory\n"
	"    $ xbps-bin show klibc\n");
	exit(1);
}

static bool
pkgindex_getinfo(prop_dictionary_t dict, repo_info_t *ri)
{
	if (dict == NULL || ri == NULL)
		return false;

	if (!prop_dictionary_get_cstring_nocopy(dict,
	    "pkgindex-version", &ri->index_version))
		return false;

	if (!prop_dictionary_get_cstring_nocopy(dict,
	    "location-local", &ri->location_local))
		return false;

	/* This one is optional, thus don't panic */
	prop_dictionary_get_cstring_nocopy(dict, "location-remote",
	    &ri->location_remote);

	if (!prop_dictionary_get_uint64(dict, "total-pkgs",
	    &ri->total_pkgs))
		return false;

	/* Reject empty repositories, how could this happen? :-) */
	if (ri->total_pkgs <= 0)
		return false;

	return true;
}

static prop_dictionary_t
getrepolist_dict(void)
{
	prop_dictionary_t dict;

	dict = prop_dictionary_internalize_from_file(XBPS_REPOLIST_PATH);
	if (dict == NULL) {
		printf("cannot find repository list file: %s\n",
		    strerror(errno));
		exit(EINVAL);
	}

	return dict;
}

static const char *
sanitize_localpath(const char *path)
{
	const char *res;
	char strtmp[PATH_MAX];
	char *dirnp, *basenp, *dir, *base;

	dir = strdup(path);
	if (dir == NULL)
		return NULL;

	base = strdup(path);
	if (base == NULL)
		goto fail;

	dirnp = dirname(dir);
	if (strcmp(dirnp, ".") == 0)
		goto fail2;

	basenp = basename(base);
	if (strcmp(basenp, base) == 0)
		goto fail2;

	/* Sanitize path into a temporary path. */
	strncpy(strtmp, dirnp, sizeof(strtmp) - 1);
	strtmp[sizeof(strtmp) - 1] = '\0';
	strncat(strtmp, "/", sizeof(strtmp) - strlen(strtmp) - 1);
	strncat(strtmp, basenp, sizeof(strtmp) - strlen(strtmp) -1);

	free(dir);
	free(base);
	res = strtmp;
	return res;
fail:
	free(dir);
fail2:
	free(base);
	return NULL;
}

int
main(int argc, char **argv)
{
	prop_dictionary_t dict;
	repo_info_t *rinfo = NULL;
	const char *dpkgidx;
	char plist[PATH_MAX];

	if (argc < 2)
		usage();

	if (strcmp(argv[1], "repo-add") == 0) {
		/* Adds a new repository to the pool. */
		if (argc != 3)
			usage();

		dpkgidx = sanitize_localpath(argv[2]);
		if (dpkgidx == NULL)
			exit(EINVAL);

		/* Temp buffer to verify pkgindex file. */
		strncpy(plist, dpkgidx, sizeof(plist) - 1);
		plist[sizeof(plist) - 1] = '\0';
		strncat(plist, "/", sizeof(plist) - strlen(plist) - 1);
		strncat(plist, XBPS_PKGINDEX,
		    sizeof(plist) - strlen(plist) - 1);

		dict = prop_dictionary_internalize_from_file(plist);
		if (dict == NULL) {
			printf("Directory %s does not contain any "
			    "xbps pkgindex file.\n", dpkgidx);
			exit(EINVAL);
		}

		rinfo = malloc(sizeof(*rinfo));
		if (rinfo == NULL)
			exit(ENOMEM);

		if (!pkgindex_getinfo(dict, rinfo)) {
			printf("'%s' is incomplete.\n", plist);
			free(rinfo);
			exit(EINVAL);
		}

		if (!xbps_register_repository(dpkgidx)) {
			printf("ERROR: couldn't register repository (%s)\n",
			    strerror(errno));
			free(rinfo);
			exit(EINVAL);
		}

		printf("Added repository at %s (%s) with %zu packages.\n",
		       rinfo->location_local, rinfo->index_version,
		       rinfo->total_pkgs);
		free(rinfo);

	} else if (strcmp(argv[1], "repo-list") == 0) {
		/* Lists all repositories registered in pool. */
		if (argc != 2)
			usage();

		xbps_callback_array_iter_in_dict(getrepolist_dict(),
		    "repository-list", xbps_list_strings_in_array, NULL);

	} else if (strcmp(argv[1], "repo-rm") == 0) {
		/* Remove a repository from the pool. */
		if (argc != 3)
			usage();

		dpkgidx = sanitize_localpath(argv[2]);
		if (dpkgidx == NULL)
			exit(EINVAL);

		if (!xbps_unregister_repository(dpkgidx)) {
			if (errno == ENODEV)
				printf("Repository '%s' not actually "
				    "registered.\n", dpkgidx);
			else
				printf("ERROR: couldn't unregister "
				    "repository (%s)\n", strerror(errno));
			exit(EINVAL);
		}

	} else if (strcmp(argv[1], "show") == 0) {
		/* Shows info about a binary package. */
		if (argc != 3)
			usage();

		if (!xbps_callback_array_iter_in_dict(getrepolist_dict(),
		    "repository-list",
		    xbps_show_pkg_info_from_repolist, argv[2])) {
			printf("ERROR: unable to locate package '%s'.\n",
			    argv[2]);
			exit(EINVAL);
		}

	} else {
		usage();
	}

	exit(0);
}
