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

typedef struct pkg_dependency {
	LIST_ENTRY(pkg_dependency) deps;
	prop_dictionary_t dict;
	char *name;
} pkg_dep_t;

static LIST_HEAD(, pkg_dependency) pkg_deps_list =
    LIST_HEAD_INITIALIZER(pkg_deps_list);

int
xbps_check_is_installed_pkg(const char *plist, const char *pkg)
{
	prop_dictionary_t dict, pkgdict;
	prop_object_t obj;
	const char *reqver, *instver;
	char *pkgname;

	pkgname = xbps_get_pkg_name(pkg);
	reqver = xbps_get_pkg_version(pkg);

	/* Get package dictionary from plist */
	dict = prop_dictionary_internalize_from_file(plist);
	if (dict == NULL) {
		free(pkgname);
		return XBPS_PKG_EEMPTY;
	}

	pkgdict = xbps_find_pkg_in_dict(dict, pkgname);
	if (pkgdict == NULL) {
		prop_object_release(dict);
		free(pkgname);
		return 1; /* not installed */
	}

	/* Get version from installed package */
	obj = prop_dictionary_get(pkgdict, "version");
	assert(obj != NULL);
	assert(prop_object_type(obj) == PROP_TYPE_STRING);
	instver = prop_string_cstring_nocopy(obj);
	assert(instver != NULL);
	free(pkgname);
	prop_object_release(dict);

	return (xbps_cmpver_versions(instver, reqver) > 0) ? 1 : 0;
}

void
xbps_add_pkg_dependency(const char *pkgname, prop_dictionary_t dict)
{
	pkg_dep_t *dep;
	size_t len = 0;

	assert(pkgname != NULL);
	assert(dict != NULL);

	LIST_FOREACH(dep, &pkg_deps_list, deps)
		if (strcmp(dep->name, pkgname) == 0)
			return;

	dep = NULL;
	dep = malloc(sizeof(*dep));
	assert(dep != NULL);

	len = strlen(pkgname) + 1;
	dep->name = malloc(len);
	if (dep->name == NULL) {
		free(dep);
		return;
	}

	memcpy(dep->name, pkgname, len - 1);
	dep->name[len - 1] = '\0';
	dep->dict = prop_dictionary_copy(dict);

	LIST_INSERT_HEAD(&pkg_deps_list, dep, deps);
}

static bool
pkg_has_rundeps(prop_dictionary_t pkg)
{
	prop_array_t array;

	assert(pkg != NULL);

	array = prop_dictionary_get(pkg, "run_depends");
	if (array && prop_array_count(array) > 0)
		return true;

	return false;
}

static int
find_deps_in_pkg(prop_dictionary_t repo, prop_dictionary_t pkg)
{
	prop_dictionary_t pkgdict;
	prop_array_t array;
	prop_string_t name;
	prop_object_t obj;
	prop_object_iterator_t iter = NULL;
	const char *reqpkg;
	char *pkgname;

	array = prop_dictionary_get(pkg, "run_depends");
	if (array == NULL || prop_array_count(array) == 0)
		return 0;

	iter = prop_array_iterator(array);
	if (iter == NULL)
		return -1;

	name = prop_dictionary_get(pkg, "pkgname");
	xbps_add_pkg_dependency(prop_string_cstring_nocopy(name), pkg);

	/* Iterate over the list of required run dependencies for a pkg */
	while ((obj = prop_object_iterator_next(iter))) {
		reqpkg = prop_string_cstring_nocopy(obj);
		pkgname = xbps_get_pkg_name(reqpkg);
		pkgdict = xbps_find_pkg_in_dict(repo, pkgname);
		xbps_add_pkg_dependency(pkgname, pkgdict);
		free(pkgname);

		/* Iterate on required pkg to find more deps */
		if (pkg_has_rundeps(pkgdict)) {
			/* more deps? */
			if (!find_deps_in_pkg(repo, pkgdict))
				continue;
		}
	}

	prop_object_iterator_release(iter);

	return 0;
}

int
xbps_install_pkg_deps(prop_dictionary_t repo, prop_dictionary_t pkg)
{
	pkg_dep_t *dep;
	prop_string_t pkgname, version;
	int rv = 0;

	assert(pkg != NULL);
	assert(repo != NULL);
	assert(prop_object_type(pkg) == PROP_TYPE_DICTIONARY);
	assert(prop_object_type(repo) == PROP_TYPE_DICTIONARY);

	if (!pkg_has_rundeps(pkg)) {
		/* Package has no required dependencies. */
		return 0;
	}

	/* Check what dependencies are required. */
	if (find_deps_in_pkg(repo, pkg) == -1) {
		errno = XBPS_PKG_EINDEPS;
		return -1;
	}

	/*
	 * Iterate over the list of dependencies and install them.
	 */
	LIST_FOREACH(dep, &pkg_deps_list, deps) {
		pkgname = prop_dictionary_get(dep->dict, "pkgname");
		version = prop_dictionary_get(dep->dict, "version");
		printf("Required package: %s >= %s\n",
		    prop_string_cstring_nocopy(pkgname),
		    prop_string_cstring_nocopy(version));
		(void)fflush(stdout);

		rv = xbps_unpack_binary_pkg(dep->dict, xbps_unpack_archive_cb);
		if (rv != 0)
			break;

		LIST_REMOVE(dep, deps);
		free(dep->name);
		prop_object_release(dep->dict);
	}

	return 1;
}
