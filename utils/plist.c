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

#include "xbps_api.h"

struct callback_args {
	const char *string;
	int number;
};

bool
xbps_add_obj_to_dict(prop_dictionary_t dict, prop_object_t obj,
		       const char *key)
{
	assert(dict != NULL || obj != NULL || key != NULL);

	if (!prop_dictionary_set(dict, key, obj))
		return false;

	prop_object_release(obj);
	return true;
}

bool
xbps_add_obj_to_array(prop_array_t array, prop_object_t obj)
{
	assert(array != NULL || obj != NULL);

	if (!prop_array_add(array, obj)) {
		prop_object_release(array);
		return false;
	}

	prop_object_release(obj);
	return true;
}

bool
xbps_callback_array_iter_in_dict(prop_dictionary_t dict, const char *key,
				 bool (*func)(prop_object_t, void *, bool *),
				 void *arg)
{
	prop_object_iterator_t iter;
	prop_object_t obj;
	bool run, ret, cbloop_done;

	run = ret = cbloop_done = false;
	assert(func != NULL);

	iter = xbps_get_array_iter_from_dict(dict, key);
	if (iter == NULL)
		return false;

	while ((obj = prop_object_iterator_next(iter))) {
		run = (*func)(obj, arg, &cbloop_done);
		if (run && cbloop_done) {
			ret = true;
			break;
		}
	}

	prop_object_iterator_release(iter);
	return ret;
}

prop_dictionary_t
xbps_find_pkg_in_dict(prop_dictionary_t dict, const char *pkgname)
{
	prop_object_iterator_t iter;
	prop_object_t obj;
	const char *dpkgn;

	assert(pkgname != NULL);

	iter = xbps_get_array_iter_from_dict(dict, "packages");
	if (iter == NULL)
		return NULL;

	while ((obj = prop_object_iterator_next(iter))) {
		prop_dictionary_get_cstring_nocopy(obj, "pkgname", &dpkgn);
		if (strcmp(dpkgn, pkgname) == 0)
			break;
	}
	prop_object_iterator_release(iter);

	return obj;
}

bool
xbps_find_string_in_array(prop_array_t array, const char *val)
{
	prop_object_iterator_t iter;
	prop_object_t obj;

	assert(array != NULL || val != NULL);

	iter = prop_array_iterator(array);
	if (iter == NULL)
		return false;

	while ((obj = prop_object_iterator_next(iter)) != NULL) {
		if (prop_object_type(obj) != PROP_TYPE_STRING)
			continue;
		if (prop_string_equals_cstring(obj, val)) {
			prop_object_iterator_release(iter);
			return true;
		}
	}

	prop_object_iterator_release(iter);
	return false;
}

prop_object_iterator_t
xbps_get_array_iter_from_dict(prop_dictionary_t dict, const char *key)
{
	prop_array_t array;

	assert(dict != NULL || key != NULL);

	array = prop_dictionary_get(dict, key);
	if (array == NULL || prop_object_type(array) != PROP_TYPE_ARRAY)
		return NULL;

	return prop_array_iterator(array);
}

const char *
xbps_get_pkgidx_string(const char *repofile)
{
	const char *res;
	char plist[PATH_MAX], *len;

	assert(repofile != NULL);

	/* Add full path to pkg-index.plist file */
	len = strncpy(plist, repofile, sizeof(plist) - 1);
	if (sizeof(*len) >= sizeof(plist))
		return NULL;

	plist[sizeof(plist) - 1] = '\0';
	strncat(plist, "/", sizeof(plist) - strlen(plist) - 1);
	strncat(plist, XBPS_PKGINDEX, sizeof(plist) - strlen(plist) - 1);
	res = plist;

	return res;
}

bool
xbps_remove_string_from_array(prop_object_t obj, void *arg, bool *loop_done)
{
	static int idx;
	struct callback_args *cb = arg;

	assert(prop_object_type(obj) == PROP_TYPE_STRING);

	if (prop_string_equals_cstring(obj, cb->string)) {
		cb->number = idx;
		*loop_done = true;
		return true;
	}
	idx++;

	return false;
}

bool
xbps_register_repository(const char *uri)
{
	prop_dictionary_t dict;
	prop_array_t array = NULL;
	prop_object_t obj;

	assert(uri != NULL);

	/* First check if we have the repository plist file. */
	dict = prop_dictionary_internalize_from_file(XBPS_REPOLIST_PATH);
	if (dict == NULL) {
		/* Looks like not, create it. */
		dict = prop_dictionary_create();
		if (dict == NULL)
			return false;

		/* Create the array and add the repository URI on it. */
		array = prop_array_create();
		if (array == NULL) {
			prop_object_release(dict);
			return false;
		}

		if (!prop_array_set_cstring_nocopy(array, 0, uri))
			goto fail;

		/* Add the array obj into the main dictionary. */
		if (!xbps_add_obj_to_dict(dict, array, "repository-list"))
			goto fail;

		/* Write dictionary into plist file. */
		if (!prop_dictionary_externalize_to_file(dict,
		    XBPS_REPOLIST_PATH))
			goto fail;

		prop_object_release(dict);
	} else {
		/* Append into the array, the plist file exists. */
		array = prop_dictionary_get(dict, "repository-list");
		if (array == NULL)
			return false;

		assert(prop_object_type(array) == PROP_TYPE_ARRAY);

		/* It seems that this object is already there */
		if (xbps_find_string_in_array(array, uri)) {
			errno = EEXIST;
			return false;
		}

		obj = prop_string_create_cstring(uri);
		if (!xbps_add_obj_to_array(array, obj)) {
			prop_object_release(obj);
			return false;
		}

		/* Write dictionary into plist file. */
		if (!prop_dictionary_externalize_to_file(dict,
		    XBPS_REPOLIST_PATH)) {
			prop_object_release(obj);
			return false;
		}

		prop_object_release(obj);
	}

	return true;

fail:
	prop_object_release(dict);
	return false;
}

bool
xbps_unregister_repository(const char *uri)
{
	prop_dictionary_t dict;
	prop_array_t array;
	struct callback_args *cb;
	bool done = false;

	assert(uri != NULL);

	dict = prop_dictionary_internalize_from_file(XBPS_REPOLIST_PATH);
	if (dict == NULL)
		return false;

	array = prop_dictionary_get(dict, "repository-list");
	if (array == NULL)
		return false;

	assert(prop_object_type(array) == PROP_TYPE_ARRAY);

	cb = malloc(sizeof(*cb));
	if (cb == NULL) {
		errno = ENOMEM;
		return false;
	}

	cb->string = uri;
	cb->number = -1;

	done = xbps_callback_array_iter_in_dict(dict, "repository-list",
		    xbps_remove_string_from_array, cb);
	if (done && cb->number >= 0) {
		/* Found, remove it. */
		prop_array_remove(array, cb->number);

		/* Update plist file. */
		if (prop_dictionary_externalize_to_file(dict,
		    XBPS_REPOLIST_PATH)) {
			free(cb);
			return true;
		}
	} else {
		/* Not found. */
		errno = ENODEV;
	}

	free(cb);
	return false;
}

void
xbps_show_pkg_info(prop_dictionary_t dict)
{
	prop_object_t obj;
	const char *sep = NULL;

	assert(dict != NULL);
	if (prop_dictionary_count(dict) == 0)
		return;

	obj = prop_dictionary_get(dict, "pkgname");
	if (obj && prop_object_type(obj) == PROP_TYPE_STRING)
		printf("Package: %s\n", prop_string_cstring_nocopy(obj));

	obj = prop_dictionary_get(dict, "installed_size");
	if (obj && prop_object_type(obj) == PROP_TYPE_NUMBER)
		printf("Installed size: %zu bytes\n",
		    prop_number_unsigned_integer_value(obj));

	obj = prop_dictionary_get(dict, "maintainer");
	if (obj && prop_object_type(obj) == PROP_TYPE_STRING)
		printf("Maintainer: %s\n", prop_string_cstring_nocopy(obj));

	obj = prop_dictionary_get(dict, "architecture");
	if (obj && prop_object_type(obj) == PROP_TYPE_STRING)
		printf("Architecture: %s\n", prop_string_cstring_nocopy(obj));

	obj = prop_dictionary_get(dict, "version");
	if (obj && prop_object_type(obj) == PROP_TYPE_STRING)
		printf("Version: %s\n", prop_string_cstring_nocopy(obj));

	obj = prop_dictionary_get(dict, "filename");
	if (obj && prop_object_type(obj) == PROP_TYPE_STRING)
		printf("Filename: %s\n", prop_string_cstring_nocopy(obj));

	obj = prop_dictionary_get(dict, "filename-sha256");
	if (obj && prop_object_type(obj) == PROP_TYPE_STRING)
		printf("SHA256: %s\n", prop_string_cstring_nocopy(obj));

	obj = prop_dictionary_get(dict, "run_depends");
	if (obj && prop_object_type(obj) == PROP_TYPE_ARRAY) {
		printf("Dependencies:\n\t");
		sep = " ";
		xbps_callback_array_iter_in_dict(dict, "run_depends",
		    xbps_list_strings_in_array2, (void *)sep);
		printf("\n\n");
	}

	obj = prop_dictionary_get(dict, "conf_files");
	if (obj && prop_object_type(obj) == PROP_TYPE_ARRAY) {
		printf("Configuration files:\n\t");
		xbps_callback_array_iter_in_dict(dict, "conf_files",
		    xbps_list_strings_in_array2, NULL);
		printf("\n");
	}

	obj = prop_dictionary_get(dict, "keep_dirs");
	if (obj && prop_object_type(obj) == PROP_TYPE_ARRAY) {
		printf("Permanent directories:\n\t");
		xbps_callback_array_iter_in_dict(dict, "keep_dirs",
		    xbps_list_strings_in_array2, NULL);
		printf("\n");
	}

	obj = prop_dictionary_get(dict, "short_desc");
	if (obj && prop_object_type(obj) == PROP_TYPE_STRING)
		printf("Description: %s", prop_string_cstring_nocopy(obj));

	obj = prop_dictionary_get(dict, "long_desc");
	if (obj && prop_object_type(obj) == PROP_TYPE_STRING)
		printf(" %s\n", prop_string_cstring_nocopy(obj));
}

bool
xbps_show_pkg_namedesc(prop_object_t obj, void *arg, bool *loop_done)
{
	const char *pkgname, *desc, *ver, *string = arg;

	assert(prop_object_type(obj) == PROP_TYPE_DICTIONARY);
	assert(string != NULL);

	prop_dictionary_get_cstring_nocopy(obj, "pkgname", &pkgname);
	prop_dictionary_get_cstring_nocopy(obj, "short_desc", &desc);
	prop_dictionary_get_cstring_nocopy(obj, "version", &ver);
	assert(ver != NULL);

	if ((strstr(pkgname, string) || strstr(desc, string)))
		printf("  %s-%s - %s\n", pkgname, ver, desc);

	return true;
}

bool
xbps_search_string_in_pkgs(prop_object_t obj, void *arg, bool *loop_done)
{
	prop_dictionary_t dict;
	const char *repofile, *plist, *pkgstring = arg;

	assert(prop_object_type(obj) == PROP_TYPE_STRING);
	assert(pkgstring != NULL);

	/* Get the location of pkgindex file. */
	repofile = prop_string_cstring_nocopy(obj);
	assert(repofile != NULL);

	/* Get string for pkg-index.plist with full path. */
	plist = xbps_get_pkgidx_string(repofile);
	if (plist == NULL)
		return false;

	dict = prop_dictionary_internalize_from_file(plist);
	if (dict == NULL || prop_dictionary_count(dict) == 0)
		return false;

	printf("From %s repository ...\n", repofile);
	xbps_callback_array_iter_in_dict(dict, "packages",
	    xbps_show_pkg_namedesc, (void *)pkgstring);

	return true;
}

bool
xbps_show_pkg_info_from_repolist(prop_object_t obj, void *arg, bool *loop_done)
{
	prop_dictionary_t dict, pkgdict;
	prop_string_t oloc;
	const char *repofile, *repoloc, *plist;

	assert(prop_object_type(obj) == PROP_TYPE_STRING);

	/* Get the location */
	repofile = prop_string_cstring_nocopy(obj);

	/* Get string for pkg-index.plist with full path. */
	plist = xbps_get_pkgidx_string(repofile);
	if (plist == NULL)
		return false;

	dict = prop_dictionary_internalize_from_file(plist);
	if (dict == NULL || prop_dictionary_count(dict) == 0)
		return false;
	pkgdict = xbps_find_pkg_in_dict(dict, arg);
	if (pkgdict == NULL)
		return false;

	oloc = prop_dictionary_get(dict, "location-remote");
	if (oloc == NULL)
		oloc = prop_dictionary_get(dict, "location-local");

	if (oloc && prop_object_type(oloc) == PROP_TYPE_STRING)
		repoloc = prop_string_cstring_nocopy(oloc);
	else
		return false;

	printf("Repository: %s\n", repoloc);
	xbps_show_pkg_info(pkgdict);
	*loop_done = true;

	return true;
}

bool
xbps_list_pkgs_in_dict(prop_object_t obj, void *arg, bool *loop_done)
{
	const char *pkgname, *version, *short_desc;

	assert(prop_object_type(obj) == PROP_TYPE_DICTIONARY);

	prop_dictionary_get_cstring_nocopy(obj, "pkgname", &pkgname);
	prop_dictionary_get_cstring_nocopy(obj, "version", &version);
	prop_dictionary_get_cstring_nocopy(obj, "short_desc", &short_desc);
	if (pkgname && version && short_desc) {
		printf("%s (%s)\t%s\n", pkgname, version, short_desc);
		return true;
	}

	return false;
}

bool
xbps_list_strings_in_array2(prop_object_t obj, void *arg, bool *loop_done)
{
	static uint16_t count;
	const char *sep;

	assert(prop_object_type(obj) == PROP_TYPE_STRING);

	if (arg == NULL) {
		sep = "\n\t";
		count = 0;
	} else
		sep = (const char *)arg;

	if (count == 4) {
		printf("\n\t");
		count = 0;
	}

	printf("%s%s", prop_string_cstring_nocopy(obj), sep);
	count++;

	return true;
}

bool
xbps_list_strings_in_array(prop_object_t obj, void *arg, bool *loop_done)
{
	assert(prop_object_type(obj) == PROP_TYPE_STRING);

	printf("%s\n", prop_string_cstring_nocopy(obj));

	return true;
}
