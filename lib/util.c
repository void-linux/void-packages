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

#include <xbps_api.h>

static const char *rootdir;

int
xbps_check_is_installed_pkg(const char *pkg)
{
	prop_dictionary_t dict, pkgdict;
	prop_object_t obj;
	const char *reqver, *instver;
	char *plist, *pkgname;
	int rv = 0;

	assert(pkg != NULL);

	plist = xbps_append_full_path(true, NULL, XBPS_REGPKGDB);
	if (plist == NULL)
		return EINVAL;

	pkgname = xbps_get_pkg_name(pkg);
	reqver = xbps_get_pkg_version(pkg);

	/* Get package dictionary from plist */
	dict = prop_dictionary_internalize_from_file(plist);
	if (dict == NULL) {
		free(pkgname);
		free(plist);
		return 1; /* not installed */
	}

	pkgdict = xbps_find_pkg_in_dict(dict, pkgname);
	if (pkgdict == NULL) {
		prop_object_release(dict);
		free(pkgname);
		free(plist);
		return 1; /* not installed */
	}

	/* Get version from installed package */
	obj = prop_dictionary_get(pkgdict, "version");
	assert(obj != NULL);
	assert(prop_object_type(obj) == PROP_TYPE_STRING);
	instver = prop_string_cstring_nocopy(obj);
	assert(instver != NULL);

	/* Compare installed and required version. */
	rv = xbps_cmpver_versions(instver, reqver) > 0 ? 1 : 0;

	free(pkgname);
	free(plist);
	prop_object_release(dict);

	return rv;
}

bool
xbps_check_is_installed_pkgname(const char *pkgname)
{
	prop_dictionary_t pkgd;
	char *plist;

	assert(pkgname != NULL);

	plist = xbps_append_full_path(true, NULL, XBPS_REGPKGDB);
	if (plist == NULL)
		return false;

	pkgd = xbps_find_pkg_from_plist(plist, pkgname);
	free(plist);
	if (pkgd) {
		prop_object_release(pkgd);
		return true;
	}

	return false;
}

const char *
xbps_get_pkg_version(const char *pkg)
{
	const char *tmp;

	assert(pkg != NULL);

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
	size_t len = 0;

	assert(pkg != NULL);

	/* Get package name */
	tmp = strrchr(pkg, '-');
	assert(tmp != NULL);
	len = strlen(pkg) - strlen(tmp) + 1;

	pkgname = malloc(len);
	memcpy(pkgname, pkg, len - 1);
	pkgname[len - 1] = '\0';

	return pkgname;
}

bool
xbps_pkg_has_rundeps(prop_dictionary_t pkg)
{
	prop_array_t array;

	assert(pkg != NULL);
	array = prop_dictionary_get(pkg, "run_depends");
	if (array && prop_array_count(array) > 0)
		return true;

	return false;
}

void
xbps_set_rootdir(const char *dir)
{
	assert(dir != NULL);
	rootdir = dir;
}

char *
xbps_append_full_path(bool use_rootdir, const char *basedir, const char *plist)
{
	const char *env;
	char *buf;
	size_t len = 0;

	assert(buf != NULL);
	assert(plist != NULL);

	if (basedir)
		env = basedir;
	else
		env = XBPS_META_PATH;

	if (rootdir && use_rootdir) {
		len = strlen(rootdir) + strlen(env) + strlen(plist) + 2;
		buf = malloc(len + 1);
		if (buf == NULL) {
			errno = ENOMEM;
			return NULL;
		}

		if (snprintf(buf, len + 1, "%s/%s/%s",
		    rootdir, env, plist) < 0) {
			errno = ENOSPC;
			return NULL;
		}
	} else {
		len = strlen(env) + strlen(plist) + 1;
		buf = malloc(len + 1);
		if (buf == NULL) {
			errno = ENOMEM;
			return NULL;
		}

		if (snprintf(buf, len + 1, "%s/%s", env, plist) < 0) {
			errno = ENOSPC;
			return NULL;
		}
	}

	return buf;
}
