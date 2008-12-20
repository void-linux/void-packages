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

static bool xbps_list_strings_in_array2(prop_object_t, void *);
static bool repo_haspkg;

bool
xbps_add_obj_to_dict(prop_dictionary_t dict, prop_object_t obj,
		       const char *key)
{
	if (dict == NULL || obj == NULL || key == NULL)
		return false;

	if (!prop_dictionary_set(dict, key, obj))
		return false;

	prop_object_release(obj);
	return true;
}

bool
xbps_add_obj_to_array(prop_array_t array, prop_object_t obj)
{
	if (array == NULL || obj == NULL)
		return false;

	if (!prop_array_add(array, obj)) {
		prop_object_release(array);
		return false;
	}

	prop_object_release(obj);
	return true;
}

bool
xbps_callback_array_iter_in_dict(prop_dictionary_t dict, const char *key,
				 bool (*func)(prop_object_t, void *),
				 void *arg)
{
	prop_object_iterator_t iter;
	prop_object_t obj;
	bool run = false, ret = false;

	if (func == NULL)
		return false;

	repo_haspkg = false;

	iter = xbps_get_array_iter_from_dict(dict, key);
	if (iter == NULL)
		return false;

	while ((obj = prop_object_iterator_next(iter))) {
		run = (*func)(obj, arg);
		if (run && repo_haspkg) {
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

	if (pkgname == NULL)
		return NULL;

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

	if (array == NULL || val == NULL)
		return false;

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

	if (dict == NULL || key == NULL)
		return NULL;

	array = prop_dictionary_get(dict, key);
	if (array == NULL || prop_object_type(array) != PROP_TYPE_ARRAY)
		return NULL;

	return prop_array_iterator(array);
}

bool
xbps_register_repository(const char *uri)
{
	prop_dictionary_t dict;
	prop_array_t array = NULL;
	prop_object_t obj;

	if (uri == NULL)
		return false;

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
		if (array == NULL || prop_object_type(array) != PROP_TYPE_ARRAY)
			return false;

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

void
xbps_show_pkg_info(prop_dictionary_t dict)
{
	prop_object_iterator_t iter;
	prop_object_t obj, obj2;
	const char *sep = NULL;
	bool rundeps = false;

	if (dict == NULL || prop_dictionary_count(dict) == 0)
		return;

	iter = prop_dictionary_iterator(dict);
	if (iter == NULL)
		return;

	while ((obj = prop_object_iterator_next(iter))) {
		/* Print the key */
		printf("%s: ", prop_dictionary_keysym_cstring_nocopy(obj));
		/* Get the obj for current keysym */
		obj2 = prop_dictionary_get_keysym(dict, obj);

		if (prop_object_type(obj2) == PROP_TYPE_STRING) {
			printf("%s\n", prop_string_cstring_nocopy(obj2));

		} else if (prop_object_type(obj2) == PROP_TYPE_NUMBER) {
			printf("%zu\n",
			    prop_number_unsigned_integer_value(obj2));

		} else if (prop_object_type(obj2) == PROP_TYPE_ARRAY) {
			/*
			 * Apply some indentation for array objs other than
			 * "run_depends".
			 */
			if (strcmp(prop_dictionary_keysym_cstring_nocopy(obj),
			    "run_depends") == 0) {
				rundeps = true;
				sep = " ";
			}
			printf("\n\t");
			xbps_callback_array_iter_in_dict(dict,
			    prop_dictionary_keysym_cstring_nocopy(obj),
			    xbps_list_strings_in_array2, (void *)sep);
			printf("\n");
			if (rundeps)
				printf("\n");
		}
	}

	prop_object_iterator_release(iter);
}

bool
xbps_show_pkg_info_from_repolist(prop_object_t obj, void *arg)
{
	prop_dictionary_t dict, pkgdict;
	prop_string_t oloc;
	const char *repofile, *repoloc;

	if (prop_object_type(obj) != PROP_TYPE_STRING)
		return false;

	repofile = prop_string_cstring_nocopy(obj);
	dict = prop_dictionary_internalize_from_file(repofile);
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
	repo_haspkg = true;

	return true;
}

bool
xbps_list_pkgs_in_dict(prop_object_t obj, void *arg)
{
	const char *pkgname, *version, *short_desc;

	if (prop_object_type(obj) != PROP_TYPE_DICTIONARY)
		return false;

	prop_dictionary_get_cstring_nocopy(obj, "pkgname", &pkgname);
	prop_dictionary_get_cstring_nocopy(obj, "version", &version);
	prop_dictionary_get_cstring_nocopy(obj, "short_desc", &short_desc);
	if (pkgname && version && short_desc) {
		printf("%s (%s)\t%s\n", pkgname, version, short_desc);
		return true;
	}

	return false;
}

static bool
xbps_list_strings_in_array2(prop_object_t obj, void *arg)
{
	static uint16_t count;
	const char *sep;

	if (prop_object_type(obj) != PROP_TYPE_STRING)
		return false;

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
xbps_list_strings_in_array(prop_object_t obj, void *arg)
{
	if (prop_object_type(obj) != PROP_TYPE_STRING)
		return false;

	printf("%s\n", prop_string_cstring_nocopy(obj));
	return true;
}
