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

const char *
xbps_get_pkg_version(const char *pkg)
{
	const char *tmp;

	/* Get the required version */
	tmp = strrchr(pkg, '-');
	assert(tmp != NULL);
	return tmp + 1; /* skip first '-' */
}

char *
xbps_get_pkg_name(const char *pkg)
{
	const char *tmp;
	char *pkgname;
	size_t len;

	/* Get the required version */
	tmp = strrchr(pkg, '-');
	assert(tmp != NULL);
	len = strlen(pkg) - strlen(tmp);

	/* Get package name */
	pkgname = malloc(len + 1);
	memcpy(pkgname, pkg, len);
	pkgname[len + 1] = '\0';

	return pkgname;
}

bool
xbps_append_full_path(char *buf, const char *root, const char *plistf)
{
	const char *env, *tmp;
	size_t len = 0;

	assert(buf != NULL);
	assert(plistf != NULL);

	if (root)
		env = root;
	else {
		env = getenv("XBPS_META_PATH");
		if (env == NULL)
			env = XBPS_META_PATH;
	}

	tmp = strncpy(buf, env, PATH_MAX - 1);
	if (sizeof(*tmp) >= PATH_MAX) {
		errno = ENOSPC;
		return false;
	}

	len = strlen(buf);
	buf[len + 1] = '\0';
	if (buf[len - 2] != '/')
		strncat(buf, "/", 1);
	strncat(buf, plistf, sizeof(buf) - strlen(buf) - 1);

	return true;
}

static int
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

int
xbps_check_reqdeps_in_pkg(const char *plist, prop_dictionary_t pkg)
{
	prop_array_t array;
	prop_object_t obj;
	prop_object_iterator_t iter;
	const char *reqpkg;
	int rv = 0;
	bool need_deps = false;

	assert(pkg != NULL);
	assert(prop_object_type(pkg) == PROP_TYPE_DICTIONARY);
	assert(prop_dictionary_count(pkg) != 0);
	assert(plist != NULL);

	array = prop_dictionary_get(pkg, "run_depends");
	if (array == NULL) {
		/* Package has no required rundeps */
		return 0;
	}

	assert(prop_object_type(array) == PROP_TYPE_ARRAY);
	assert(prop_array_count(array) != 0);

	iter = prop_array_iterator(array);
	if (iter == NULL) {
		errno = ENOMEM;
		return -1;
	}

	while ((obj = prop_object_iterator_next(iter))) {
		assert(prop_object_type(obj) == PROP_TYPE_STRING);
		reqpkg = prop_string_cstring_nocopy(obj);

		rv = xbps_check_is_installed_pkg(plist, reqpkg);
		if (rv == XBPS_PKG_EEMPTY) {
			/* No packages registered yet. */
			need_deps = true;
			printf("Package '%s' not installed\n", reqpkg);
			//xbps_add_pkg_dependency(reqpkg);

		} else if (rv == 1) {
			need_deps = true;
			printf("Package '%s' required.\n", reqpkg);

		} else if (rv == 0) {
			printf("Package '%s' already installed.\n", reqpkg);

		}
	}

	prop_object_iterator_release(iter);

	return need_deps;
}
