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

#include <xbps_api.h>

struct callback_args {
	const char *string;
	int64_t number;
};

bool
xbps_add_obj_to_dict(prop_dictionary_t dict, prop_object_t obj,
		       const char *key)
{
	assert(dict != NULL);
	assert(obj != NULL);
	assert(key != NULL);

	if (!prop_dictionary_set(dict, key, obj)) {
		prop_object_release(dict);
		return false;
	}

	prop_object_release(obj);
	return true;
}

bool
xbps_add_obj_to_array(prop_array_t array, prop_object_t obj)
{
	assert(array != NULL);
	assert(obj != NULL);

	if (!prop_array_add(array, obj)) {
		prop_object_release(array);
		return false;
	}

	prop_object_release(obj);
	return true;
}

int
xbps_callback_array_iter_in_dict(prop_dictionary_t dict, const char *key,
				 int (*func)(prop_object_t, void *, bool *),
				 void *arg)
{
	prop_object_iterator_t iter;
	prop_object_t obj;
	int rv = 0;
	bool run, cbloop_done;

	assert(dict != NULL);
	assert(key != NULL);
	assert(func != NULL);

	run = cbloop_done = false;
	assert(func != NULL);

	iter = xbps_get_array_iter_from_dict(dict, key);
	if (iter == NULL)
		return EINVAL;

	while ((obj = prop_object_iterator_next(iter))) {
		rv = (*func)(obj, arg, &cbloop_done);
		if (rv == 0 && cbloop_done)
			break;
	}

	prop_object_iterator_release(iter);
	return rv;
}

prop_dictionary_t
xbps_find_pkg_from_plist(const char *plist, const char *pkgname)
{
	prop_dictionary_t dict;
	prop_dictionary_t obj, res;

	assert(plist != NULL);
	assert(pkgname != NULL);

	dict = prop_dictionary_internalize_from_file(plist);
	if (dict == NULL) {
		errno = ENOENT;
		return NULL;
	}

	obj = xbps_find_pkg_in_dict(dict, pkgname);
	if (obj == NULL) {
		prop_object_release(dict);
		errno = ENOENT;
		return NULL;
	}

	res = prop_dictionary_copy(obj);
	prop_object_release(dict);

	return res;
}

prop_dictionary_t
xbps_find_pkg_in_dict(prop_dictionary_t dict, const char *pkgname)
{
	prop_object_iterator_t iter;
	prop_object_t obj;
	const char *dpkgn;

	assert(dict != NULL);
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

	assert(array != NULL);
	assert(val != NULL);

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

	assert(dict != NULL);
	assert(key != NULL);

	array = prop_dictionary_get(dict, key);
	if (array == NULL || prop_object_type(array) != PROP_TYPE_ARRAY)
		return NULL;

	return prop_array_iterator(array);
}

bool
xbps_remove_pkg_dict_from_file(const char *pkg, const char *plist)
{
	prop_dictionary_t pdict;
	prop_array_t array;
	prop_object_t obj;
	prop_object_iterator_t iter;
	const char *curpkg;
	size_t i = 0;

	assert(pkg != NULL);
	assert(plist != NULL);

	pdict = prop_dictionary_internalize_from_file(plist);
	if (pdict == NULL)
		return false;

	array = prop_dictionary_get(pdict, "packages");
	if (array == NULL || prop_object_type(array) != PROP_TYPE_ARRAY)
		return false;

	iter = prop_array_iterator(array);
	if (iter == NULL)
		return false;

	/* Iterate over the array of dictionaries to find its index. */
	while ((obj = prop_object_iterator_next(iter))) {
		prop_dictionary_get_cstring_nocopy(obj, "pkgname", &curpkg);
		if ((curpkg && (strcmp(curpkg, pkg) == 0))) {
			/* Found, remove it and write plist file. */
			prop_array_remove(array, i);
			prop_object_iterator_release(iter);
			goto wr_plist;
		}
		i++;
	}

	prop_object_iterator_release(iter);
	prop_object_release(pdict);
	errno = ENODEV;
	return false;

wr_plist:
	if (!prop_dictionary_externalize_to_file(pdict, plist)) {
		prop_object_release(pdict);
		return false;
	}

	prop_object_release(pdict);

	return true;
}

int
xbps_remove_string_from_array(prop_object_t obj, void *arg, bool *loop_done)
{
	static int64_t idx;
	struct callback_args *cb = arg;

	assert(prop_object_type(obj) == PROP_TYPE_STRING);

	if (prop_string_equals_cstring(obj, cb->string)) {
		cb->number = idx;
		*loop_done = true;
		return 0;
	}
	idx++;

	return EINVAL;
}

bool
xbps_register_repository(const char *uri)
{
	prop_dictionary_t dict;
	prop_array_t array = NULL;
	prop_object_t obj;
	char plist[PATH_MAX];

	assert(uri != NULL);

	if (!xbps_append_full_path(plist, NULL, XBPS_REPOLIST)) {
		errno = EINVAL;
		return false;
	}

	/* First check if we have the repository plist file. */
	dict = prop_dictionary_internalize_from_file(plist);
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
		if (!prop_dictionary_externalize_to_file(dict, plist))
			goto fail;

		prop_object_release(dict);
	} else {
		/* Append into the array, the plist file exists. */
		array = prop_dictionary_get(dict, "repository-list");
		if (array == NULL)
			goto fail;

		assert(prop_object_type(array) == PROP_TYPE_ARRAY);

		/* It seems that this object is already there */
		if (xbps_find_string_in_array(array, uri)) {
			errno = EEXIST;
			goto fail;
		}

		obj = prop_string_create_cstring(uri);
		if (!xbps_add_obj_to_array(array, obj)) {
			prop_object_release(obj);
			return false;
		}

		/* Write dictionary into plist file. */
		if (!prop_dictionary_externalize_to_file(dict, plist)) {
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
	char plist[PATH_MAX];
	bool done = false;

	assert(uri != NULL);

	if (!xbps_append_full_path(plist, NULL, XBPS_REPOLIST)) {
		errno = EINVAL;
		return false;
	}

	dict = prop_dictionary_internalize_from_file(plist);
	if (dict == NULL)
		return false;

	array = prop_dictionary_get(dict, "repository-list");
	if (array == NULL) {
		prop_object_release(dict);
		return false;
	}

	assert(prop_object_type(array) == PROP_TYPE_ARRAY);

	cb = malloc(sizeof(*cb));
	if (cb == NULL) {
		prop_object_release(dict);
		errno = ENOMEM;
		return false;
	}

	cb->string = uri;
	cb->number = -1;

	done = xbps_callback_array_iter_in_dict(dict, "repository-list",
		    xbps_remove_string_from_array, cb);
	if (done == 0 && cb->number >= 0) {
		/* Found, remove it. */
		prop_array_remove(array, cb->number);

		/* Update plist file. */
		if (prop_dictionary_externalize_to_file(dict, plist)) {
			free(cb);
			prop_object_release(dict);
			return true;
		}
	} else {
		/* Not found. */
		errno = ENODEV;
	}

	prop_object_release(dict);
	free(cb);
	return false;
}

void
xbps_show_pkg_info(prop_dictionary_t dict)
{
	prop_object_t obj;
	const char *sep = NULL;
	char size[64];
	int rv = 0;

	assert(dict != NULL);
	assert(prop_dictionary_count(dict) != 0);

	obj = prop_dictionary_get(dict, "pkgname");
	if (obj && prop_object_type(obj) == PROP_TYPE_STRING)
		printf("Package: %s\n", prop_string_cstring_nocopy(obj));

	obj = prop_dictionary_get(dict, "installed_size");
	if (obj && prop_object_type(obj) == PROP_TYPE_NUMBER) {
		printf("Installed size: ");
		rv = xbps_humanize_number(size, 5,
		    (int64_t)prop_number_unsigned_integer_value(obj),
		    "", HN_AUTOSCALE, HN_NOSPACE);
		if (rv == -1)
			printf("%ju\n",
			    prop_number_unsigned_integer_value(obj));
		else
			printf("%s\n", size);
	}

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

int
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

	return 0;
}

int
xbps_search_string_in_pkgs(prop_object_t obj, void *arg, bool *loop_done)
{
	prop_dictionary_t dict;
	const char *repofile;
	char plist[PATH_MAX];

	assert(prop_object_type(obj) == PROP_TYPE_STRING);

	/* Get the location of pkgindex file. */
	repofile = prop_string_cstring_nocopy(obj);
	assert(repofile != NULL);

	if (!xbps_append_full_path(plist, repofile, XBPS_PKGINDEX))
		return EINVAL;

	dict = prop_dictionary_internalize_from_file(plist);
	if (dict == NULL)
		return EINVAL;

	printf("From %s repository ...\n", repofile);
	xbps_callback_array_iter_in_dict(dict, "packages",
	    xbps_show_pkg_namedesc, arg);
	prop_object_release(dict);

	return 0;
}

int
xbps_show_pkg_info_from_repolist(prop_object_t obj, void *arg, bool *loop_done)
{
	prop_dictionary_t dict, pkgdict;
	prop_string_t oloc;
	const char *repofile, *repoloc;
	char plist[PATH_MAX];

	assert(prop_object_type(obj) == PROP_TYPE_STRING);

	/* Get the location */
	repofile = prop_string_cstring_nocopy(obj);

	/* Get string for pkg-index.plist with full path. */
	if (!xbps_append_full_path(plist, repofile, XBPS_PKGINDEX))
		return EINVAL;

	dict = prop_dictionary_internalize_from_file(plist);
	if (dict == NULL || prop_dictionary_count(dict) == 0)
		return EINVAL;

	pkgdict = xbps_find_pkg_in_dict(dict, arg);
	if (pkgdict == NULL) {
		prop_object_release(dict);
		return XBPS_PKG_ENOTINREPO;
	}

	oloc = prop_dictionary_get(dict, "location-remote");
	if (oloc == NULL)
		oloc = prop_dictionary_get(dict, "location-local");

	if (oloc && prop_object_type(oloc) == PROP_TYPE_STRING)
		repoloc = prop_string_cstring_nocopy(oloc);
	else {
		prop_object_release(dict);
		return EINVAL;
	}

	printf("Repository: %s\n", repoloc);
	xbps_show_pkg_info(pkgdict);
	*loop_done = true;
	prop_object_release(dict);

	return 0;
}

int
xbps_list_pkgs_in_dict(prop_object_t obj, void *arg, bool *loop_done)
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

	return 0;
}

int
xbps_list_strings_in_array(prop_object_t obj, void *arg, bool *loop_done)
{
	assert(prop_object_type(obj) == PROP_TYPE_STRING);

	printf("%s\n", prop_string_cstring_nocopy(obj));

	return 0;
}
