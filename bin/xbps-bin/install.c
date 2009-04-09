/*-
 * Copyright (c) 2009 Juan Romero Pardines.
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

#include <xbps_api.h>
#include "defs.h"

static void	show_missing_deps(prop_dictionary_t, const char *);
static int	show_missing_dep_cb(prop_object_t, void *, bool *);

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

        (void)arg;
        (void)loop_done;

	prop_dictionary_get_cstring_nocopy(obj, "pkgname", &pkgname);
	prop_dictionary_get_cstring_nocopy(obj, "version", &version);
	if (pkgname && version) {
		printf("  * Missing binary package for: %s >= %s\n",
		    pkgname, version);
		return 0;
	}

	return EINVAL;
}

void
xbps_install_pkg(const char *pkg, bool force, bool update)
{
	prop_dictionary_t props, instpkg;
	prop_array_t array;
	prop_object_t obj;
	prop_object_iterator_t iter;
	uint64_t tsize = 0, dlsize = 0, instsize = 0;
	size_t cols = 0;
	const char *repoloc, *filename, *instver, *origin;
	const char *pkgname, *version;
	char size[64];
	int rv = 0;
	bool pkg_is_dep, first = false;

	assert(props != NULL);

	/*
	 * Find and sort all required package dictionaries.
	 */
	printf("Finding/sorting required binary packages...\n");

	rv = xbps_prepare_pkg(pkg);
	if (rv != 0 && rv == EAGAIN) {
		printf("Unable to locate %s in repository pool.\n", pkg);
		exit(EXIT_FAILURE);
	} else if (rv != 0 && rv != ENOENT) {
		printf("Unexpected error: %s\n", strerror(rv));
		exit(EXIT_FAILURE);
	}

	props = xbps_get_pkg_props(pkg);
	if (props == NULL) {
		printf("error: unexistent props dictionary!\n");
		exit(EXIT_FAILURE);
	}

	/*
	 * Bail out if there are unresolved deps.
	 */
	array = prop_dictionary_get(props, "missing_deps");
	if (prop_array_count(array) > 0) {
		show_missing_deps(props, pkg);
		prop_object_release(props);
		exit(EXIT_FAILURE);
	}

	prop_dictionary_get_cstring_nocopy(props, "origin", &origin);

	/*
	 * Iterate over the list of packages that are going to be
	 * installed and check the file hash.
	 */
	array = prop_dictionary_get(props, "packages");
	if (array == NULL || prop_array_count(array) == 0) {
		printf("error: empty packages array!\n");
		prop_object_release(props);
		exit(EXIT_FAILURE);
	}

	iter = prop_array_iterator(array);
	if (iter == NULL) {
		printf("error: allocating array mem! (%s)\n", strerror(errno));
		prop_object_release(props);
		exit(EXIT_FAILURE);
	}

	while ((obj = prop_object_iterator_next(iter)) != NULL) {
		prop_dictionary_get_uint64(obj, "filename-size", &tsize);
		dlsize += tsize;
		tsize = 0;
		prop_dictionary_get_uint64(obj, "installed_size", &tsize);
		instsize += tsize;
		tsize = 0;
	}
	prop_object_iterator_reset(iter);

	/*
	 * Show the list of packages that will be installed.
	 */
	printf("\nThe following new packages will be installed:\n\n");

	while ((obj = prop_object_iterator_next(iter)) != NULL) {
		prop_dictionary_get_cstring_nocopy(obj, "pkgname", &pkgname);
		prop_dictionary_get_cstring_nocopy(obj, "version", &version);
		cols += strlen(pkgname) + strlen(version) + 4;
		if (cols <= 80) {
			if (first == false) {
				printf("  ");
				first = true;
			}
		} else {
			printf("\n  ");
			cols = strlen(pkgname) + strlen(version) + 4;
		}
		printf("%s-%s ", pkgname, version);
	}
	prop_object_iterator_reset(iter);
	printf("\n\n");

	/*
	 * Show total download/installed size for all required packages.
	 */
	if (xbps_humanize_number(size, 5, (int64_t)dlsize,
	    "", HN_AUTOSCALE, HN_NOSPACE) == -1) {
		printf("error: humanize_number %s\n", strerror(errno));
		prop_object_release(props);
		exit(EXIT_FAILURE);
	}
	printf("Total download size: %s\n", size);
	if (xbps_humanize_number(size, 5, (int64_t)instsize,
	    "", HN_AUTOSCALE, HN_NOSPACE) == -1) {
		printf("error: humanize_number2 %s\n", strerror(errno));
		prop_object_release(props);
		exit(EXIT_FAILURE);
	}
	printf("Total installed size: %s\n\n", size);

	if (force == false) {
		if (xbps_noyes("Do you want to continue?") == false) {
			printf("Aborting!\n");
			prop_object_release(props);
			exit(EXIT_SUCCESS);
		}
	}

	printf("Checking binary package file(s) integrity...\n");
	while ((obj = prop_object_iterator_next(iter)) != NULL) {
		prop_dictionary_get_cstring_nocopy(obj, "repository", &repoloc);
		prop_dictionary_get_cstring_nocopy(obj, "filename", &filename);
		rv = xbps_check_pkg_file_hash(obj, repoloc);
		if (rv != 0 && rv != ERANGE) {
			printf("error: checking hash for %s (%s)\n",
			    filename, strerror(rv));
			prop_object_release(props);
			exit(EXIT_FAILURE);
		} else if (rv != 0 && rv == ERANGE) {
			printf("Hash doesn't match for %s!\n", filename);
			prop_object_release(props);
			exit(EXIT_FAILURE);
		}
	}
	prop_object_iterator_reset(iter);
	printf("\n");

	/*
	 * Install all packages, the list is already sorted.
	 */
	while ((obj = prop_object_iterator_next(iter)) != NULL) {
		prop_dictionary_get_cstring_nocopy(obj, "pkgname", &pkgname);
		prop_dictionary_get_cstring_nocopy(obj, "version", &version);
		if (strcmp(origin, pkgname))
			pkg_is_dep = true;

		if (update) {
			/*
			* Update a package, firstly removing current package.
			 */
			instpkg = xbps_find_pkg_installed_from_plist(pkgname);
			if (instpkg == NULL) {
				printf("error: unable to find %s installed "
				    "dict!\n", pkgname);
				prop_object_release(props);
				exit(EXIT_FAILURE);
			}

			prop_dictionary_get_cstring_nocopy(instpkg,
			    "version", &instver);
			printf("Updating package %s-%s to %s...\n", pkgname,
			    instver, version);
			prop_object_release(instpkg);
			rv = xbps_remove_binary_pkg(pkgname, update);
			if (rv != 0) {
				printf("error: removing %s-%s (%s)\n",
				    pkgname, instver, strerror(rv));
				prop_object_release(props);
				exit(EXIT_FAILURE);
			}

		} else {
			printf("Installing %s%s-%s ...\n",
			    pkg_is_dep ? "dependency " : "", pkgname, version);
		}
		/*
		 * Unpack binary package.
		 */
		if ((rv = xbps_unpack_binary_pkg(obj)) != 0) {
			printf("error: unpacking %s-%s (%s)\n", pkgname,
			    version, strerror(rv));
			prop_object_release(props);
			exit(EXIT_FAILURE);
		}
		/*
		 * Register binary package.
		 */
		if ((rv = xbps_register_pkg(obj, update, pkg_is_dep)) != 0) {
			printf("error: registering %s-%s! (%s)\n",
			    pkgname, version, strerror(rv));
			prop_object_release(props);
			exit(EXIT_FAILURE);
		}
		pkg_is_dep = false;
	}
	prop_object_iterator_release(iter);
	prop_object_release(props);

	exit(EXIT_SUCCESS);
}
